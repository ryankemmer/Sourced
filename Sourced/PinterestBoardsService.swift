//
//  PinterestBoardsService.swift
//  Sourced
//
//  Handles fetching Pinterest boards from backend
//

import Foundation

struct PinterestBoardsResponse: Codable {
    let message: String
    let boards: [PinterestBoard]
    let bookmark: String?
}

enum PinterestBoardsError: Error {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case networkError(Error)
}

class PinterestBoardsService {
    static let shared = PinterestBoardsService()

    private let endpoint = "https://k2nebib668.execute-api.us-east-1.amazonaws.com/prod/pinterest-boards"

    func fetchBoards(
        userId: String,
        accessToken: String,
        refreshToken: String?,
        expiresIn: Int?,
        accessTokenExpiresAt: String?,
        refreshTokenExpiresIn: Int?,
        refreshTokenExpiresAt: String?
    ) async throws -> [PinterestBoard] {
        guard let url = URL(string: endpoint) else {
            throw PinterestBoardsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body
        var body: [String: Any] = [
            "userId": userId,
            "access_token": accessToken
        ]

        if let refreshToken = refreshToken {
            body["refresh_token"] = refreshToken
        }
        if let expiresIn = expiresIn {
            body["expires_in"] = expiresIn
        }
        if let accessTokenExpiresAt = accessTokenExpiresAt {
            body["access_token_expires_at"] = accessTokenExpiresAt
        }
        if let refreshTokenExpiresIn = refreshTokenExpiresIn {
            body["refresh_token_expires_in"] = refreshTokenExpiresIn
        }
        if let refreshTokenExpiresAt = refreshTokenExpiresAt {
            body["refresh_token_expires_at"] = refreshTokenExpiresAt
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("=== Pinterest Boards Request ===")
        print("URL: \(endpoint)")
        print("Body: \(body)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw PinterestBoardsError.invalidResponse
            }

            print("=== Pinterest Boards Response ===")
            print("Status: \(httpResponse.statusCode)")
            print("Body: \(String(data: data, encoding: .utf8) ?? "<non-utf8>")")

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw PinterestBoardsError.serverError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }

            let boardsResponse = try JSONDecoder().decode(PinterestBoardsResponse.self, from: data)
            return boardsResponse.boards

        } catch let error as PinterestBoardsError {
            throw error
        } catch {
            throw PinterestBoardsError.networkError(error)
        }
    }
}
