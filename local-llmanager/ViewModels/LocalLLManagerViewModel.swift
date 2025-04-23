//
//  LocalLLManagerViewModel.swift
//  local-llmanager
//
//  Created by Dominic McRae on 22/04/2025.
//

import Combine
import Foundation

@MainActor
class LocalLLManagerViewModel: ObservableObject {
    private let cliService: CLIServiceManaging
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimerTask: Task<Void, Never>?

    @Published var isServiceRunning: Bool = false
    @Published var servicePID: Int32? = nil
    @Published var serviceVersion: String = "N/A"
    @Published var lastRefresh: Date? = nil
    @Published var isLoading: Bool = false
    @Published var isLoadingLocalModels = false
    @Published var isLoadingRunningModels = false
    @Published var isLoadingModels: Bool = false
    @Published var localModels: [LocalModel] = []
    @Published var runningModels: [RunningModel] = []
    @Published var displayModels: [DisplayModelItem] = []
    @Published var errorMessage: String?
    @Published var showingErrorAlert: Bool = false

    init(
        cliService: CLIServiceManaging = CLIService(),
        apiService: APIService = APIService()
    ) {
        self.cliService = cliService
        self.apiService = apiService

        Publishers.CombineLatest($localModels, $runningModels)
            .map { local, running in
                self.mapToDisplayModels(
                    localModels: local,
                    runningModels: running
                )
            }
            .receive(on: DispatchQueue.main)  // Ensure UI updates on main thread
            .assign(to: \.displayModels, on: self)
            .store(in: &cancellables)

        // Monitor errorMessage to show alert
        $errorMessage
            .map { $0 != nil }
            .assign(to: \.showingErrorAlert, on: self)
            .store(in: &cancellables)

        Task {
            await checkInitialServiceStatus()
        }
    }

    private func checkInitialServiceStatus() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let statusInfo = try await cliService.checkServiceStatus()
            self.isServiceRunning = statusInfo.isServiceRunning
            self.servicePID = statusInfo.servicePID

            if isServiceRunning {
                print(
                    "The service is running with PID \(servicePID ?? -1). Performing setup."
                )
                await performSetup()
                startScheduledRefresh()
            } else {
                print("The service is not currently running.")
                self.serviceVersion = "N/A"
                self.localModels = []
                self.runningModels = []
                stopScheduledRefresh()
            }

        } catch {
            handleError(error, context: "checking initial service status")
            self.isServiceRunning = false
            self.servicePID = nil
            self.serviceVersion = "N/A"
            self.localModels = []
            self.runningModels = []
        }
    }

    private func performSetup() async {
        guard isServiceRunning else { return }
        isLoadingModels = true
        defer { isLoadingModels = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getVersion() }
            group.addTask { await self.getLocalModels() }
            group.addTask { await self.getRunningModels() }
        }
        print("Initial data fetch complete.")
    }

    func startService() async {
        do {
            let result = try await cliService.startService()
            servicePID = result.servicePID
            isServiceRunning = result.isServiceRunning
            startScheduledRefresh()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to start Ollama: \(error)")
        }
    }

    func stopService() async {
        do {
            let result = try await cliService.stopService()
            servicePID = result.servicePID
            isServiceRunning = result.isServiceRunning
            stopScheduledRefresh()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to stop Ollama: \(error)")
        }
    }

    func startModel(modelName: String, keepAlive: String?) async throws -> Bool
    {
        let requestBody = GenerateRequest(
            model: modelName,
            stream: false,
            keepAlive: keepAlive
        )

        let response: GenerateRequestResponse = try await apiService.generate(
            requestBody: requestBody
        )

        print(
            "Model load request sent for '\(modelName)'. Response done status: \(response.done)"
        )

        return response.done
    }

    func stopModel(modelName: String) async throws -> Bool {
        let requestBody = GenerateRequest(
            model: modelName,
            stream: false,
            keepAlive: "0"
        )

        let response: GenerateRequestResponse = try await apiService.generate(
            requestBody: requestBody
        )

        print(
            "Model stop request sent for '\(modelName)'. Response done status: \(response.done)"
        )

        return response.done
    }

    func getLocalModels() async {
        print("It's time for getLocalModels!")
        guard isServiceRunning else { return }
        isLoadingLocalModels = true
        do {
            let response = try await apiService.listLocalModels()
            self.localModels = response.models.sorted { $0.name < $1.name }
        } catch {
            isLoadingLocalModels = false
            handleError(error, context: "fetching local models")
            self.localModels = []
        }
    }

    func getRunningModels() async {
        print("It's time for getRunningModels!")
        guard isServiceRunning else { return }
        isLoadingRunningModels = true
        do {
            let response = try await apiService.listRunningModels()
            self.runningModels = response.models.sorted { $0.name < $1.name }
        } catch {
            isLoadingRunningModels = false
            handleError(error, context: "fetching running models")
            self.runningModels = []
        }
    }

    func removeModel(modelName: String) async {
        let requestBody = RemoveModelRequest(model: modelName)
        do {
            try await apiService.removeModel(requestBody: requestBody)
            await getLocalModels()
            await getRunningModels()
            print("Model '\(modelName)' successfully removed.")

        } catch {
            errorMessage = error.localizedDescription
            print("Failed to remove model '\(modelName)': \(error)")

            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
                print("API Error details: \(apiError.localizedDescription)")
            }
        }
    }

    func getVersion() async {
        print("It's time for getVersion!")
        do {
            let versionResponse = try await apiService.version()
            serviceVersion = versionResponse.version
        } catch {
            print(
                "Error fetching Ollama version: \(error.localizedDescription)"
            )
            if let apiError = error as? APIError {
                switch apiError {
                case .badServerResponse(let statusCode, let description):
                    errorMessage = apiError.localizedDescription
                    print(
                        "API Error Details - Status Code: \(statusCode), Description: \(description)"
                    )
                case .jsonDecodingError(let decodeError):
                    errorMessage = decodeError.localizedDescription
                    print(
                        "API Error Details - JSON Decoding Failed: \(decodeError)"
                    )
                default: break
                }
            }
        }
    }

    private func mapToDisplayModels(
        localModels: [LocalModel],
        runningModels: [RunningModel]
    ) -> [DisplayModelItem] {
        let runningModelsDict = Dictionary(
            uniqueKeysWithValues: runningModels.map { ($0.name, $0) }
        )

        return localModels.map { localModel in
            let isRunning = runningModelsDict[localModel.name] != nil
            let runningModel = runningModelsDict[localModel.name]

            return DisplayModelItem(
                id: localModel.id,  // Use the stable digest as ID
                name: localModel.name,
                identifier: String(localModel.digest.prefix(12)),  // Shortened digest
                sizePacked: formatBytes(localModel.size),
                sizeUnpacked: runningModel != nil
                    ? formatBytes(runningModel!.size) : "N/A",  // Size when running
                processor: runningModel?.details.quantizationLevel ?? "N/A",  // Or parameterSize? Choose what's more relevant
                until: runningModel != nil
                    ? formatRelativeDate(runningModel!.expiresAt)
                    : "Not Loaded",
                modified: formatRelativeDate(localModel.modifiedAt),
                isRunning: isRunning
            )
        }
    }

    func manualRefresh() async {
        print("Manual refresh triggered.")
        if isServiceRunning {
            await performSetup()
            lastRefresh = Date()
        } else {
            await checkInitialServiceStatus()
        }
    }

    func startScheduledRefresh() {
        guard isServiceRunning, refreshTimerTask == nil else {
            if !isServiceRunning {
                print("Scheduled refresh not started: Service is not running.")
            }
            if refreshTimerTask != nil {
                print("Scheduled refresh not started: Already running.")
            }
            return
        }

        print("Starting scheduled model refresh task...")

        refreshTimerTask = Task { @MainActor [weak self] in
            guard let self = self else {
                print("Scheduled refresh cancelled: ViewModel deallocated.")
                return
            }

            while !Task.isCancelled {
                print("Performing scheduled refresh...")
                await self.performScheduledTask()

                do {
                    try await Task.sleep(for: .seconds(15))
                } catch is CancellationError {
                    print("Scheduled refresh task cancelled.")
                    break
                } catch {
                    print(
                        "Unexpected error during Task.sleep in scheduled refresh: \(error)"
                    )
                    self.handleError(
                        error,
                        context: "in scheduled refresh timer sleep"
                    )
                    break
                }
            }
            print("Scheduled refresh task finished.")
        }
    }

    func stopScheduledRefresh() {
        if refreshTimerTask != nil {
            print("Stopping scheduled model refresh task...")
            refreshTimerTask?.cancel()
            refreshTimerTask = nil
        } else {
            print("Scheduled refresh task already stopped.")
        }
    }

    private func performScheduledTask() async {
        guard isServiceRunning else {
            print("Skipping scheduled task: Service not running.")
            stopScheduledRefresh()
            return
        }
        isLoadingModels = true
        defer { isLoadingModels = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getLocalModels() }
            group.addTask { await self.getRunningModels() }
        }
        lastRefresh = Date()
        print("Scheduled refresh task execution complete.")
    }

    private func handleError(_ error: Error, context: String) {
        print("Error encountered (\(context)): \(error)")
        if let apiError = error as? APIError {
            print("API Error Details: \(apiError.localizedDescription)")
            errorMessage = "API Error: \(apiError.localizedDescription)"
        } else if let cliError = error as? CLIServiceError {
            print("CLI Error Details: \(cliError.localizedDescription)")
            errorMessage = "CLI Error: \(cliError.localizedDescription)"
        } else {
            print("Unknown Error Details: \(error.localizedDescription)")
            errorMessage =
                "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    deinit {
        print("ViewModel deinitializing, stopping scheduled refresh task.")
        cancellables.forEach { $0.cancel() }
        refreshTimerTask = nil
        // stopScheduledRefresh()
    }

}

extension LocalModel: Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(digest)
    }
    public static func == (lhs: LocalModel, rhs: LocalModel) -> Bool {
        lhs.digest == rhs.digest
    }
}

extension RunningModel: Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(digest)
    }
    public static func == (lhs: RunningModel, rhs: RunningModel) -> Bool {
        lhs.digest == rhs.digest
    }
}

extension DisplayModelItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public static func == (lhs: DisplayModelItem, rhs: DisplayModelItem) -> Bool
    {
        lhs.id == rhs.id
    }
}
