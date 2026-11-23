//
//  ForgotPasswordView.swift
//  StudyVerse
//
//  Branch: Student-Registration
//  Owner: Maira Zaman
//
//  Two screens:
//  - ForgotPasswordView: type your email, tap "Send Reset Link".
//  - CheckEmailView: "Check your email", link expires in 30 minutes,
//    Resend Link, Back to Log In.
//

import SwiftUI

struct ForgotPasswordView: View {
    /// Called with the email after the link was sent.
    var onLinkSent: (String) -> Void = { _ in }

    @State private var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var emailFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Forgot Password", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reset your password")
                            .font(.largeTitle.bold())
                        Text("Enter the email you signed up with and we'll send you a link to reset your password.")
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.bottom, 8)

                    InputField(label: "Email",
                               placeholder: "you@example.com",
                               text: $viewModel.email,
                               error: viewModel.emailError,
                               keyboard: .emailAddress,
                               contentType: .emailAddress)
                        .focused($emailFocused)
                        .submitLabel(.send)
                        .onSubmit(send)

                    PrimaryButton(title: "Send Reset Link",
                                  isLoading: viewModel.isLoading,
                                  action: send)
                        .padding(.top, 8)
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

    private func send() {
        emailFocused = false
        Task {
            if await viewModel.sendResetLink() {
                onLinkSent(viewModel.email.trimmingCharacters(in: .whitespaces))
            }
        }
    }
}

// MARK: - Check your email

struct CheckEmailView: View {
    let email: String
    var onBackToLogIn: () -> Void = {}

    @State private var viewModel: ForgotPasswordViewModel
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 96

    init(email: String, onBackToLogIn: @escaping () -> Void = {}) {
        self.email = email
        self.onBackToLogIn = onBackToLogIn
        _viewModel = State(initialValue: ForgotPasswordViewModel(email: email))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Forgot Password", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(spacing: AppTheme.spacing) {
                    Image(systemName: "envelope.badge.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(AppTheme.primary)
                        .padding(iconSize * 0.22)
                        .frame(width: iconSize, height: iconSize)
                        .background(AppTheme.card, in: Circle())
                        .accessibilityHidden(true)
                        .padding(.top, 24)

                    Text("Check your email")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    VStack(spacing: 4) {
                        Text("We sent a password reset link to")
                        Text(email)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("The link expires in 30 minutes.")
                            .padding(.top, 8)
                    }
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        PrimaryButton(title: "Back to Log In", action: onBackToLogIn)
                        SecondaryButton(title: viewModel.isLoading ? "Sending…" : "Resend Link",
                                        action: resend)
                            .disabled(viewModel.isLoading)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.vertical, AppTheme.spacing)
            }
        }
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func resend() {
        Task {
            if await viewModel.sendResetLink() {
                viewModel.banner = .success("Link sent again", "Check your inbox and spam folder.")
            } else if let error = viewModel.emailError {
                viewModel.banner = .error(error)
            }
        }
    }
}

#Preview("Forgot password") {
    NavigationStack { ForgotPasswordView() }
}

#Preview("Check your email") {
    NavigationStack { CheckEmailView(email: "maira@example.com") }
}
