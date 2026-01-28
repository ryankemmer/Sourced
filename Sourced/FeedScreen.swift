//
//  FeedScreen.swift
//  Sourced
//

import SwiftUI
import Combine

// MARK: - Listings API Models

struct ListingItem: Codable, Identifiable {
    let url: String
    let position: Int?
    let item_type: String?
    let description: String?
    let size: String?
    let sizes_available: [String]?
    let color: String?
    let title: String?
    let image_url: String?
    let price: String?
    let currency: String?

    var id: String { url }

    var brand: String? {
        guard let title = title else { return nil }
        let words = title.components(separatedBy: " ")
        if words.count >= 2 {
            let firstTwo = "\(words[0]) \(words[1])"
            let twoWordBrands = ["Banana Republic", "Calvin Klein", "Victoria Beckham", "rag bone", "rag & bone"]
            if twoWordBrands.contains(where: { firstTwo.lowercased().contains($0.lowercased()) }) {
                return firstTwo
            }
        }
        return words.first
    }

    var formattedPrice: String {
        guard let price = price else { return "" }
        let currency = currency ?? "USD"
        if let priceDouble = Double(price) {
            return currency == "USD" ? "$\(Int(priceDouble))" : "\(Int(priceDouble)) \(currency)"
        }
        return price
    }
}

struct ItemTypeGroup: Codable, Identifiable {
    let item_type: String
    let query: String?
    let notes: String?
    let listings: [ListingItem]
    let listing_count: Int?

    var id: String { item_type }
}

struct PinListingsData: Codable {
    let pin_id: String
    let s3_image_key: String?
    let s3_image_url: String?
    let items: [ItemTypeGroup]
}

struct PinListingsResponse: Codable {
    let message: String?
    let pin_id: String
    let s3_image_key: String?
    let s3_image_url: String?
    let items: [ItemTypeGroup]
}

// MARK: - Profile Image View

struct ProfileImageView: View {
    let image: UIImage?

    var body: some View {
        if let profileImage = image {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.black.opacity(0.3))
        }
    }
}

// MARK: - Personalized Feed Screen

struct PersonalizedFeedScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var showLogoutConfirmation = false
    @State private var profileImageRefresh = UUID()
    @State private var isLoading = false
    @State private var selectedImage: FeedImage?
    @State private var selectedImageUIImage: UIImage?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("For you")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    Spacer()

                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        ProfileImageView(image: flow.profilePhoto)
                            .id(profileImageRefresh)
                    }
                    .onAppear {
                        profileImageRefresh = UUID()
                    }
                    .confirmationDialog("Account", isPresented: $showLogoutConfirmation) {
                        Button("Edit Profile") {
                            flow.step = .editProfile
                        }
                        Button("Log Out", role: .destructive) {
                            flow.logout()
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                Text("Based on your vibe, sizing, and favorite brands.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.65))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                if flow.feedImages.isEmpty {
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    } else {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 48))
                                .foregroundColor(.black.opacity(0.3))
                            Text("No images yet")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.6))
                            Text("Connect Pinterest or upload outfit photos to see your personalized feed.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.black.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    }
                } else {
                    GeometryReader { geometry in
                        let columnWidth = (geometry.size.width - 24) / 2
                        ScrollView {
                            MasonryGrid(
                                images: flow.feedImages,
                                columnWidth: columnWidth,
                                onImageTap: { image, uiImage in
                                    selectedImage = image
                                    selectedImageUIImage = uiImage
                                }
                            )
                            .padding(.horizontal, 8)
                            .padding(.bottom, 80)
                        }
                        .refreshable {
                            await refreshFeed()
                        }
                    }
                }
            }
            .background(Color.white.ignoresSafeArea())
            .onReceive(flow.$profilePhoto) { _ in
                profileImageRefresh = UUID()
            }
            .task {
                await refreshFeed()
            }
        }
        .sheet(item: $selectedImage) { image in
            ImageDetailView(
                image: image,
                preloadedImage: selectedImageUIImage,
                userId: flow.userId
            )
        }
    }

    private func refreshFeed() async {
        guard !flow.userId.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if let profile = try await ProfileService.shared.fetchProfile(userId: flow.userId) {
                await MainActor.run {
                    if let images = profile.images {
                        print("=== Feed Images Received ===")
                        print("Count: \(images.count)")
                        flow.feedImages = images
                    } else {
                        print("No images in profile response")
                    }
                }
            }
        } catch {
            print("Error refreshing feed: \(error)")
        }
    }
}

// MARK: - Image Detail View

struct ImageDetailView: View {
    let image: FeedImage
    let preloadedImage: UIImage?
    let userId: String

    @Environment(\.dismiss) var dismiss
    @State private var listings: [ItemTypeGroup] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if let uiImage = preloadedImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 300)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Finding similar items...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding(.top, 40)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                    } else if listings.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.black.opacity(0.3))
                            Text("No listings found for this image yet.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 24) {
                            ForEach(listings) { itemGroup in
                                ItemTypeSection(itemGroup: itemGroup)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Shop the Look")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
            }
        }
        .task {
            await fetchListings()
        }
    }

    private func fetchListings() async {
        var components = URLComponents(string: "https://k2nebib668.execute-api.us-east-1.amazonaws.com/prod/listings")
        components?.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "pinId", value: image.id)
        ]

        guard let url = components?.url else {
            await MainActor.run {
                errorMessage = "Invalid URL"
                isLoading = false
            }
            return
        }

        print("Fetching listings from: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse else {
                await MainActor.run {
                    errorMessage = "Invalid server response"
                    isLoading = false
                }
                return
            }

            print("Listings response status: \(http.statusCode)")

            if let responseString = String(data: data, encoding: .utf8) {
                print("Listings response: \(responseString.prefix(800))")
            }

            guard (200...299).contains(http.statusCode) else {
                await MainActor.run {
                    errorMessage = "Server error (\(http.statusCode))"
                    isLoading = false
                }
                return
            }

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(PinListingsResponse.self, from: data)

            await MainActor.run {
                listings = decoded.items
                isLoading = false
                errorMessage = nil
            }
        } catch {
            print("Error fetching listings: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load listings"
                isLoading = false
            }
        }
    }
}

// MARK: - Item Type Section

struct ItemTypeSection: View {
    let itemGroup: ItemTypeGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(itemGroup.item_type)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)

                if let notes = itemGroup.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(itemGroup.listings) { listing in
                        ListingCard(listing: listing)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Listing Card

struct ListingCard: View {
    let listing: ListingItem
    @State private var loadedImage: UIImage?

    var body: some View {
        Link(destination: URL(string: listing.url) ?? URL(string: "https://poshmark.com")!) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.06))

                    if let uiImage = loadedImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .frame(width: 150, height: 180)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    if let brand = listing.brand {
                        Text(brand.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.black.opacity(0.5))
                            .lineLimit(1)
                    }

                    Text(listing.title ?? "Item")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Text(listing.formattedPrice)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)

                        if let size = listing.size {
                            Text("Size \(size)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                }
                .frame(width: 150, alignment: .leading)
            }
        }
        .onAppear {
            loadListingImage()
        }
    }

    private func loadListingImage() {
        guard let imageUrl = listing.image_url, let url = URL(string: imageUrl) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    loadedImage = image
                }
            }
        }.resume()
    }
}

// MARK: - Masonry Grid

struct MasonryGrid: View {
    let images: [FeedImage]
    let columnWidth: CGFloat
    let columns = 2
    let spacing: CGFloat = 8
    var onImageTap: ((FeedImage, UIImage?) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(imagesForColumn(columnIndex), id: \.id) { image in
                        FeedImageCard(image: image, width: columnWidth, onTap: onImageTap)
                    }
                }
            }
        }
    }

    private func imagesForColumn(_ column: Int) -> [FeedImage] {
        images.enumerated().compactMap { index, image in
            index % columns == column ? image : nil
        }
    }
}

// MARK: - Feed Image Card

struct FeedImageCard: View {
    let image: FeedImage
    let width: CGFloat
    var onTap: ((FeedImage, UIImage?) -> Void)?

    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false

    private var heightMultiplier: CGFloat {
        let hash = abs(image.id.hashValue)
        let options: [CGFloat] = [1.0, 1.2, 1.4, 1.6, 1.8]
        return options[hash % options.count]
    }

    private var cardHeight: CGFloat {
        width * heightMultiplier
    }

    var body: some View {
        Group {
            if let uiImage = loadedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: cardHeight)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onTapGesture {
                        onTap?(image, uiImage)
                    }
            } else if isLoading {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.06))
                    .frame(width: width, height: cardHeight)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.06))
                    .frame(width: width, height: cardHeight)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.black.opacity(0.3))
                    )
                    .onTapGesture {
                        onTap?(image, nil)
                    }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = URL(string: image.url) else {
            print("Invalid URL: \(image.url)")
            isLoading = false
            loadFailed = true
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    print("Image load error: \(error.localizedDescription)")
                    loadFailed = true
                    return
                }

                if let data = data, let uiImage = UIImage(data: data) {
                    loadedImage = uiImage
                } else {
                    loadFailed = true
                }
            }
        }.resume()
    }
}

