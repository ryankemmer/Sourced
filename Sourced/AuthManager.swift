//
//  AuthManager.swift
//  Sourced
//
//  Manages authentication state persistence
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated: Bool = false
    @Published var currentUserId: String?
    @Published var onboardingComplete: Bool = false

    private let userDefaults = UserDefaults.standard
    private let userIdKey = "userId"
    private let onboardingCompleteKey = "onboardingComplete"

    private init() {
        loadAuthState()
    }

    // Load saved auth state on app launch
    func loadAuthState() {
        currentUserId = userDefaults.string(forKey: userIdKey)
        isAuthenticated = currentUserId != nil
        onboardingComplete = userDefaults.bool(forKey: onboardingCompleteKey)
    }

    // Save auth state after successful login
    func saveAuthState(userId: String) {
        userDefaults.set(userId, forKey: userIdKey)
        self.currentUserId = userId
        self.isAuthenticated = true
    }

    // Mark onboarding as complete
    func setOnboardingComplete(_ complete: Bool) {
        userDefaults.set(complete, forKey: onboardingCompleteKey)
        self.onboardingComplete = complete
    }

    // Clear auth state on logout
    func logout() {
        userDefaults.removeObject(forKey: userIdKey)
        userDefaults.removeObject(forKey: onboardingCompleteKey)
        currentUserId = nil
        isAuthenticated = false
        onboardingComplete = false
    }
}
