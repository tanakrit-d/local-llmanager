//
//  APIModels.swift
//  local-llmanager
//
//  Created by Dominic McRae on 22/04/2025.
//

import Foundation

// MARK: - Generate Request
/// Represents the request body for the Ollama /api/generate endpoint.
struct GenerateRequest: Encodable {
    /// The model name (e.g., "llama2", "mistral"). Required.
    let model: String

    /// Additional model parameters. Optional.
    let options: Options?

    /// If false the response will be returned as a single response object,
    /// rather than a stream of objects. Defaults to false in this model
    /// based on your specified use case.
    let stream: Bool

    /// Controls how long the model will stay loaded in memory following the request.
    /// Accepts durations like "10m" (10 minutes), "1h" (1 hour),
    /// "0" (unload immediately), or "-1" (keep loaded indefinitely). Optional.
    let keepAlive: String?

    // Initialize with required parameters and optional ones
    init(
        model: String,
        options: Options? = nil,
        stream: Bool = false,
        keepAlive: String? = nil
    ) {
        self.model = model
        self.options = options
        self.stream = stream
        self.keepAlive = keepAlive
    }

    // Map Swift properties to JSON keys
    enum CodingKeys: String, CodingKey {
        case model
        case options
        case stream
        case keepAlive = "keep_alive"
    }
}

// MARK: - Generate Request (Options)
/// Represents the structure for the optional 'options' parameter
/// in the /api/generate request. Includes common model parameters.
struct Options: Encodable {
    let temperature: Double?
    let numPredict: Int?
    let topK: Int?
    let topP: Double?
    let repeatPenalty: Double?

    // Initialize with optional parameters
    init(
        temperature: Double? = nil,
        numPredict: Int? = nil,
        topK: Int? = nil,
        topP: Double? = nil,
        repeatPenalty: Double? = nil
    ) {
        self.temperature = temperature
        self.numPredict = numPredict
        self.topK = topK
        self.topP = topP
        self.repeatPenalty = repeatPenalty
    }

    // Map Swift properties to JSON keys
    enum CodingKeys: String, CodingKey {
        case temperature
        case numPredict = "num_predict"
        case topK = "top_k"
        case topP = "top_p"
        case repeatPenalty = "repeat_penalty"
    }
}

// MARK: - Generate Request Response
/// Represents the response body for the Ollama /api/generate endpoint
/// when streaming is disabled (`"stream": false`) or the final chunk
/// when streaming is enabled. Contains the generated response and metrics.
struct GenerateRequestResponse: Codable {
    let model, createdAt, response: String
    let done: Bool
    let context: [Int]
    let totalDuration, loadDuration, promptEvalCount, promptEvalDuration: Int
    let evalCount, evalDuration: Int

    // Map JSON keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response, done, context
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }
}

// MARK: - Local Model
/// Represents a single local model object returned within the
/// ListLocalModelsResponse from the /api/tags endpoint.
struct LocalModel: Codable {
    var id: String { digest }
    let name: String
    let model: String
    let modifiedAt: String
    let size: Int
    let digest: String
    let details: LocalModelDetails

    enum CodingKeys: String, CodingKey {
        case name
        case model
        case modifiedAt = "modified_at"
        case size, digest, details
    }
}

// MARK: - Local Model Details
/// Contains detailed information about a local model's structure.
struct LocalModelDetails: Codable {
    let format: String
    let family: String
    let families: [String]?
    let parameterSize: String?
    let quantizationLevel: String?

    // Map JSON keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case format, family, families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }
}

// MARK: - List Local Model Response
/// Represents the top-level response body for the Ollama /api/tags endpoint.
/// Contains a list of locally available models.
struct ListLocalModelResponse: Codable {
    let models: [LocalModel]
}

// MARK: - Running Model
/// Represents a single running model object returned within the
/// ListRunningModels from the /api/ps endpoint.
struct RunningModel: Codable {
    var id: String { digest }
    let name: String
    let model: String
    let size: Int
    let digest: String
    let details: RunningModelDetails
    let expiresAt: String
    let sizeVRAM: Int

    // Map JSON keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case name, model, size, digest, details
        case expiresAt = "expires_at"
        case sizeVRAM = "size_vram"
    }
}

// MARK: - Running Model Details
/// Contains detailed information about a running model instance's structure.
struct RunningModelDetails: Codable {
    let parentModel: String
    let format: String
    let family: String
    let families: [String]?
    let parameterSize: String
    let quantizationLevel: String

    // Map JSON keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case parentModel = "parent_model"
        case format, family, families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }
}

// MARK: - List Running Model Response

/// Represents the top-level response body for the Ollama /api/ps endpoint.
/// Contains a list of models currently loaded and running.
struct ListRunningModelResponse: Codable {
    let models: [RunningModel]  // Array of individual running model details
}

// MARK: - Version Response
/// Represents the response body for the Ollama /api/version endpoint.
struct VersionResponse: Codable {
    let version: String
}

// MARK: - Remove Model Request
/// Represents the request body for the Ollama /api/delete endpoint.
struct RemoveModelRequest: Codable {
    let model: String
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error {
    case badServerResponse(statusCode: Int, description: String)
    case jsonDecodingError(Error)
    case jsonEncodingError(Error)
    case invalidURL
    case requestBuildingError(String)
    case unexpectedResponse
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .badServerResponse(let statusCode, let description):
            return
                "Ollama API request failed with status code \(statusCode): \(description)"
        case .jsonDecodingError(let error):
            return "JSON decoding error: \(error.localizedDescription)"
        case .jsonEncodingError(let error):
            return "JSON encoding error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL constructed for the API request."
        case .requestBuildingError(let description):
            return "Failed to build the request: \(description)"
        case .unexpectedResponse:
            return "Received an unexpected response type from the server."
        }
    }
}

struct ErrorResponse: Decodable {
    let error: String
}
