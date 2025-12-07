//
//  ContentView.swift
//  Sourced
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var flow: OnboardingFlow

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            switch flow.step {
            case .welcome:
                WelcomeScreen()
            case .emailAuth:
                EmailAuthScreen()
            case .basicProfile:
                BasicProfileScreen()
            case .personalizationChoice:
                PersonalizationChoiceScreen()
            case .pinterestOAuth:
                PinterestOAuthScreen()
            case .uploadOutfits:
                OutfitUploadScreen()
            case .styleProfile:
                StyleProfileScreen()
            case .sizingProfile:
                SizingProfileScreen()
            case .vibeLoading:
                VibeLoadingScreen()
            case .styleSummary:
                StyleSummaryScreen()
            case .feed:
                PersonalizedFeedScreen()
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .environmentObject(OnboardingFlow())
}
