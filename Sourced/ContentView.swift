//
//  ContentView.swift
//  Sourced
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var flow: OnboardingFlow
    @StateObject private var authManager = AuthManager.shared
    @State private var isCheckingAuth = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if isCheckingAuth {
                // Show loading while checking auth status
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.6))
                }
            } else {
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
                case .editProfile:
                    EditProfileScreen()
                case .editBrands:
                    EditBrandsScreen()
                case .editSizing:
                    EditSizingScreen()
                }
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

                    // Load cached profile photo immediately (no delay)
                    if let cachedImage = ImageCache.shared.loadImage(forKey: "profile_\(savedUserId)") {
                        flow.profilePhoto = cachedImage
                        print("Loaded profile photo from cache")
                    }

                    // If onboarding is complete, go straight to feed
                    if authManager.onboardingComplete {
                        print("Onboarding complete (cached), going to feed")
                        flow.step = .feed
                        // Fetch profile in background to sync data
                        Task {
                            await fetchProfileInBackground(userId: savedUserId)
                        }
                    } else {
                        // Need to check onboarding status from API
                        isCheckingAuth = true
                        Task {
                            await fetchProfileAndNavigate(userId: savedUserId)
                        }
                    }
                }
            }
        }
    }

    private func fetchProfileAndNavigate(userId: String) async {
        do {
            if let profile = try await ProfileService.shared.fetchProfile(userId: userId) {
                await MainActor.run {
                    // Populate flow with profile data
                    if let fn = profile.firstName, !fn.isEmpty {
                        flow.firstName = fn
                    }
                    if let un = profile.username, !un.isEmpty {
                        flow.username = un
                    }
                    if let photoString = profile.profilePhoto, !photoString.isEmpty {
                        // Load profile photo (URL or base64)
                        Task {
                            if let image = await loadProfileImage(from: photoString) {
                                await MainActor.run {
                                    flow.profilePhoto = image
                                    ImageCache.shared.saveImage(image, forKey: "profile_\(userId)")
                                }
                            }
                        }
                    }
                    if let boards = profile.selectedPinterestBoards {
                        flow.selectedPinterestBoards = Set(boards)
                    }
                    if let brands = profile.selectedBrands {
                        flow.selectedBrands = Set(brands)
                    }
                    if let gender = profile.sizingGender {
                        flow.sizingGender = SizingGender.fromAPI(gender)
                    }
                    if let mens = profile.mensSizes {
                        flow.mensSizes.tops = mens.tops ?? ""
                        flow.mensSizes.bottoms = mens.bottoms ?? ""
                        flow.mensSizes.outerwear = mens.outerwear ?? ""
                        flow.mensSizes.footwear = mens.footwear ?? ""
                        flow.mensSizes.tailoring = mens.tailoring ?? ""
                        flow.mensSizes.accessories = mens.accessories ?? ""
                    }
                    if let womens = profile.womensSizes {
                        flow.womensSizes.tops = womens.tops ?? ""
                        flow.womensSizes.bottoms = womens.bottoms ?? ""
                        flow.womensSizes.outerwear = womens.outerwear ?? ""
                        flow.womensSizes.dresses = womens.dresses ?? ""
                    }

                    // Check if onboarding is complete
                    if profile.onboardingComplete == true {
                        print("Onboarding complete, going to feed")
                        AuthManager.shared.setOnboardingComplete(true)
                        flow.step = .feed
                    } else {
                        print("Onboarding not complete, starting onboarding")
                        flow.step = .basicProfile
                    }
                    isCheckingAuth = false
                }
            } else {
                // No profile found, start onboarding
                await MainActor.run {
                    print("No profile found, starting onboarding")
                    flow.step = .basicProfile
                    isCheckingAuth = false
                }
            }
        } catch {
            // On error, default to onboarding
            await MainActor.run {
                print("Error fetching profile: \(error), starting onboarding")
                flow.step = .basicProfile
                isCheckingAuth = false
            }
        }
    }

    private func fetchProfileInBackground(userId: String) async {
        do {
            if let profile = try await ProfileService.shared.fetchProfile(userId: userId) {
                await MainActor.run {
                    // Silently update flow with profile data
                    if let fn = profile.firstName, !fn.isEmpty {
                        flow.firstName = fn
                    }
                    if let un = profile.username, !un.isEmpty {
                        flow.username = un
                    }
                    if let boards = profile.selectedPinterestBoards {
                        flow.selectedPinterestBoards = Set(boards)
                    }
                    if let brands = profile.selectedBrands {
                        flow.selectedBrands = Set(brands)
                    }
                    if let gender = profile.sizingGender {
                        flow.sizingGender = SizingGender.fromAPI(gender)
                    }
                    if let mens = profile.mensSizes {
                        flow.mensSizes.tops = mens.tops ?? ""
                        flow.mensSizes.bottoms = mens.bottoms ?? ""
                        flow.mensSizes.outerwear = mens.outerwear ?? ""
                        flow.mensSizes.footwear = mens.footwear ?? ""
                        flow.mensSizes.tailoring = mens.tailoring ?? ""
                        flow.mensSizes.accessories = mens.accessories ?? ""
                    }
                    if let womens = profile.womensSizes {
                        flow.womensSizes.tops = womens.tops ?? ""
                        flow.womensSizes.bottoms = womens.bottoms ?? ""
                        flow.womensSizes.outerwear = womens.outerwear ?? ""
                        flow.womensSizes.dresses = womens.dresses ?? ""
                    }
                }

                // Load profile photo separately
                if let photoString = profile.profilePhoto, !photoString.isEmpty {
                    if let image = await loadProfileImage(from: photoString) {
                        await MainActor.run {
                            flow.profilePhoto = image
                            ImageCache.shared.saveImage(image, forKey: "profile_\(userId)")
                            print("Profile photo loaded from API")
                        }
                    }
                }
            }
        } catch {
            print("Background profile fetch failed: \(error)")
        }
    }

    private func loadProfileImage(from photoString: String) async -> UIImage? {
        // Check if it's a URL
        if photoString.hasPrefix("http"), let url = URL(string: photoString) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return UIImage(data: data)
            } catch {
                print("Failed to load profile image from URL: \(error)")
                return nil
            }
        }

        // Check if it's base64
        if let dataRange = photoString.range(of: "base64,") {
            let base64String = String(photoString[dataRange.upperBound...])
            if let imageData = Data(base64Encoded: base64String) {
                return UIImage(data: imageData)
            }
        }

        return nil
    }
}

#Preview {
    ContentView()
        .environmentObject(OnboardingFlow())
}
