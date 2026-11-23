//
//  ForgotPasswordViewModel.swift
//  StudyVerse
//
//  Branch: Student-Registration
//  Owner: Maira Zaman
//
//  Sends the password reset email. Used by ForgotPasswordView (first send)
//  and CheckEmailView (Resend Link).
//

import Foundation
import Observation

@MainActor
@Observable
final class ForgotPasswordViewModel {
    var email: String
    var isLoading = false
    var emailError: String?
    var banner: FeedbackMessage?

    private let auth: AuthenticationService

    init(email: String = "", auth: AuthenticationService? = nil) {
        self.email = email
        self.auth = auth ?? .shared
    }

    /// Returns true when the email was sent.
    func sendResetLink() async -> Bool {
        emailError = nil
        banner = nil

        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard AuthenticationService.isValidEmail(trimmed) else {
            emailError = AuthError.invalidEmail.errorDescription
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.sendPasswordReset(to: trimmed)
            return true
        } catch {
            let authError = AuthError.from(error)
            switch authError {
            case .noAccountForEmail, .invalidEmail:
                emailError = authError.errorDescription
            default:
                banner = .error(authError.errorDescription ?? "Something went wrong. Please try again.")
            }
            return false
        }
    }
}
