//
//  ApiClient.swift
//  RentTracker
//
//  Created by Rene Bonilla on 5/3/26.
//
import Foundation

class ApiClient {
    static let shared = ApiClient()
    private init() {}
    
    #if DEBUG
    private let baseURL = "http://localhost:3000"
    #else
    private let baseURL = "https://your-app.up.railway.app"
    #endif
    
    // MARK: - Logging

    private func logRequest(_ request: URLRequest) {
        print("📡 [\(request.httpMethod ?? "?")] \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Body: \(bodyString)")
        }
        if let headers = request.allHTTPHeaderFields {
            print("🔑 Headers: \(headers)")
        }
    }

    private func logResponse(_ data: Data, _ response: HTTPURLResponse) {
        let body = String(data: data, encoding: .utf8) ?? "empty"
        print("✅ [\(response.statusCode)] \(body)")
    }

    private func logError(_ error: Error, _ data: Data? = nil) {
        print("❌ Error: \(error.localizedDescription)")
        if let data = data, let body = String(data: data, encoding: .utf8) {
            print("❌ Response: \(body)")
        }
    }

    // MARK: - Requests

    func request<T: Codable>(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
                    throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // Inject JWT token if authenticated
        if authenticated, let token = KeychainHelper.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        logResponse(data, httpResponse)

        guard (200...299).contains(httpResponse.statusCode) else {
           // Try to parse the error message from the server response
           var serverMessage = "Unknown error"
           if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["error"] as? String {
               serverMessage = message
           }

           if httpResponse.statusCode == 401 {
               logError(APIError.unauthorized(message: serverMessage), data)
               throw APIError.unauthorized(message: serverMessage)
           }
           logError(APIError.serverError(statusCode: httpResponse.statusCode, message: serverMessage), data)
           throw APIError.serverError(statusCode: httpResponse.statusCode, message: serverMessage)
       }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    // For requests that return no body (like DELETE 204)
       func requestNoContent(
           path: String,
           method: String,
           body: [String: Any]? = nil,
           authenticated: Bool = true
       ) async throws {
           guard let url = URL(string: "\(baseURL)\(path)") else {
               throw APIError.invalidURL
           }
           
           var request = URLRequest(url: url)
           request.httpMethod = method
           request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
           
           if authenticated, let token = KeychainHelper.shared.getToken() {
               request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
           }
           
           if let body = body {
               request.httpBody = try JSONSerialization.data(withJSONObject: body)
           }
           
           logRequest(request)

           let (data, response) = try await URLSession.shared.data(for: request)

           guard let httpResponse = response as? HTTPURLResponse else {
               throw APIError.invalidResponse
           }

           logResponse(data, httpResponse)

           guard (200...299).contains(httpResponse.statusCode) else {
               logError(APIError.invalidResponse, data)
               throw APIError.invalidResponse
           }
       }
    
    enum APIError: LocalizedError {
        case invalidURL
        case invalidResponse
        case unauthorized(message: String = "Session expired. Please log in again.")
        case serverError(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid response from server"
            case .unauthorized(let message): return message
            case .serverError(_, let message): return message
            }
        }
    }
}
