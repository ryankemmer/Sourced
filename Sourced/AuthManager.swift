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
    @Published var authToken: String?

    private let userDefaults = UserDefaults.standard
    private let tokenKey = "authToken"
    private let userIdKey = "userId"

    private init() {
        loadAuthState()
    }

    // Load saved auth state on app launch
    func loadAuthState() {
        authToken = userDefaults.string(forKey: tokenKey)
        currentUserId = userDefaults.string(forKey: userIdKey)
        isAuthenticated = authToken != nil
    }

    // Save auth state after successful login
    func saveAuthState(token: String?, userId: String?) {
        if let token = token {
            userDefaults.set(token, forKey: tokenKey)
        }
        if let userId = userId {
            userDefaults.set(userId, forKey: userIdKey)
        }

        self.authToken = token
        self.currentUserId = userId
        self.isAuthenticated = token != nil
    }

    // Clear auth state on logout
    func logout() {
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: userIdKey)

        authToken = nil
        currentUserId = nil
        isAuthenticated = false
    }
}
