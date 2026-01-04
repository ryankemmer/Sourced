//
//  PinterestAuthService.swift
//  Sourced
//
//  Handles Pinterest OAuth authentication
//

import Foundation
import AuthenticationServices
import Combine

struct PinterestTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int?
    let refresh_token: String?
    let scope: String?
}

struct PinterestAuthData: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let scope: String?
}

enum PinterestAuthError: Error {
    case authorizationFailed
    case tokenExchangeFailed
    case invalidURL
    case backendError(String)
}

class PinterestAuthService: NSObject, ObservableObject {
    @Published var isAuthenticating = false
    @Published var authError: String?

    private var authSession: ASWebAuthenticationSession?
    private var completionHandler: ((Result<PinterestAuthData, PinterestAuthError>) -> Void)?

    func authenticate(completion: @escaping (Result<PinterestAuthData, PinterestAuthError>) -> Void) {
        self.completionHandler = completion
        isAuthenticating = true
        authError = nil

        // Build Pinterest OAuth URL
        let scope = Config.pinterestScopes
        let state = UUID().uuidString

        var components = URLComponents(string: "https://www.pinterest.com/oauth/")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Config.pinterestAppID),
            URLQueryItem(name: "redirect_uri", value: Config.pinterestRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: state)
        ]

        guard let authURL = components.url else {
            completion(.failure(.invalidURL))
            isAuthenticating = false
            return
        }

        print("=== Pinterest Authorization Request ===")
        print("Auth URL: \(authURL)")
        print("Client ID: \(Config.pinterestAppID)")
        print("Redirect URI: \(Config.pinterestRedirectURI)")
        print("Scopes: \(scope)")

        // Start web authentication session
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "com.ryankemmer.sourced"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }

            if let error = error {
                print("Pinterest auth error: \(error)")
                self.authError = "Authentication cancelled"
                self.completionHandler?(.failure(.authorizationFailed))
                self.isAuthenticating = false
                return
            }

            guard let callbackURL = callbackURL else {
                self.authError = "No callback URL received"
                self.completionHandler?(.failure(.authorizationFailed))
                self.isAuthenticating = false
                return
            }

            // Check callback URL for success/error
            print("=== Pinterest Callback ===")
            print("Full callback URL: \(callbackURL.absoluteString)")

            guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
                self.authError = "Invalid callback URL"
                self.completionHandler?(.failure(.authorizationFailed))
                self.isAuthenticating = false
                return
            }

            print("Scheme: \(components.scheme ?? "none")")
            print("Host: \(components.host ?? "none")")
            print("Path: \(components.path)")
            print("Query string: \(components.query ?? "none")")
            print("All query items:")
            if let queryItems = components.queryItems {
                for item in queryItems {
                    print("  - \(item.name) = \(item.value ?? "nil")")
                }
            } else {
                print("  (no query items)")
            }

            // Check for success parameter (Lambda already handled token exchange)
            if let success = components.queryItems?.first(where: { $0.name == "success" })?.value,
               success == "true" {
                print("Pinterest auth successful (handled by backend)")

                // Extract actual tokens from callback URL
                let accessToken = components.queryItems?.first(where: { $0.name == "access_token" })?.value ?? ""
                let refreshToken = components.queryItems?.first(where: { $0.name == "refresh_token" })?.value
                let expiresInStr = components.queryItems?.first(where: { $0.name == "expires_in" })?.value
                let expiresIn = expiresInStr.flatMap { Int($0) }
                let scope = components.queryItems?.first(where: { $0.name == "scope" })?.value

                print("Extracted tokens from callback:")
                print("  - access_token: \(accessToken.isEmpty ? "MISSING" : "present (\(accessToken.prefix(20))...)")")
                print("  - refresh_token: \(refreshToken != nil ? "present" : "nil")")
                print("  - expires_in: \(expiresIn?.description ?? "nil")")
                print("  - scope: \(scope ?? "nil")")

                let authData = PinterestAuthData(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: expiresIn,
                    scope: scope
                )

                Task { @MainActor in
                    self.completionHandler?(.success(authData))
                    self.isAuthenticating = false
                }
                return
            }

            // Check for error parameter
            if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
                print("Pinterest auth error: \(error)")
                Task { @MainActor in
                    self.authError = error
                    self.completionHandler?(.failure(.authorizationFailed))
                    self.isAuthenticating = false
                }
                return
            }

            // Fallback error
            Task { @MainActor in
                self.authError = "Unknown callback response"
                self.completionHandler?(.failure(.authorizationFailed))
                self.isAuthenticating = false
            }
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }

    private func exchangeCodeForToken(code: String) async {
        do {
            let tokenURL = URL(string: "https://api.pinterest.com/v5/oauth/token")!
            var request = URLRequest(url: tokenURL)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            // ✅ Basic Auth like Python requests(auth=(id, secret))
            let creds = "\(Config.pinterestAppID):\(Config.pinterestAppSecret)"
            let base64 = Data(creds.utf8).base64EncodedString()
            request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

            // ✅ IMPORTANT: redirect_uri must EXACTLY match what you used in authorize
            let redirect = Config.pinterestRedirectURI

            // ✅ Form body exactly like Python
            let body = [
                "grant_type=authorization_code",
                "code=\(urlEncode(code))",
                "redirect_uri=\(urlEncode(redirect))"
            ].joined(separator: "&")

            request.httpBody = body.data(using: .utf8)

            print("=== Pinterest Token Exchange ===")
            print("redirect_uri: \(redirect)")
            print("Has Authorization header: \(request.value(forHTTPHeaderField: "Authorization") != nil)")

            let (data, response) = try await URLSession.shared.data(for: request)
            let http = response as? HTTPURLResponse
            print("Token response status: \(http?.statusCode ?? -1)")
            print("Token response body: \(String(data: data, encoding: .utf8) ?? "<non-utf8>")")

            guard let http, http.statusCode == 200 else {
                await MainActor.run {
                    self.authError = "Failed to exchange code for token"
                    self.completionHandler?(.failure(.tokenExchangeFailed))
                    self.isAuthenticating = false
                }
                return
            }

            let tokenResponse = try JSONDecoder().decode(PinterestTokenResponse.self, from: data)
            let authData = PinterestAuthData(
                accessToken: tokenResponse.access_token,
                refreshToken: tokenResponse.refresh_token,
                expiresIn: tokenResponse.expires_in,
                scope: tokenResponse.scope
            )

            await MainActor.run {
                self.completionHandler?(.success(authData))
                self.isAuthenticating = false
            }
        } catch {
            print("Token exchange error: \(error)")
            await MainActor.run {
                self.authError = error.localizedDescription
                self.completionHandler?(.failure(.tokenExchangeFailed))
                self.isAuthenticating = false
            }
        }
    }

    private func urlEncode(_ s: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?")
        return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
    }
}

extension PinterestAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
