//
//  SourcedApp.swift
//  Sourced
//
//  Created by Ryan Kemmer on 11/17/25.
//

import SwiftUI

@main
struct SourcedApp: App {
    @StateObject private var flow = OnboardingFlow()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(flow)
        }
    }
}
