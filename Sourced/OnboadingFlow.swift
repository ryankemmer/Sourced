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
            case selectPinterestBoard
            case uploadOutfits
            case styleProfile
            case sizingProfile
            case vibeLoading
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
    @Published var R: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var authError: String?

    // Profile
    @Published var firstName: String = ""
    @Published var username: String = ""
    @Published var profilePhoto: UIImage?

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

    // Pinterest auth data
    @Published var pinterestAccessToken: String = ""
    @Published var pinterestRefreshToken: String = ""
    @Published var pinterestTokenExpiresIn: Int = 0
    @Published var pinterestScope: String = ""
    @Published var pinterestBoards: [PinterestBoard] = []
    @Published var selectedPinterestBoards: Set<String> = []  // Set of board IDs

    // Style profile
    @Published var selectedBrands: Set<String> = []
    @Published var selectedFabrics: Set<String> = []
    @Published var selectedAesthetics: Set<String> = []
    @Published var sizingGender: SizingGender = .mens
    @Published var mensSizes = MensSizes()
    @Published var womensSizes = WomensSizes()

    init() {
        // Restore userId from saved auth state
        if let savedUserId = AuthManager.shared.currentUserId {
            userId = savedUserId
            print("OnboardingFlow initialized with saved userId: \(savedUserId)")
        }
    }

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
                if response.success, let responseUserId = response.userId, !responseUserId.isEmpty {
                    userId = responseUserId

                    print("=== Authentication Successful ===")
                    print("userId: \(userId)")

                    // Save userId to persist login
                    AuthManager.shared.saveAuthState(userId: userId)

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
    var tops: String = ""
    var bottoms: String = ""
    var outerwear: String = ""
    var footwear: String = ""
    var tailoring: String = ""
    var accessories: String = ""

    static let topsOptions = ["XXS/40", "XS/42", "S/44-46", "M/48-50", "L/52-54", "XL/56", "XXL/58"]
    static let bottomsOptions = ["26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44"]
    static let outerwearOptions = ["XXS/40", "XS/42", "S/44-46", "M/48-50", "L/52-54", "XL/56", "XXL/58"]
    static let footwearOptions = ["5", "5.5", "6", "6.5", "7", "7.5", "8", "8.5", "9", "9.5", "10", "10.5", "11", "11.5", "12", "12.5", "13", "14", "15"]
    static let tailoringOptions = ["34S", "34R", "36S", "36R", "38S", "38R", "38L", "40S", "40R", "40L", "42S", "42R", "42L", "44S", "44R", "44L", "46S", "46R", "46L", "48S", "48R", "48L", "50S", "50R", "50L", "52S", "52R", "52L", "54R", "54L"]
    static let accessoriesOptions = ["OS", "26", "28", "30", "32", "34", "36", "38", "40", "42", "44", "46"]
}

struct WomensSizes {
    var tops: String = ""
    var bottoms: String = ""
    var outerwear: String = ""
    var dresses: String = ""

    static let topsOptions = ["XXS/00/34", "XS/0-2/36-38", "S/4/40", "M/6-8/42-44", "L/10/46", "XL/12-14/48-50", "XXL/16-18/52-54", "3XL/20-22", "4XL/24-26", "OS"]
    static let bottomsOptions = ["22", "23", "24/00/34", "25/0/36", "26/2/38", "27/4/40", "28/6/42", "29", "30/8/44", "31", "32/10/46", "33", "34/12/48", "35", "36/14/50", "37", "38/16/52", "39", "40/18", "41", "42/20"]
    static let outerwearOptions = ["XXS/00/34", "XS/0-2/36-38", "S/4/40", "M/6-8/42-44", "L/10/46", "XL/12-14/48-50", "XXL/16-18/52-54", "3XL/20-22", "4XL/24-26", "OS"]
    static let dressesOptions = ["XXS/00/34", "XS/0-2/36-38", "S/4/40", "M/6-8/42-44", "L/10/46", "XL/12-14/48-50", "XXL/16-18/52-54", "3XL/20-22", "4XL/24-26", "OS"]
}

struct PinterestPin: Identifiable, Codable, Hashable {
    let id: String
    let media: PinterestMedia?

    struct PinterestMedia: Codable, Hashable {
        let images: [String: PinterestImage]?

        struct PinterestImage: Codable, Hashable {
            let url: String?
            let width: Int?
            let height: Int?
        }
    }
}

struct PinterestBoard: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let pin_count: Int?
    let pins: [PinterestPin]?

    var pinCount: Int {
        pin_count ?? 0
    }

    var pinImages: [String] {
        pins?.compactMap { pin in
            pin.media?.images?["originals"]?.url ??
            pin.media?.images?["400x300"]?.url ??
            pin.media?.images?["600x"]?.url
        } ?? []
    }
}
