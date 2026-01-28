//
//  ProfileService.swift
//  Sourced
//
//  Service for saving and fetching user profile data
//

import Foundation
import UIKit

enum ProfileError: Error {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case networkError(Error)
    case encodingError
}

struct FeedImage: Codable, Identifiable {
    let id: String
    let s3Path: String?
    let url: String
}

struct ProfileData: Codable {
    let userId: String
    var email: String?
    var firstName: String?
    var username: String?
    var profilePhoto: String?
    var selectedPinterestBoards: [String]?
    var selectedBrands: [String]?
    var sizingGender: String?
    var mensSizes: MensSizesData?
    var womensSizes: WomensSizesData?
    var onboardingComplete: Bool?
    var images: [FeedImage]?
}

struct MensSizesData: Codable {
    var tops: String?
    var bottoms: String?
    var outerwear: String?
    var footwear: String?
    var tailoring: String?
    var accessories: String?
}

struct WomensSizesData: Codable {
    var tops: String?
    var bottoms: String?
    var outerwear: String?
    var dresses: String?
}

struct ProfileResponse: Codable {
    let message: String?
    let user: ProfileData?
}

class ProfileService {
    static let shared = ProfileService()
    private let baseURL = "https://k2nebib668.execute-api.us-east-1.amazonaws.com/prod/profile"

    private init() {}

    // MARK: - Save Profile

    func saveProfile(
        userId: String,
        firstName: String?,
        username: String?,
        profilePhotoData: Data?,
        selectedPinterestBoards: Set<String>,
        selectedBrands: Set<String>,
        sizingGender: SizingGender,
        mensSizes: MensSizes,
        womensSizes: WomensSizes,
        onboardingComplete: Bool? = nil
    ) async throws {
        guard let url = URL(string: baseURL) else {
            throw ProfileError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build the profile data
        var profileData: [String: Any] = [
            "userId": userId
        ]

        if let firstName = firstName, !firstName.isEmpty {
            profileData["firstName"] = firstName
        }

        if let username = username, !username.isEmpty {
            profileData["username"] = username
        }

        // Convert profile photo to base64 if available
        if let photoData = profilePhotoData {
            let base64String = photoData.base64EncodedString()
            profileData["profilePhoto"] = "data:image/jpeg;base64,\(base64String)"
        }

        if !selectedPinterestBoards.isEmpty {
            profileData["selectedPinterestBoards"] = Array(selectedPinterestBoards)
        }

        if !selectedBrands.isEmpty {
            profileData["selectedBrands"] = Array(selectedBrands)
        }

        // Save enum case name directly (not display string)
        profileData["sizingGender"] = sizingGender == .mens ? "mens" : "womens"

        profileData["mensSizes"] = [
            "tops": mensSizes.tops,
            "bottoms": mensSizes.bottoms,
            "outerwear": mensSizes.outerwear,
            "footwear": mensSizes.footwear,
            "tailoring": mensSizes.tailoring,
            "accessories": mensSizes.accessories
        ]

        profileData["womensSizes"] = [
            "tops": womensSizes.tops,
            "bottoms": womensSizes.bottoms,
            "outerwear": womensSizes.outerwear,
            "dresses": womensSizes.dresses
        ]

        if let onboardingComplete = onboardingComplete {
            profileData["onboardingComplete"] = onboardingComplete
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: profileData)
        } catch {
            throw ProfileError.encodingError
        }

        print("=== Saving Profile ===")
        print("userId: \(userId)")
        print("firstName: \(firstName ?? "nil")")
        print("username: \(username ?? "nil")")
        print("selectedBrands count: \(selectedBrands.count)")
        print("selectedPinterestBoards count: \(selectedPinterestBoards.count)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProfileError.invalidResponse
            }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("Profile saved successfully")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Profile save failed: \(errorMessage)")
                throw ProfileError.serverError(errorMessage)
            }
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.networkError(error)
        }
    }

    // MARK: - Fetch Profile

    func fetchProfile(userId: String) async throws -> ProfileData? {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw ProfileError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "userId", value: userId)
        ]

        guard let url = urlComponents.url else {
            throw ProfileError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("=== Fetching Profile ===")
        print("userId: \(userId)")
        print("URL: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProfileError.invalidResponse
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                // Try to decode the response
                let decoder = JSONDecoder()

                // First try to decode as ProfileResponse wrapper
                if let profileResponse = try? decoder.decode(ProfileResponse.self, from: data) {
                    print("Profile fetched successfully (wrapped)")
                    return profileResponse.user
                }

                // Try to decode directly as ProfileData
                if let profile = try? decoder.decode(ProfileData.self, from: data) {
                    print("Profile fetched successfully (direct)")
                    return profile
                }

                print("Could not decode profile response")
                return nil
            } else if httpResponse.statusCode == 404 {
                print("Profile not found")
                return nil
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Profile fetch failed: \(errorMessage)")
                throw ProfileError.serverError(errorMessage)
            }
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.networkError(error)
        }
    }

    // MARK: - Trigger Listings Finder

    func triggerListingsFinder(userId: String) async {
        let urlString = "https://p2g0jidnp9.execute-api.us-east-1.amazonaws.com/prod/listings-finder"

        guard let url = URL(string: urlString) else {
            print("Invalid listings finder URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["user_id": userId]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            print("=== Triggering Listings Finder ===")
            print("userId: \(userId)")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("Listings finder response status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
        } catch {
            print("Listings finder error: \(error)")
        }
    }
}
