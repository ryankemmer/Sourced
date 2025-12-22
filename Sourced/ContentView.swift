//
//  ContentView.swift
//  Sourced
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var flow: OnboardingFlow
    @StateObject private var authManager = AuthManager.shared

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
        .onAppear {
            // Check if user is already authenticated
            if authManager.isAuthenticated {
                flow.step = .feed
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(OnboardingFlow())
}
