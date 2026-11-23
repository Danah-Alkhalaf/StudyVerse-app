//
//  WelcomeView.swift
//  StudyVerse
//
//  Branch: Welcome-View
//  Owner: Maira Zaman
//
//  First screen for logged-out users: logo, app name, tagline,
//  "Log In" and "Sign Up". It owns the NavigationStack for the auth screens.
//  No tab bar here (CLAUDE.md: navbar is not shown on login/sign-up screens).
//

import SwiftUI

enum AuthRoute: Hashable {
    case login(passwordJustUpdated: Bool = false)
    case signUp
    case forgotPassword
    case checkEmail(String)
    case tutorVerification
}

struct WelcomeView: View {
    /// Called after a successful log in or student sign up, so the app can
    /// switch to the main tabs.
    var onLoggedIn: (UserModel) -> Void = { _ in }

    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: AppTheme.spacing) {
                Spacer()

                AppLogo()
                    .padding(.bottom, 8)

                Text("StudyVerse")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("Learn, play and level up with your classmates.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: "Log In") { path.append(.login()) }
                    SecondaryButton(title: "Sign Up") { path.append(.signUp) }
                }
                .padding(.bottom, AppTheme.spacing)
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .studyverseBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .login(let passwordJustUpdated):
                    LoginView(passwordJustUpdated: passwordJustUpdated,
                              onLoggedIn: onLoggedIn,
                              onForgotPassword: { path.append(.forgotPassword) },
                              onSignUp: { path = [.signUp] })
                case .signUp:
                    SignUpView(onStudentSignedUp: onLoggedIn,
                               onTutorSignedUp: { _ in path = [.tutorVerification] },
                               onLogIn: { path = [.login()] })
                case .forgotPassword:
                    ForgotPasswordView(onLinkSent: { email in path.append(.checkEmail(email)) })
                case .checkEmail(let email):
                    CheckEmailView(email: email, onBackToLogIn: { path = [.login()] })
                case .tutorVerification:
                    // TODO: replace with TutorVerificationView (24 November task)
                    ComingSoonView(title: "Tutor Verification")
                }
            }
        }
    }
}

// MARK: - App logo

/// Placeholder logo built from SF Symbols (graduation cap inside a yellow
/// star) until the real alien logo image is added to Assets.
struct AppLogo: View {
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 140

    var body: some View {
        ZStack {
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(AppTheme.chipYellow)
                .overlay {
                    Image(systemName: "star")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(AppTheme.primary.opacity(0.25))
                }
            Image(systemName: "graduationcap.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(AppTheme.primary)
                .frame(width: size * 0.38)
                .offset(y: size * 0.04)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Temporary placeholder

/// Shown for screens that are not built yet. Delete once they exist.
private struct ComingSoonView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: title, showsBack: true, onBack: { dismiss() })
            Spacer()
            Text("Coming soon")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .studyverseBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    WelcomeView()
}
