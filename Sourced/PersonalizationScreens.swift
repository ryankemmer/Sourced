//
//  PersonalizationScreens.swift
//  Sourced
//

import SwiftUI
import PhotosUI

// MARK: - Pinterest OAuth (stubbed)

struct PinterestOAuthScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var isAuthorizing: Bool = false
    @State private var authError: String?

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

                if let authError {
                    Text(authError)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.red.opacity(0.9))
                }

                Button {
                    startPinterestOAuth()
                } label: {
                    HStack {
                        Image(systemName: "p.circle")
                        Text(isAuthorizing ? "Connecting…" : "Connect Pinterest")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isAuthorizing)

                Button {
                    flow.step = .styleProfile
                } label: {
                    Text("Skip for now")
                        .foregroundColor(.black.opacity(0.8))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                }
                .padding(.top, 4)

                Text("We only analyze images. We never publish or edit your boards.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.top, 8)
            }
        }
    }

    private func startPinterestOAuth() {
        isAuthorizing = true
        authError = nil

        // TODO: replace with real ASWebAuthenticationSession Pinterest OAuth
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isAuthorizing = false
            self.flow.connectedPinterest = true
            self.flow.step = .styleProfile
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

                Button {
                    flow.step = .styleProfile
                } label: {
                    Text("Skip and just set style profile")
                        .foregroundColor(.black.opacity(0.8))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                }
                .padding(.top, 4)

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
            self.flow.step = .styleProfile
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

    private let brandOptions = [
        "Levi’s", "Nike", "Zara", "COS", "Everlane", "Arket", "Vintage", "Designer"
    ]

    private let fabricOptions = [
        "Denim", "Cotton", "Linen", "Wool", "Leather", "Silk", "Fleece"
    ]

    private let aestheticOptions = [
        "Minimal", "Streetwear", "Y2K", "Vintage", "Clean classics", "Techwear", "Soft grunge"
    ]

    var body: some View {
        OnboardingShell(
            title: "Lock in your fit",
            subtitle: "We’ll match you with secondhand finds that actually fit and feel like you.",
            showBack: true,
            backAction: {
                if flow.prefersUpload {
                    flow.step = .uploadOutfits
                } else if flow.prefersPinterest {
                    flow.step = .pinterestOAuth
                } else {
                    flow.step = .personalizationChoice
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader("Favorite brands") {
                    Text("Think pieces you reach for over and over.")
                }
                WrapChips(options: brandOptions, selected: $flow.selectedBrands)

                SectionHeader("Fabrics you love") {
                    Text("We'll prioritize pieces in these materials.")
                }
                WrapChips(options: fabricOptions, selected: $flow.selectedFabrics)

                SectionHeader("Your aesthetic keywords") {
                    Text("We'll use this to style your feed and alerts.")
                }
                WrapChips(options: aestheticOptions, selected: $flow.selectedAesthetics)

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

// MARK: - Sizing Profile

struct SizingProfileScreen: View {
    @EnvironmentObject var flow: OnboardingFlow

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
                } else {
                    SizeGridWomens(womens: $flow.womensSizes)
                }

                Button {
                    flow.step = .vibeLoading
                } label: {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 10)
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
                    flow.step = .styleSummary
                }
            }
        }
    }
}

// MARK: - Style Summary

struct StyleSummaryScreen: View {
    @EnvironmentObject var flow: OnboardingFlow

    var body: some View {
        OnboardingShell(
            title: "Here’s what we picked up",
            subtitle: "We’ll use this to power your personalized thrift feed.",
            showBack: false
        ) {
            VStack(alignment: .leading, spacing: 18) {
                SummaryCard(
                    title: "Core style lanes",
                    items: Array(flow.selectedAesthetics.isEmpty
                                 ? ["Clean classics", "Modern vintage"]
                                 : flow.selectedAesthetics)
                )

                SummaryCard(
                    title: "Brands + labels to prioritize",
                    items: Array(flow.selectedBrands.isEmpty
                                 ? ["Premium denim", "Quality basics", "Under-the-radar designers"]
                                 : flow.selectedBrands)
                )

                SummaryCard(
                    title: "Fabrics & textures",
                    items: Array(flow.selectedFabrics.isEmpty
                                 ? ["Denim", "Cotton", "Wool"]
                                 : flow.selectedFabrics)
                )

                SummaryCard(
                    title: "Sizing snapshot",
                    items: sizingSnapshot
                )

                Button {
                    flow.goToFeed()
                } label: {
                    Text("Start thrifting")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 10)
            }
        }
    }

    private var sizingSnapshot: [String] {
        if flow.sizingGender == .mens {
            return [
                "Shirt: \(flow.mensSizes.shirt.ifEmpty("Not set"))",
                "Pants: \(flow.mensSizes.pants.ifEmpty("Not set"))",
                "Jacket: \(flow.mensSizes.jacket.ifEmpty("Not set"))",
                "Shoes: \(flow.mensSizes.shoes.ifEmpty("Not set"))"
            ]
        } else {
            return [
                "Shirt: \(flow.womensSizes.shirt.ifEmpty("Not set"))",
                "Pants: \(flow.womensSizes.pants.ifEmpty("Not set"))",
                "Jacket: \(flow.womensSizes.jacket.ifEmpty("Not set"))",
                "Sweaters: \(flow.womensSizes.sweaters.ifEmpty("Not set"))",
                "Shoes: \(flow.womensSizes.shoes.ifEmpty("Not set"))",
                "Handbags: \(flow.womensSizes.handbags.ifEmpty("Not set"))",
                "Dress: \(flow.womensSizes.dress.ifEmpty("Not set"))",
                "Skirt: \(flow.womensSizes.skirt.ifEmpty("Not set"))"
            ]
        }
    }
}

struct SummaryCard: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.black)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.black.opacity(0.8))
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
