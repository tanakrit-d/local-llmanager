//
//  CLIService.swift
//  local-llmanager
//
//  Created by Dominic McRae on 22/04/2025.
//

import Foundation

enum CLIServiceError: Error {
    case shellCommandFailed(
        command: String,
        status: Int32,
        output: String,
        errorOutput: String
    )
    case pidNotFound(serviceName: String)
    case serviceNotRunning(serviceName: String)
    case failedToStopService(serviceName: String, pid: Int32, reason: String)
    case unknownError(Error)

    var localizedDescription: String {
        switch self {
        case .shellCommandFailed(
            let command,
            let status,
            let output,
            let errorOutput
        ):
            return
                "Shell command failed: \(command)\nStatus: \(status)\nOutput: \(output)\nError Output: \(errorOutput)"
        case .pidNotFound(let serviceName):
            return "PID not found for service: \(serviceName)"
        case .serviceNotRunning(let serviceName):
            return "\(serviceName) is not running."
        case .failedToStopService(let serviceName, let pid, let reason):
            return "Failed to stop \(serviceName) with PID \(pid): \(reason)"
        case .unknownError(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}

protocol CLIServiceManaging {
    func startService() async throws -> (
        servicePID: Int32?, isServiceRunning: Bool
    )
    func stopService() async throws -> (
        servicePID: Int32?, isServiceRunning: Bool
    )
    func checkServiceStatus() async throws -> (
        servicePID: Int32?, isServiceRunning: Bool
    )
}

class CLIService: CLIServiceManaging {

    let standardPath =
        "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    let serviceName = "ollama"

    // MARK: - Run Shell Command
    private func runShellCommand(_ command: String) async throws -> (
        stdout: String, stderr: String
    ) {
        let task = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.environment = ["PATH": standardPath]

        do {
            try task.run()

            task.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading
                .readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(decoding: outputData, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let errorOutput = String(decoding: errorData, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if task.terminationStatus != 0 {
                throw CLIServiceError.shellCommandFailed(
                    command: command,
                    status: task.terminationStatus,
                    output: output,
                    errorOutput: errorOutput
                )
            }

            return (stdout: output, stderr: errorOutput)

        } catch {
            if let shellError = error as? CLIServiceError {
                throw shellError
            } else {
                throw CLIServiceError.unknownError(error)
            }
        }
    }

    // MARK: - Check Ollama Service PID
    private func checkServicePID() async throws -> Int32? {
        let pgrepCommand = "pgrep -x \(serviceName)" // serviceName is "ollama"
        do {
            let result = try await runShellCommand(pgrepCommand)

            let pids = result.stdout
                .split(separator: "\n")
                .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

            if let firstPID = pids.first {
                return firstPID
            } else {
                return nil
            }
        } catch let CLIServiceError.shellCommandFailed(_, status, _, _)
            where status == 1
        {
            return nil
        } catch {
            throw error
        }
    }

    // MARK: - Start Ollama Service
    func startService() async throws -> (
        servicePID: Int32?, isServiceRunning: Bool
    ) {
        print("Attempting to start \(serviceName)...")
        let startCommand = "\(serviceName) serve &"
        let startResult = try await runShellCommand(startCommand)

        try await Task.sleep(nanoseconds: 500_000_000)

        let pid = try await checkServicePID()

        if let servicePID = pid {
            print("Started \(serviceName) with PID: \(servicePID)")
            return (servicePID, true)
        } else {
            print("Attempted to start \(serviceName), but PID was not found.")
            throw CLIServiceError.pidNotFound(serviceName: serviceName)
        }
    }

    // MARK: - Stop Ollama Service
    func stopService() async throws -> (
        servicePID: Int32?, isServiceRunning: Bool
    ) {
        print("Attempting to stop \(serviceName)...")
        guard let servicePID = try await checkServicePID() else {
            print("\(serviceName) is not running. Nothing to stop.")
            return (nil, false)
        }

        print(
            "Found \(serviceName) running with PID \(servicePID). Sending termination signal..."
        )

        let killCommand = "kill \(servicePID)"
        do {
            let killResult = try await runShellCommand(killCommand)
            print(
                "Sent termination signal to \(serviceName) (PID \(servicePID))."
            )

            try await Task.sleep(nanoseconds: 200_000_000)  // Sleep for 0.2 seconds
            let isStillRunning = try await checkServicePID() != nil

            if isStillRunning {
                print(
                    "\(serviceName) (PID \(servicePID)) might still be running after kill."
                )
                throw CLIServiceError.failedToStopService(
                    serviceName: serviceName,
                    pid: servicePID,
                    reason: "Process did not terminate after receiving signal."
                )
            } else {
                print(
                    "\(serviceName) (PID \(servicePID)) successfully stopped."
                )
                return (nil, false)
            }

        } catch let CLIServiceError.shellCommandFailed(cmd, status, out, errOut)
            where cmd == killCommand
        {
            throw CLIServiceError.failedToStopService(
                serviceName: serviceName,
                pid: servicePID,
                reason:
                    "Kill command failed (status \(status)). Output: \(out), Error: \(errOut)"
            )
        } catch {
            throw error
        }
    }

    // MARK: - Check Ollama Service Status
    func checkServiceStatus() async throws -> (
        servicePID: Int32?, isServiceRunning: Bool
    ) {
        print("Checking status of \(serviceName)...")
        let pid = try await checkServicePID()

        if let servicePID = pid {
            print("\(serviceName) is running with PID: \(servicePID)")
            return (servicePID, true)
        } else {
            print("\(serviceName) is not running.")
            return (nil, false)
        }
    }
}
