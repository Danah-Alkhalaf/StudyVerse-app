//
//  LoginViewModel.swift
//  StudyVerse
//
//  Branch: Welcome-View
//  Owner: Maira Zaman
//
//  Holds what the user typed on LoginView and talks to AuthenticationService.
//  States: idle -> loading -> success (onLoggedIn) or error.
//  - Wrong details      -> red fields + "Incorrect username or password. Try again."
//  - Tutor not approved -> banner "Your tutor account is waiting for admin approval."
//  - Password changed   -> banner "Password updated. Log in with your new password."
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var usernameOrEmail = ""
    var password = ""

    var isLoading = false
    var identifierError: String?
    var passwordError: String?
    var banner: FeedbackMessage?

    private let auth: AuthenticationService

    init(auth: AuthenticationService? = nil, passwordJustUpdated: Bool = false) {
        self.auth = auth ?? .shared
        if passwordJustUpdated {
            banner = .success("Password updated. Log in with your new password.")
        }
    }

    /// Returns the logged-in user, or nil if something went wrong
    /// (the error is then shown on screen).
    func logIn() async -> UserModel? {
        identifierError = nil
        passwordError = nil
        banner = nil

        // Quick checks before calling Firebase
        if usernameOrEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            identifierError = "Enter your username or email."
        }
        if password.isEmpty {
            passwordError = "Enter your password."
        }
        guard identifierError == nil, passwordError == nil else { return nil }

        isLoading = true
        defer { isLoading = false }

        do {
            return try await auth.logIn(usernameOrEmail: usernameOrEmail, password: password)
        } catch {
            show(AuthError.from(error))
            return nil
        }
    }

    private func show(_ error: AuthError) {
        switch error {
        case .incorrectCredentials:
            // Red border on both fields, message under the password
            identifierError = ""
            passwordError = error.errorDescription
            password = ""
        case .pendingApproval:
            banner = FeedbackMessage(kind: .info, title: error.errorDescription ?? "")
        default:
            banner = .error(error.errorDescription ?? "Something went wrong. Please try again.")
        }
    }
}
