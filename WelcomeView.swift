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
    case waitingApproval
}

struct WelcomeView: View {
    /// Called after a successful log in or student sign up, so the app can
    /// switch to the main tabs.
    var onLoggedIn: (UserModel) -> Void = { _ in }

    @State private var path: [AuthRoute]

    /// `startAt` opens a screen straight away, e.g. after a password change:
    /// WelcomeView(startAt: [.login(passwordJustUpdated: true)]) { ... }
    init(startAt: [AuthRoute] = [], onLoggedIn: @escaping (UserModel) -> Void = { _ in }) {
        _path = State(initialValue: startAt)
        self.onLoggedIn = onLoggedIn
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: AppTheme.spacing) {
                Spacer()

                AppLogo()
                    .padding(.top, 56)      // sits a bit lower than centre
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
                    TutorVerificationView(onSubmitted: { path.append(.waitingApproval) })
                case .waitingApproval:
                    WaitingApprovalView(
                        onBackToLogIn: {
                            // Pending tutors can't use the app yet, so log them out.
                            try? AuthenticationService.shared.logOut()
                            path = [.login()]
                        },
                        onEditDetails: { path.removeLast() }   // form still has their details
                    )
                }
            }
        }
    }
}

// MARK: - App logo

/// The official StudyVerse logo (studyverse-logo.png): about 180pt,
/// rounded corners and a soft shadow.
/// UIImage(named:) finds the file both in Assets.xcassets and as a loose
/// file in the app bundle, so it works either way the project adds it.
struct AppLogo: View {
    var size: CGFloat = 180

    var body: some View {
        Image(uiImage: UIImage(named: "studyverse-logo") ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: AppTheme.primary.opacity(0.18), radius: 20, y: 10)
            .accessibilityHidden(true)   // "StudyVerse" title right below says it
    }
}

#Preview {
    WelcomeView()
}
