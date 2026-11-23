//
//  LoginView.swift
//  StudyVerse
//
//  Branch: Welcome-View
//  Owner: Maira Zaman
//
//  Log in with username or email + password.
//  States: loading (spinner in button), incorrect details (red fields),
//  pending tutor (banner), password updated (banner on arrival).
//

import SwiftUI

struct LoginView: View {
    /// Called after a successful log in, so the app can switch to the main tabs.
    var onLoggedIn: (UserModel) -> Void = { _ in }
    var onForgotPassword: () -> Void = {}
    var onSignUp: () -> Void = {}

    @State private var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    private enum Field { case identifier, password }

    init(passwordJustUpdated: Bool = false,
         onLoggedIn: @escaping (UserModel) -> Void = { _ in },
         onForgotPassword: @escaping () -> Void = {},
         onSignUp: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: LoginViewModel(passwordJustUpdated: passwordJustUpdated))
        self.onLoggedIn = onLoggedIn
        self.onForgotPassword = onForgotPassword
        self.onSignUp = onSignUp
    }

    var body: some View {
        VStack(spacing: 0) {
            AuthBackHeader(onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome back!")
                            .font(.largeTitle.bold())
                        Text("Log in to continue your learning adventure.")
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.bottom, 8)

                    InputField(label: "Username or email",
                               placeholder: "e.g. maira_z",
                               text: $viewModel.usernameOrEmail,
                               error: viewModel.identifierError,
                               keyboard: .emailAddress,
                               contentType: .username)
                        .focused($focus, equals: .identifier)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }

                    InputField(label: "Password",
                               placeholder: "Your password",
                               text: $viewModel.password,
                               error: viewModel.passwordError,
                               isSecure: true,
                               contentType: .password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit(logIn)

                    HStack {
                        Spacer()
                        Button("Forgot password?", action: onForgotPassword)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                            .frame(minHeight: AppTheme.minTapSize)
                    }

                    PrimaryButton(title: "Log In", isLoading: viewModel.isLoading, action: logIn)
                        .padding(.top, 8)

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(AppTheme.textSecondary)
                        Button("Sign Up", action: onSignUp)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.primary)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.vertical, AppTheme.spacing)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .disabled(viewModel.isLoading)
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func logIn() {
        focus = nil
        Task {
            if let user = await viewModel.logIn() {
                onLoggedIn(user)
            }
        }
    }
}

#Preview("Normal") {
    LoginView()
}

#Preview("Password updated") {
    LoginView(passwordJustUpdated: true)
}
