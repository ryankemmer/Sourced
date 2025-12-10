//
//  SourcedApp.swift
//  Sourced
//
//  Created by Ryan Kemmer on 11/17/25.
//

import SwiftUI
import GoogleSignIn

@main
struct SourcedApp: App {
    @StateObject private var flow = OnboardingFlow()

    init() {
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: Config.googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        // Register URL scheme
        if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
            print("Registered URL schemes: \(urlTypes)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(flow)
                .onOpenURL { url in
                    print("Received URL: \(url)")
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
