//
//  OnboardingScreens.swift
//  Sourced
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

// MARK: - Welcome

struct WelcomeScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var appleSignInCoordinator: SignInWithAppleCoordinator?

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
                if flow.isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .padding(.bottom, 8)
                }

                if let error = flow.authError {
                    Text(error)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // PRIMARY: Sign in with Apple
                Button {
                    handleSignInWithApple()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(height: 48)
                .disabled(flow.isAuthenticating)

                // Google
                Button {
                    handleSignInWithGoogle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "g.circle")
                        Text("Continue with Google")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(flow.isAuthenticating)

                // Email
                Button {
                    flow.authError = nil
                    flow.step = .emailAuth
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                        Text("Continue with Email")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(flow.isAuthenticating)

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

    private func handleSignInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let coordinator = SignInWithAppleCoordinator(flow: flow)
        appleSignInCoordinator = coordinator

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator
        controller.performRequests()
    }

    private func handleSignInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No root view controller found")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                // Check if user cancelled (error code -5 is cancellation)
                let nsError = error as NSError
                if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                    print("Google Sign-In cancelled by user")
                    // Don't show error for cancellation
                    return
                }

                print("Google Sign-In error: \(error.localizedDescription)")
                flow.authError = "Google Sign-In failed: \(error.localizedDescription)"
                return
            }

            guard let user = result?.user,
                  let profile = user.profile else {
                print("No user profile found")
                flow.authError = "No user profile found"
                return
            }

            // Store Google user info
            flow.authMethod = .google
            flow.googleUserID = user.userID ?? ""
            flow.email = profile.email
            flow.firstName = profile.givenName ?? ""

            // Authenticate with backend
            Task {
                await flow.authenticate()
            }
        }
    }
}

class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let flow: OnboardingFlow

    init(flow: OnboardingFlow) {
        self.flow = flow
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            flow.authMethod = .apple
            flow.appleUserID = appleIDCredential.user
            flow.email = appleIDCredential.email ?? ""

            if let givenName = appleIDCredential.fullName?.givenName {
                flow.firstName = givenName
            }

            // Authenticate with backend
            Task {
                await flow.authenticate()
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Check if user cancelled
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            print("Sign in with Apple cancelled by user")
            // Don't show error for cancellation
            return
        }

        print("Sign in with Apple error: \(error.localizedDescription)")
        flow.authError = "Apple Sign-In failed: \(error.localizedDescription)"
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
                    .disabled(flow.isAuthenticating)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .modifier(OnboardingTextField())
                    .disabled(flow.isAuthenticating)

                if let error = flow.authError {
                    Text(error)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button {
                        Task {
                            flow.authMethod = .email
                            flow.email = email
                            flow.password = password
                            await flow.authenticate()
                        }
                    } label: {
                        if flow.isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty || flow.isAuthenticating)
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
    @State private var selectedPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showError: Bool = false

    private var isFirstNameEmpty: Bool {
        firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isUsernameEmpty: Bool {
        username.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        OnboardingShell(
            title: "Who's thrifting?",
            subtitle: "We'll use this to personalize your experience. You can change it later.",
            showBack: true,
            backAction: { flow.step = .welcome }
        ) {
            VStack(spacing: 18) {
                TextField("First name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .modifier(OnboardingTextField())
                    .onChange(of: firstName) { _ in
                        if showError { showError = false }
                    }

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
                .onChange(of: username) { _ in
                    if showError { showError = false }
                }

                // Profile photo section
                VStack(spacing: 12) {
                    if let photo = selectedPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    } else {
                        Circle()
                            .fill(Color.black.opacity(0.05))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
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
                                Text("Upload")
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

                    Text("Optional")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    if showError {
                        Text("Please enter your first name and username")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        if isFirstNameEmpty || isUsernameEmpty {
                            showError = true
                        } else {
                            flow.firstName = firstName
                            flow.username = username
                            flow.profilePhoto = selectedPhoto
                            flow.step = .personalizationChoice
                        }
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.top, 10)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedPhoto, sourceType: imageSourceType)
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
            backAction: {
                if flow.isEditingPreferences {
                    flow.isEditingPreferences = false
                    flow.step = .editProfile
                } else {
                    flow.step = .basicProfile
                }
            }
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
            }

            Text("We only analyze images. We never publish or edit your boards or photos.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(.black.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
