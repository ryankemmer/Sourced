//
//  PersonalizationScreens.swift
//  Sourced
//

import SwiftUI
import PhotosUI

// MARK: - Pinterest OAuth (stubbed)

struct PinterestOAuthScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @StateObject private var pinterestAuth = PinterestAuthService()

    var body: some View {
        OnboardingShell(
            title: "Connect Pinterest",
            subtitle: "We’ll scan your boards to learn your color story, silhouettes, and recurring themes.",
            showBack: true,
            backAction: { flow.step = .personalizationChoice }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .overlay(
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Circle().stroke(Color.black.opacity(0.4), lineWidth: 1)
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Image(systemName: "p.circle")
                                            .foregroundColor(.black)
                                            .font(.system(size: 18))
                                    )
                                Text("Read-only access")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            Text("We only pull:")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.9))
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Board names & descriptions")
                                Text("• Pin image URLs")
                                Text("• Board-level tags")
                            }
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.black.opacity(0.75))
                        }
                        .padding(14)
                    )

                if let authError = pinterestAuth.authError {
                    Text(authError)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.red.opacity(0.9))
                }

                Button {
                    startPinterestOAuth()
                } label: {
                    HStack {
                        if pinterestAuth.isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "p.circle")
                        }
                        Text(pinterestAuth.isAuthenticating ? "Connecting…" : "Connect Pinterest")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(pinterestAuth.isAuthenticating)

                Text("We only analyze images. We never publish or edit your boards.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.top, 8)
            }
        }
    }

    private func startPinterestOAuth() {
        // Ensure user is authenticated before connecting Pinterest
        guard !flow.userId.isEmpty else {
            print("ERROR: Cannot connect Pinterest - userId is empty. User must authenticate first.")
            pinterestAuth.authError = "Please complete authentication first"
            return
        }

        print("Starting Pinterest OAuth with userId: \(flow.userId)")

        pinterestAuth.authenticate { result in
            switch result {
            case .success(let authData):
                print("Pinterest auth successful!")
                print("Access token: \(authData.accessToken)")
                if let refreshToken = authData.refreshToken {
                    print("Refresh token: \(refreshToken)")
                }

                // Save Pinterest auth data to flow
                flow.pinterestAccessToken = authData.accessToken
                flow.pinterestRefreshToken = authData.refreshToken ?? ""
                flow.pinterestTokenExpiresIn = authData.expiresIn ?? 0
                flow.pinterestScope = authData.scope ?? ""

                // Mark Pinterest as connected and proceed to board selection
                flow.connectedPinterest = true
                flow.step = .selectPinterestBoard

            case .failure(let error):
                print("Pinterest auth failed: \(error)")
                // Error is already set in pinterestAuth.authError
            }
        }
    }
}

// MARK: - Select Pinterest Board

struct SelectPinterestBoardScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var isLoadingBoards = false
    @State private var loadError: String?

    var body: some View {
        OnboardingShell(
            title: "Select boards",
            subtitle: "Choose which boards we should analyze to understand your style. You can select multiple.",
            showBack: true,
            backAction: { flow.step = .pinterestOAuth }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingBoards {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                        Text("Loading your boards...")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let error = loadError {
                    VStack(spacing: 12) {
                        Text(error)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button {
                            loadBoards()
                        } label: {
                            Text("Try again")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.vertical, 20)
                } else if flow.pinterestBoards.isEmpty {
                    VStack(spacing: 12) {
                        Text("No boards found")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                        Button {
                            if flow.isEditingPreferences {
                                flow.isEditingPreferences = false
                                flow.step = .feed
                            } else {
                                flow.step = .styleProfile
                            }
                        } label: {
                            Text("Continue")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.vertical, 20)
                } else {
                    // Selected boards count
                    if !flow.selectedPinterestBoards.isEmpty {
                        Text("\(flow.selectedPinterestBoards.count) board\(flow.selectedPinterestBoards.count == 1 ? "" : "s") selected")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.6))
                    }

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(flow.pinterestBoards) { board in
                                let isSelected = flow.selectedPinterestBoards.contains(board.id)
                                Button {
                                    toggleBoard(board)
                                } label: {
                                    HStack(spacing: 12) {
                                        // Board preview with pin images
                                        BoardPreviewGrid(board: board)
                                            .frame(width: 60, height: 60)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(board.name)
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                .foregroundColor(.black)

                                            Text("\(board.pinCount) pins")
                                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                                .foregroundColor(.black.opacity(0.6))

                                            if let description = board.description, !description.isEmpty {
                                                Text(description)
                                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                                    .foregroundColor(.black.opacity(0.5))
                                                    .lineLimit(2)
                                            }
                                        }

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.black)
                                                .font(.system(size: 22))
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.black.opacity(0.2))
                                                .font(.system(size: 22))
                                        }
                                    }
                                    .padding(12)
                                    .background(isSelected ? Color.black.opacity(0.03) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isSelected ? Color.black.opacity(0.4) : Color.black.opacity(0.25), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }

                    Button {
                        continueWithSelectedBoards()
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(flow.selectedPinterestBoards.isEmpty)
                    .padding(.top, 8)
                }
            }
        }
        .onAppear {
            if flow.pinterestBoards.isEmpty && !isLoadingBoards {
                loadBoards()
            }
        }
    }

    private func loadBoards() {
        isLoadingBoards = true
        loadError = nil

        Task {
            do {
                // Validate required data
                guard !flow.userId.isEmpty else {
                    await MainActor.run {
                        loadError = "User ID is missing. Please restart authentication."
                        isLoadingBoards = false
                        print("ERROR: userId is empty!")
                    }
                    return
                }

                guard !flow.pinterestAccessToken.isEmpty else {
                    await MainActor.run {
                        loadError = "Pinterest access token is missing. Please reconnect Pinterest."
                        isLoadingBoards = false
                        print("ERROR: pinterestAccessToken is empty!")
                    }
                    return
                }

                print("=== Fetching Pinterest Boards ===")
                print("userId: \(flow.userId)")
                print("accessToken: \(flow.pinterestAccessToken.prefix(20))...")
                print("refreshToken: \(flow.pinterestRefreshToken.isEmpty ? "empty" : "present")")

                // Calculate token expiration times if needed
                let accessTokenExpiresAt: String?
                if flow.pinterestTokenExpiresIn > 0 {
                    let expiryDate = Date().addingTimeInterval(TimeInterval(flow.pinterestTokenExpiresIn))
                    accessTokenExpiresAt = ISO8601DateFormatter().string(from: expiryDate)
                } else {
                    accessTokenExpiresAt = nil
                }

                let boards = try await PinterestBoardsService.shared.fetchBoards(
                    userId: flow.userId,
                    accessToken: flow.pinterestAccessToken,
                    refreshToken: flow.pinterestRefreshToken.isEmpty ? nil : flow.pinterestRefreshToken,
                    expiresIn: flow.pinterestTokenExpiresIn > 0 ? flow.pinterestTokenExpiresIn : nil,
                    accessTokenExpiresAt: accessTokenExpiresAt,
                    refreshTokenExpiresIn: nil,
                    refreshTokenExpiresAt: nil
                )

                await MainActor.run {
                    flow.pinterestBoards = boards
                    isLoadingBoards = false
                    print("Loaded \(boards.count) boards")
                }
            } catch let error as PinterestBoardsError {
                await MainActor.run {
                    switch error {
                    case .invalidURL:
                        loadError = "Invalid API endpoint"
                    case .invalidResponse:
                        loadError = "Invalid response from server"
                    case .serverError(let message):
                        loadError = "Server error: \(message)"
                    case .networkError(let err):
                        loadError = "Network error: \(err.localizedDescription)"
                    }
                    isLoadingBoards = false
                }
            } catch {
                await MainActor.run {
                    loadError = "Failed to load boards: \(error.localizedDescription)"
                    isLoadingBoards = false
                }
            }
        }
    }

    private func toggleBoard(_ board: PinterestBoard) {
        if flow.selectedPinterestBoards.contains(board.id) {
            flow.selectedPinterestBoards.remove(board.id)
            print("Deselected board: \(board.name)")
        } else {
            flow.selectedPinterestBoards.insert(board.id)
            print("Selected board: \(board.name)")
        }
        print("Total selected boards: \(flow.selectedPinterestBoards.count)")
    }

    private func continueWithSelectedBoards() {
        let selectedBoardNames = flow.pinterestBoards
            .filter { flow.selectedPinterestBoards.contains($0.id) }
            .map { $0.name }

        print("=== Continuing with selected boards ===")
        print("Board IDs: \(flow.selectedPinterestBoards)")
        print("Board names: \(selectedBoardNames)")

        // TODO: Send selected boards to backend for processing

        if flow.isEditingPreferences {
            flow.isEditingPreferences = false
            flow.step = .feed
        } else {
            flow.step = .styleProfile
        }
    }
}

// MARK: - Outfit Upload

struct OutfitUploadScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isScanning: Bool = false

    var body: some View {
        OnboardingShell(
            title: "Upload outfit pics",
            subtitle: "Add 5–30 photos of outfits or pieces you love. We’ll find similar secondhand items.",
            showBack: true,
            backAction: { flow.step = .personalizationChoice }
        ) {
            VStack(spacing: 18) {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 30,
                    matching: .images
                ) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add from camera roll")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text("Multi-select looks, mirror selfies, inspo pics, and more.")
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "plus")
                    }
                    .foregroundColor(.black)
                    .padding(14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .onChange(of: selectedItems) { newValue in
                    Task {
                        await loadImages(from: newValue)
                    }
                }

                if !selectedImages.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .frame(height: 110)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.black.opacity(0.7))
                                Text("Drag & drop outfits here")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.black)
                                Text("Or tap above to multi-select from camera roll.")
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                        )
                }

                if selectedImages.count < 5 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Add at least 5 looks for best results.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.black)
                }

                Button {
                    startScan()
                } label: {
                    HStack(spacing: 8) {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isScanning ? "Scanning your looks…" : "Scan looks")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedImages.isEmpty || isScanning)

                Text("We only analyze the images. Nothing is shared or posted anywhere.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
            }
        }
    }

    private func startScan() {
        isScanning = true
        flow.uploadedImageCount = selectedImages.count

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            self.isScanning = false
            if self.flow.isEditingPreferences {
                self.flow.isEditingPreferences = false
                self.flow.step = .feed
            } else {
                self.flow.step = .styleProfile
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        selectedImages.removeAll()
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }
}

// MARK: - Style / Size Profile

struct StyleProfileScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var searchText: String = ""

    var filteredBrands: [String] {
        if searchText.isEmpty {
            return availableBrands
        }
        return availableBrands.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        OnboardingShell(
            title: "Tell us your brand preferences",
            subtitle: "Help us understand which brands resonate with your style so we can curate the perfect secondhand finds for you.",
            showBack: true,
            backAction: {
                if flow.prefersUpload {
                    flow.step = .uploadOutfits
                } else if flow.prefersPinterest {
                    flow.step = .selectPinterestBoard
                } else {
                    flow.step = .personalizationChoice
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.black.opacity(0.4))
                        .font(.system(size: 14))

                    TextField("Search brands...", text: $searchText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.black)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )

                // Selected brands count
                if !flow.selectedBrands.isEmpty {
                    Text("\(flow.selectedBrands.count) brand\(flow.selectedBrands.count == 1 ? "" : "s") selected")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.6))
                }

                // Brand list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredBrands, id: \.self) { brand in
                            BrandRow(
                                brand: brand,
                                isSelected: flow.selectedBrands.contains(brand),
                                onToggle: {
                                    if flow.selectedBrands.contains(brand) {
                                        flow.selectedBrands.remove(brand)
                                    } else {
                                        flow.selectedBrands.insert(brand)
                                    }
                                }
                            )
                        }
                    }
                }

                Button {
                    flow.step = .sizingProfile
                } label: {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 10)
            }
        }
    }
}

struct BrandRow: View {
    let brand: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(brand)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 18))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.black.opacity(0.2))
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Color.black.opacity(0.03) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.black.opacity(0.4) : Color.black.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

// MARK: - Sizing Profile

struct SizingProfileScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showValidationError = false

    private var hasAtLeastOneSize: Bool {
        if flow.sizingGender == .mens {
            return !flow.mensSizes.tops.isEmpty ||
                   !flow.mensSizes.bottoms.isEmpty ||
                   !flow.mensSizes.outerwear.isEmpty ||
                   !flow.mensSizes.footwear.isEmpty ||
                   !flow.mensSizes.tailoring.isEmpty ||
                   !flow.mensSizes.accessories.isEmpty
        } else {
            return !flow.womensSizes.tops.isEmpty ||
                   !flow.womensSizes.bottoms.isEmpty ||
                   !flow.womensSizes.outerwear.isEmpty ||
                   !flow.womensSizes.dresses.isEmpty
        }
    }

    var body: some View {
        OnboardingShell(
            title: "Your sizing",
            subtitle: "Help us find pieces that actually fit.",
            showBack: true,
            backAction: { flow.step = .styleProfile }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader("Sizing") {
                    Text("Choose the sizing you shop in most often.")
                }

                HStack(spacing: 10) {
                    ForEach(SizingGender.allCases, id: \.self) { gender in
                        Button {
                            flow.sizingGender = gender
                        } label: {
                            Text(gender.rawValue)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(gender == flow.sizingGender ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    gender == flow.sizingGender ? Color.black : Color.white
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                    }
                }

                if flow.sizingGender == .mens {
                    SizeGridMens(mens: $flow.mensSizes)
                        .onChange(of: flow.mensSizes.tops) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.bottoms) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.outerwear) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.footwear) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.tailoring) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.accessories) { _ in showValidationError = false }
                } else {
                    SizeGridWomens(womens: $flow.womensSizes)
                        .onChange(of: flow.womensSizes.tops) { _ in showValidationError = false }
                        .onChange(of: flow.womensSizes.bottoms) { _ in showValidationError = false }
                        .onChange(of: flow.womensSizes.outerwear) { _ in showValidationError = false }
                        .onChange(of: flow.womensSizes.dresses) { _ in showValidationError = false }
                }

                if showValidationError {
                    Text("Please select at least one size")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                if let error = saveError {
                    Text(error)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    if hasAtLeastOneSize {
                        saveProfileAndContinue()
                    } else {
                        showValidationError = true
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSaving)
                .padding(.top, 10)
            }
        }
    }

    private func saveProfileAndContinue() {
        isSaving = true
        saveError = nil

        Task {
            do {
                // Convert profile photo to data if available
                let photoData = flow.profilePhoto?.jpegData(compressionQuality: 0.7)

                try await ProfileService.shared.saveProfile(
                    userId: flow.userId,
                    firstName: flow.firstName,
                    username: flow.username,
                    profilePhotoData: photoData,
                    selectedPinterestBoards: flow.selectedPinterestBoards,
                    selectedBrands: flow.selectedBrands,
                    sizingGender: flow.sizingGender,
                    mensSizes: flow.mensSizes,
                    womensSizes: flow.womensSizes,
                    onboardingComplete: true
                )

                await MainActor.run {
                    // Cache profile photo for instant loading
                    if let photo = flow.profilePhoto {
                        ImageCache.shared.saveImage(photo, forKey: "profile_\(flow.userId)")
                    }
                    // Cache onboarding complete status
                    AuthManager.shared.setOnboardingComplete(true)
                    isSaving = false
                    flow.step = .vibeLoading
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Failed to save profile. Please try again."
                    print("Profile save error: \(error)")
                }
            }
        }
    }
}

// MARK: - Vibe Loading

struct VibeLoadingScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var progress: Double = 0.2

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Your vibe loading…")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)

                Text("Analyzing brands, fabrics, colors, and silhouettes to build your thrift brain.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 10) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)

                Text(randomLoadingCaption)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
            }

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            animateAndComplete()
        }
    }

    private var randomLoadingCaption: String {
        if flow.connectedPinterest {
            return "Reading your boards for color stories and repeat themes…"
        } else if flow.uploadedImageCount >= 5 {
            return "Scanning outfit shapes, textures, and recurring pieces…"
        } else {
            return "Combining your style + size profile into a curated thrift feed…"
        }
    }

    private func animateAndComplete() {
        progress = 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            progress = 0.6
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                progress = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    flow.step = .feed
                }
            }
        }
    }
}

// MARK: - Board Preview Grid

struct BoardPreviewGrid: View {
    let board: PinterestBoard

    var body: some View {
        let pinImages = board.pinImages.prefix(4)

        if pinImages.isEmpty {
            // Fallback placeholder if no images
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.05))
                .overlay(
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(.black.opacity(0.4))
                        .font(.system(size: 18))
                )
        } else {
            // 2x2 grid of pin images
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    if pinImages.count > 0 {
                        AsyncImage(url: URL(string: pinImages[0])) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.black.opacity(0.05)
                        }
                        .frame(width: 29, height: 29)
                        .clipped()
                    }

                    if pinImages.count > 1 {
                        AsyncImage(url: URL(string: pinImages[1])) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.black.opacity(0.05)
                        }
                        .frame(width: 29, height: 29)
                        .clipped()
                    } else {
                        Color.black.opacity(0.05)
                            .frame(width: 29, height: 29)
                    }
                }

                HStack(spacing: 2) {
                    if pinImages.count > 2 {
                        AsyncImage(url: URL(string: pinImages[2])) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.black.opacity(0.05)
                        }
                        .frame(width: 29, height: 29)
                        .clipped()
                    } else {
                        Color.black.opacity(0.05)
                            .frame(width: 29, height: 29)
                    }

                    if pinImages.count > 3 {
                        AsyncImage(url: URL(string: pinImages[3])) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.black.opacity(0.05)
                        }
                        .frame(width: 29, height: 29)
                        .clipped()
                    } else {
                        Color.black.opacity(0.05)
                            .frame(width: 29, height: 29)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

// MARK: - Edit Profile

struct EditProfileScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var firstName: String = ""
    @State private var username: String = ""
    @State private var selectedPhoto: UIImage?
    @State private var profilePhotoURL: String?
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var isSaving = false

    var body: some View {
        OnboardingShell(
            title: "Edit Profile",
            subtitle: "Update your profile information and preferences.",
            showBack: true,
            backAction: { flow.step = .feed }
        ) {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    Text("Loading profile...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 24) {
                    // Profile photo section
                    VStack(spacing: 12) {
                        if let photo = selectedPhoto {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                        } else if let existingPhoto = flow.profilePhoto {
                            Image(uiImage: existingPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                        } else if let photoURL = profilePhotoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(Color.black.opacity(0.05))
                                    .overlay(
                                        ProgressView()
                                    )
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                        } else {
                            Circle()
                                .fill(Color.black.opacity(0.05))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.black.opacity(0.3))
                                )
                        }

                    HStack(spacing: 12) {
                        Button {
                            imageSourceType = .photoLibrary
                            showingImagePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "photo")
                                    .font(.system(size: 12))
                                Text("Change Photo")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button {
                                imageSourceType = .camera
                                showingImagePicker = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 12))
                                    Text("Take Photo")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                }

                // Name and username fields
                VStack(spacing: 16) {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)
                        .modifier(OnboardingTextField())

                    HStack(spacing: 0) {
                        Text("@")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.4))
                            .padding(.leading, 14)

                        TextField("username", text: $username)
                            .autocapitalization(.none)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.trailing, 14)
                            .padding(.leading, 4)
                    }
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.4), lineWidth: 1)
                    )
                    .accentColor(.black)
                }

                // Large action buttons
                VStack(spacing: 12) {
                    Text("Update Preferences")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.black.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    Button {
                        saveProfileChanges()
                        flow.isEditingPreferences = true
                        flow.step = .personalizationChoice
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Update boards / reference photos")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                Text("Add Pinterest boards or upload new outfit photos")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.black)
                        .padding(16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        saveProfileChanges()
                        flow.step = .editBrands
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Update preferred brands")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                Text("Change the brands you love to shop")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "tag")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.black)
                        .padding(16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        saveProfileChanges()
                        flow.step = .editSizing
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Update sizing")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                Text("Adjust your size preferences")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "ruler")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.black)
                        .padding(16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                    Button {
                        saveAndReturn()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save & Return")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSaving)
                    .padding(.top, 8)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedPhoto, sourceType: imageSourceType)
        }
        .onAppear {
            fetchProfile()
        }
    }

    private func fetchProfile() {
        isLoading = true
        loadError = nil

        Task {
            do {
                if let profile = try await ProfileService.shared.fetchProfile(userId: flow.userId) {
                    await MainActor.run {
                        // Populate local state
                        firstName = profile.firstName ?? flow.firstName
                        username = profile.username ?? flow.username
                        profilePhotoURL = profile.profilePhoto

                        // Also update flow with fetched data
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

                        isLoading = false
                    }
                } else {
                    // No profile found, use local flow data
                    await MainActor.run {
                        firstName = flow.firstName
                        username = flow.username
                        selectedPhoto = flow.profilePhoto
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    // On error, fall back to local flow data
                    firstName = flow.firstName
                    username = flow.username
                    selectedPhoto = flow.profilePhoto
                    isLoading = false
                    print("Failed to fetch profile: \(error)")
                }
            }
        }
    }

    private func saveProfileChanges() {
        if !firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            flow.firstName = firstName
        }
        if !username.trimmingCharacters(in: .whitespaces).isEmpty {
            flow.username = username
        }
        if let photo = selectedPhoto {
            flow.profilePhoto = photo
        }
    }

    private func saveAndReturn() {
        saveProfileChanges()
        isSaving = true

        Task {
            do {
                let photoData = flow.profilePhoto?.jpegData(compressionQuality: 0.7)

                try await ProfileService.shared.saveProfile(
                    userId: flow.userId,
                    firstName: flow.firstName,
                    username: flow.username,
                    profilePhotoData: photoData,
                    selectedPinterestBoards: flow.selectedPinterestBoards,
                    selectedBrands: flow.selectedBrands,
                    sizingGender: flow.sizingGender,
                    mensSizes: flow.mensSizes,
                    womensSizes: flow.womensSizes
                )

                await MainActor.run {
                    // Cache profile photo for instant loading
                    if let photo = flow.profilePhoto {
                        ImageCache.shared.saveImage(photo, forKey: "profile_\(flow.userId)")
                    }
                    isSaving = false
                    flow.step = .feed
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    flow.step = .feed  // Still navigate even on error
                    print("Failed to save profile: \(error)")
                }
            }
        }
    }
}

// MARK: - Edit Brands

struct EditBrandsScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var searchText: String = ""
    @State private var isSaving = false

    var filteredBrands: [String] {
        if searchText.isEmpty {
            return availableBrands
        }
        return availableBrands.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        OnboardingShell(
            title: "Update preferred brands",
            subtitle: "Select the brands you love to shop.",
            showBack: true,
            backAction: { flow.step = .editProfile }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.black.opacity(0.4))
                        .font(.system(size: 14))

                    TextField("Search brands...", text: $searchText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.black)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )

                // Selected brands count
                if !flow.selectedBrands.isEmpty {
                    Text("\(flow.selectedBrands.count) brand\(flow.selectedBrands.count == 1 ? "" : "s") selected")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.6))
                }

                // Brand list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredBrands, id: \.self) { brand in
                            BrandRow(
                                brand: brand,
                                isSelected: flow.selectedBrands.contains(brand),
                                onToggle: {
                                    if flow.selectedBrands.contains(brand) {
                                        flow.selectedBrands.remove(brand)
                                    } else {
                                        flow.selectedBrands.insert(brand)
                                    }
                                }
                            )
                        }
                    }
                }

                Button {
                    saveAndReturn()
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save & Return")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSaving)
                .padding(.top, 10)
            }
        }
    }

    private func saveAndReturn() {
        isSaving = true

        Task {
            do {
                let photoData = flow.profilePhoto?.jpegData(compressionQuality: 0.7)

                try await ProfileService.shared.saveProfile(
                    userId: flow.userId,
                    firstName: flow.firstName,
                    username: flow.username,
                    profilePhotoData: photoData,
                    selectedPinterestBoards: flow.selectedPinterestBoards,
                    selectedBrands: flow.selectedBrands,
                    sizingGender: flow.sizingGender,
                    mensSizes: flow.mensSizes,
                    womensSizes: flow.womensSizes
                )

                await MainActor.run {
                    isSaving = false
                    flow.step = .feed
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    flow.step = .feed  // Still navigate even on error
                    print("Failed to save profile: \(error)")
                }
            }
        }
    }
}

// MARK: - Edit Sizing

struct EditSizingScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var isSaving = false
    @State private var showValidationError = false

    private var hasAtLeastOneSize: Bool {
        if flow.sizingGender == .mens {
            return !flow.mensSizes.tops.isEmpty ||
                   !flow.mensSizes.bottoms.isEmpty ||
                   !flow.mensSizes.outerwear.isEmpty ||
                   !flow.mensSizes.footwear.isEmpty ||
                   !flow.mensSizes.tailoring.isEmpty ||
                   !flow.mensSizes.accessories.isEmpty
        } else {
            return !flow.womensSizes.tops.isEmpty ||
                   !flow.womensSizes.bottoms.isEmpty ||
                   !flow.womensSizes.outerwear.isEmpty ||
                   !flow.womensSizes.dresses.isEmpty
        }
    }

    var body: some View {
        OnboardingShell(
            title: "Update sizing",
            subtitle: "Adjust your size preferences.",
            showBack: true,
            backAction: { flow.step = .editProfile }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader("Sizing") {
                    Text("Choose the sizing you shop in most often.")
                }

                HStack(spacing: 10) {
                    ForEach(SizingGender.allCases, id: \.self) { gender in
                        Button {
                            flow.sizingGender = gender
                        } label: {
                            Text(gender.rawValue)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(gender == flow.sizingGender ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    gender == flow.sizingGender ? Color.black : Color.white
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                    }
                }

                if flow.sizingGender == .mens {
                    SizeGridMens(mens: $flow.mensSizes)
                        .onChange(of: flow.mensSizes.tops) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.bottoms) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.outerwear) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.footwear) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.tailoring) { _ in showValidationError = false }
                        .onChange(of: flow.mensSizes.accessories) { _ in showValidationError = false }
                } else {
                    SizeGridWomens(womens: $flow.womensSizes)
                        .onChange(of: flow.womensSizes.tops) { _ in showValidationError = false }
                        .onChange(of: flow.womensSizes.bottoms) { _ in showValidationError = false }
                        .onChange(of: flow.womensSizes.outerwear) { _ in showValidationError = false }
                        .onChange(of: flow.womensSizes.dresses) { _ in showValidationError = false }
                }

                if showValidationError {
                    Text("Please select at least one size")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    if hasAtLeastOneSize {
                        saveAndReturn()
                    } else {
                        showValidationError = true
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save & Return")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSaving)
                .padding(.top, 10)
            }
        }
    }

    private func saveAndReturn() {
        isSaving = true

        Task {
            do {
                let photoData = flow.profilePhoto?.jpegData(compressionQuality: 0.7)

                try await ProfileService.shared.saveProfile(
                    userId: flow.userId,
                    firstName: flow.firstName,
                    username: flow.username,
                    profilePhotoData: photoData,
                    selectedPinterestBoards: flow.selectedPinterestBoards,
                    selectedBrands: flow.selectedBrands,
                    sizingGender: flow.sizingGender,
                    mensSizes: flow.mensSizes,
                    womensSizes: flow.womensSizes
                )

                await MainActor.run {
                    isSaving = false
                    flow.step = .feed
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    flow.step = .feed  // Still navigate even on error
                    print("Failed to save profile: \(error)")
                }
            }
        }
    }
}
