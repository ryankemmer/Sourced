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
    @Published var email: String = ""
    @Published var password: String = ""

    // Profile
    @Published var firstName: String = ""
    @Published var username: String = ""

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
}
