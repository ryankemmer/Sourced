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
            case .selectPinterestBoard:
                SelectPinterestBoardScreen()
            case .uploadOutfits:
                OutfitUploadScreen()
            case .styleProfile:
                StyleProfileScreen()
            case .sizingProfile:
                SizingProfileScreen()
            case .vibeLoading:
                VibeLoadingScreen()
            case .feed:
                PersonalizedFeedScreen()
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            // Check if user is already authenticated
            if authManager.isAuthenticated {
                // Restore userId from saved state
                if let savedUserId = authManager.currentUserId {
                    flow.userId = savedUserId
                    print("Restored userId from AuthManager: \(savedUserId)")
                }
                flow.step = .feed
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(OnboardingFlow())
}
