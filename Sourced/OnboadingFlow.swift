//
//  OnboardingFlow.swift
//  Sourced
//

import SwiftUI
import Combine

final class OnboardingFlow: ObservableObject {
    enum Step {
            case welcome
            case emailAuth
            case basicProfile
            case personalizationChoice
            case pinterestOAuth
            case uploadOutfits
            case styleProfile
            case sizingProfile
            case vibeLoading
            case styleSummary
            case feed
        }

    @Published var step: Step = .welcome

    // Auth
    @Published var authMethod: AuthMethod = .none
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var appleUserID: String = ""
    @Published var googleUserID: String = ""
    @Published var authToken: String = ""
    @Published var userId: String = ""
    @Published var isAuthenticating: Bool = false
    @Published var authError: String?

    // Profile
    @Published var firstName: String = ""
    @Published var username: String = ""

    enum AuthMethod {
        case none
        case apple
        case google
        case email
    }

    // Personalization choices
    @Published var prefersPinterest: Bool = false
    @Published var prefersUpload: Bool = false
    @Published var connectedPinterest: Bool = false
    @Published var uploadedImageCount: Int = 0

    // Style profile
    @Published var selectedBrands: Set<String> = []
    @Published var selectedFabrics: Set<String> = []
    @Published var selectedAesthetics: Set<String> = []
    @Published var sizingGender: SizingGender = .mens
    @Published var mensSizes = MensSizes()
    @Published var womensSizes = WomensSizes()

    func authenticate() async {
        await MainActor.run {
            isAuthenticating = true
            authError = nil
        }

        let mechanism: AuthMechanism
        let passwordToSend: String

        switch authMethod {
        case .email:
            mechanism = .standard
            passwordToSend = password
        case .google:
            mechanism = .google
            passwordToSend = googleUserID
        case .apple:
            mechanism = .apple
            passwordToSend = appleUserID
        case .none:
            await MainActor.run {
                isAuthenticating = false
                authError = "No authentication method selected"
            }
            return
        }

        do {
            let response = try await AuthService.shared.authenticate(
                email: email,
                password: passwordToSend,
                mechanism: mechanism
            )

            await MainActor.run {
                if response.success {
                    authToken = response.token ?? ""
                    userId = response.userId ?? ""

                    // Save auth state to persist login
                    AuthManager.shared.saveAuthState(token: authToken, userId: userId)

                    step = .basicProfile
                } else {
                    authError = response.message ?? "Authentication failed"
                }
                isAuthenticating = false
            }
        } catch let error as AuthError {
            await MainActor.run {
                switch error {
                case .invalidURL:
                    authError = "Invalid server URL"
                case .invalidResponse:
                    authError = "Invalid server response"
                case .serverError(let message):
                    authError = message
                case .networkError(let err):
                    authError = "Network error: \(err.localizedDescription)"
                }
                isAuthenticating = false
            }
        } catch {
            await MainActor.run {
                authError = "Unexpected error: \(error.localizedDescription)"
                isAuthenticating = false
            }
        }
    }

    func logout() {
        // Clear auth state
        AuthManager.shared.logout()

        // Reset flow state
        authMethod = .none
        email = ""
        password = ""
        appleUserID = ""
        googleUserID = ""
        authToken = ""
        userId = ""
        firstName = ""
        username = ""

        // Go back to welcome screen
        step = .welcome
    }

    func goToFeed() {
        step = .feed
    }

    func resetForPreview() {
        step = .feed
    }
}

enum SizingGender: String, CaseIterable {
    case mens = "Men’s"
    case womens = "Women’s"
}

struct MensSizes {
    var shirt: String = ""
    var pants: String = ""
    var jacket: String = ""
    var shoes: String = ""
}

struct WomensSizes {
    var shirt: String = ""
    var pants: String = ""
    var jacket: String = ""
    var shoes: String = ""
    var dress: String = ""
    var skirt: String = ""
    var sweaters: String = ""
    var handbags: String = ""
}
