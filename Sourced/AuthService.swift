//
//  AuthService.swift
//  Sourced
//
//  Handles authentication API calls
//

import Foundation

enum AuthMechanism: String {
    case standard = "Standard"
    case google = "Google"
    case apple = "Apple"
}

struct AuthRequest: Codable {
    let email: String
    let password: String
    let authMechanism: String
}

struct AuthUser: Codable {
    let userId: String
    let email: String
    let authMechanism: String?
    let authProviderId: String?
    let createdAt: String?
}

struct AuthResponse: Codable {
    let message: String
    let user: AuthUser?
    let token: String?

    // Computed properties for backwards compatibility
    var success: Bool {
        return user != nil
    }

    var userId: String? {
        return user?.userId
    }
}

struct ErrorResponse: Codable {
    let error: String
}

enum AuthError: Error {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case networkError(Error)
}

class AuthService {
    static let shared = AuthService()
    private let authEndpoint = Config.authEndpoint

    private init() {}

    func authenticate(
        email: String,
        password: String,
        mechanism: AuthMechanism
    ) async throws -> AuthResponse {
        guard let url = URL(string: authEndpoint) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let authRequest = AuthRequest(
            email: email,
            password: password,
            authMechanism: mechanism.rawValue
        )

        request.httpBody = try JSONEncoder().encode(authRequest)

        // Debug logging
        print("=== Auth Request ===")
        print("URL: \(url)")
        print("Method: \(request.httpMethod ?? "UNKNOWN")")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("Body: \(bodyString)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            // Debug logging
            print("=== Auth Response ===")
            print("Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Body: \(responseString)")
            }

            // Accept any 2xx status code as success
            if (200...299).contains(httpResponse.statusCode) {
                // Try to decode the response, but if it fails, throw error
                if let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                    return authResponse
                } else {
                    // If we can't decode the response, throw error with response body
                    let responseBody = String(data: data, encoding: .utf8) ?? "Unknown response"
                    throw AuthError.serverError("Failed to parse response: \(responseBody)")
                }
            } else {
                // Try to decode error message from backend in different formats
                if let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                } else if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.error)
                } else if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                    // Show raw response if we can't decode it
                    throw AuthError.serverError(errorString)
                } else {
                    throw AuthError.serverError("Authentication failed (HTTP \(httpResponse.statusCode))")
                }
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
}
