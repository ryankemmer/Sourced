//
//  OnboardingScreens.swift
//  Sourced
//

import SwiftUI
import AuthenticationServices

// MARK: - Welcome

// OnboardingScreens.swift

import SwiftUI
import AuthenticationServices

struct WelcomeScreen: View {
    @EnvironmentObject var flow: OnboardingFlow

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                SourcedMonoLogo()
                    .padding(.bottom, 8)

                Text("The New Way to Thrift:")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)

                Text("Personalized, curated, effortless.\nSecondhand that actually looks like you.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 14) {
                // PRIMARY: Sign in with Apple
                Button {
                    // TODO: handle Sign in with Apple
                    flow.step = .basicProfile
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(height: 48)

                // Google
                Button {
                    // TODO: integrate GoogleSignIn
                    flow.step = .basicProfile
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "g.circle")
                        Text("Continue with Google")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                // Email
                Button {
                    flow.step = .emailAuth
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                        Text("Continue with Email")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                Text("We never post on your behalf. We only use your data to personalize your thrift experience.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - Email Auth

struct EmailAuthScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        OnboardingShell(
            title: "Sign in with Email",
            subtitle: "Enter your email and password to continue.",
            showBack: true,
            backAction: { flow.step = .welcome }
        ) {
            VStack(spacing: 18) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .modifier(OnboardingTextField())

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .modifier(OnboardingTextField())

                VStack(spacing: 12) {
                    Button {
                        flow.email = email
                        flow.password = password
                        flow.step = .basicProfile
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
                }
                .padding(.top, 10)
            }
        }
    }
}

// MARK: - Basic Profile

struct BasicProfileScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var firstName: String = ""
    @State private var username: String = ""

    var body: some View {
        OnboardingShell(
            title: "Who's thrifting?",
            subtitle: "We'll use this to personalize your experience. You can change it later.",
            showBack: true,
            backAction: { flow.step = .emailAuth }
        ) {
            VStack(spacing: 18) {
                TextField("First name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .modifier(OnboardingTextField())

                TextField("Username (optional)", text: $username)
                    .autocapitalization(.none)
                    .modifier(OnboardingTextField())

                VStack(spacing: 12) {
                    Button {
                        flow.firstName = firstName
                        flow.username = username
                        flow.step = .personalizationChoice
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.top, 10)
            }
        }
    }
}

// MARK: - Personalization Choice

struct PersonalizationChoiceScreen: View {
    @EnvironmentObject var flow: OnboardingFlow

    var body: some View {
        OnboardingShell(
            title: "How do you want to personalize?",
            subtitle: "Choose one to start. You can add more later.",
            showBack: true,
            backAction: { flow.step = .basicProfile }
        ) {
            VStack(spacing: 16) {
                Button {
                    flow.prefersPinterest = true
                    flow.prefersUpload = false
                    flow.step = .pinterestOAuth
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connect Pinterest")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Text("We'll read your boards to understand your vibe, not to post.")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "p.circle")
                    }
                    .foregroundColor(.black)
                    .padding(16)
                }
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    flow.prefersUpload = true
                    flow.prefersPinterest = false
                    flow.step = .uploadOutfits
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upload outfit pics")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Text("Drop in photos of looks you love. We'll find similar pieces.")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "photo.on.rectangle.angled")
                    }
                    .foregroundColor(.black)
                    .padding(16)
                }
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    flow.step = .styleProfile
                } label: {
                    VStack(spacing: 4) {
                        Text("Skip & browse basic feed")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Text("We'll still ask a few quick style + size questions.")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, 8)
            }

            Text("We only analyze images. We never publish or edit your boards or photos.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(.black.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
}
