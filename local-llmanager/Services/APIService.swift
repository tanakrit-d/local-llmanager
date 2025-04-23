//
//  APIService.swift
//  local-llmanager
//
//  Created by Dominic McRae on 22/04/2025.
//

import Foundation

class APIService {

    let baseURL: URL

    init(baseURL: URL = URL(string: "http://localhost:11434")!) {
        self.baseURL = baseURL
    }

    // MARK: - Perform Request
    private func performRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data? = nil
    ) async throws -> T {

        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let body = body {
            request.httpBody = body
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiErrorDescription: String
            let decoder = JSONDecoder()

            if let ollamaError = try? decoder.decode(
                ErrorResponse.self,
                from: data
            ) {
                apiErrorDescription = ollamaError.error
            } else {
                apiErrorDescription = HTTPURLResponse.localizedString(
                    forStatusCode: httpResponse.statusCode
                )
                print(
                    "Warning: Could not decode generic error response for status code \(httpResponse.statusCode). Data received: \(String(data: data, encoding: .utf8) ?? "N/A")"
                )
            }

            throw APIError.badServerResponse(
                statusCode: httpResponse.statusCode,
                description: apiErrorDescription
            )
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("--- Received JSON Data Before Decoding ---")
            print(jsonString)
            print("-----------------------------------------")
        } else {
            print("--- Received Data Before Decoding (not UTF8 string) ---")
            print(data)
            print("-----------------------------------------------------")
        }
        
        let decoder = JSONDecoder()
        //decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let decodedResponse = try decoder.decode(T.self, from: data)
            return decodedResponse
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                 print("--- Received JSON Data ---")
                 print(jsonString)
                 print("--------------------------")
            } else {
                 print("--- Received Data (not UTF8 string) ---")
                 print(data)
                 print("---------------------------------------")
            }
            print("Attempted to decode type: \(T.self)")
            throw APIError.jsonDecodingError(error)
        }
    }

    // MARK: - Perform Request No Response
    private func performRequestNoResponseBody(
        endpoint: String,
        method: HTTPMethod,
        body: Data? = nil
    ) async throws {

        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let body = body {
            request.httpBody = body
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }

        guard (200...204).contains(httpResponse.statusCode) else {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let apiErrorDescription: String

            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                apiErrorDescription = errorResponse.error
            } else {
                apiErrorDescription = HTTPURLResponse.localizedString(
                    forStatusCode: httpResponse.statusCode
                )
                print(
                    "Warning: Could not decode generic error response for status code \(httpResponse.statusCode). Data received: \(String(data: data, encoding: .utf8) ?? "N/A")"
                )
            }
            throw APIError.badServerResponse(
                statusCode: httpResponse.statusCode,
                description: apiErrorDescription
            )
        }
    }

    // MARK: - Generate Request Endpoint
    func generate(requestBody: GenerateRequest) async throws
        -> GenerateRequestResponse
    {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let httpBody: Data
        do {
            httpBody = try encoder.encode(requestBody)
        } catch {
            throw APIError.jsonEncodingError(error)
        }

        return try await performRequest(
            endpoint: "api/generate",
            method: .post,
            body: httpBody
        )
    }

    // MARK: - List Local Models Endpoint
    func listLocalModels() async throws -> ListLocalModelResponse {
        try await performRequest(endpoint: "api/tags", method: .get)
    }

    // MARK: - List Running Models Endpoint
    func listRunningModels() async throws -> ListRunningModelResponse {
        try await performRequest(endpoint: "api/ps", method: .get)
    }

    // MARK: - Version Endpoint
    func version() async throws -> VersionResponse {
        try await performRequest(endpoint: "api/version", method: .get)
    }

    // MARK: - Remove Model Endpoint
    func removeModel(requestBody: RemoveModelRequest) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let httpBody: Data
        do {
            httpBody = try encoder.encode(requestBody)
        } catch {
            throw APIError.jsonEncodingError(error)
        }

        try await performRequestNoResponseBody(
            endpoint: "api/delete",
            method: .delete,
            body: httpBody
        )
    }

}
