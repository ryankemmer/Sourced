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

    private let userDefaults = UserDefaults.standard
    private let userIdKey = "userId"

    private init() {
        loadAuthState()
    }

    // Load saved auth state on app launch
    func loadAuthState() {
        currentUserId = userDefaults.string(forKey: userIdKey)
        isAuthenticated = currentUserId != nil
    }

    // Save auth state after successful login
    func saveAuthState(userId: String) {
        userDefaults.set(userId, forKey: userIdKey)
        self.currentUserId = userId
        self.isAuthenticated = true
    }

    // Clear auth state on logout
    func logout() {
        userDefaults.removeObject(forKey: userIdKey)
        currentUserId = nil
        isAuthenticated = false
    }
}
