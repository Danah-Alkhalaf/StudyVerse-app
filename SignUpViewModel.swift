//
//  SignUpViewModel.swift
//  StudyVerse
//
//  Branch: Student-Registration
//  Owner: Maira Zaman
//
//  Holds the sign up form and talks to AuthenticationService.
//  States: idle -> loading -> success (returns the new user) or error.
//  Each error is shown under the field it belongs to; anything else
//  (e.g. no internet) is shown in a FeedbackBanner.
//

import Foundation
import Observation

@MainActor
@Observable
final class SignUpViewModel {
    var role: UserRole = .student
    var fullName = ""
    var username = ""
    var email = ""
    var password = ""

    var isLoading = false
    var fullNameError: String?
    var usernameError: String?
    var emailError: String?
    var passwordError: String?
    var banner: FeedbackMessage?

    private let auth: AuthenticationService

    init(auth: AuthenticationService? = nil) {
        self.auth = auth ?? .shared
    }

    /// Tutors see "Continue" because the next step is Tutor Verification.
    var buttonTitle: String { role == .tutor ? "Continue" : "Sign Up" }

    // MARK: Validation

    /// Checks every field at once so all problems show together.
    /// Returns true when the form can be sent.
    func validate() -> Bool {
        let name = fullName.trimmingCharacters(in: .whitespaces)
        let user = username.trimmingCharacters(in: .whitespaces)
        let mail = email.trimmingCharacters(in: .whitespaces)

        fullNameError = name.isEmpty ? "Enter your full name." : nil
        usernameError = AuthenticationService.isValidUsername(user) ? nil : AuthError.invalidUsername.errorDescription
        emailError    = AuthenticationService.isValidEmail(mail) ? nil : AuthError.invalidEmail.errorDescription
        passwordError = AuthenticationService.isValidPassword(password) ? nil : AuthError.passwordTooShort.errorDescription

        return [fullNameError, usernameError, emailError, passwordError].allSatisfy { $0 == nil }
    }

    /// Live check while typing (called after a short pause): only says
    /// "taken". The format message waits until the user taps the button,
    /// so they are not told off halfway through typing.
    func checkUsernameAvailability() async {
        let user = username.trimmingCharacters(in: .whitespaces)
        guard AuthenticationService.isValidUsername(user) else {
            if usernameError == AuthError.usernameTaken.errorDescription { usernameError = nil }
            return
        }
        let taken = (try? await auth.isUsernameTaken(user)) ?? false
        guard user == username.trimmingCharacters(in: .whitespaces) else { return }   // user kept typing
        if taken {
            usernameError = AuthError.usernameTaken.errorDescription
        } else if usernameError == AuthError.usernameTaken.errorDescription {
            usernameError = nil
        }
    }

    // MARK: Sign up

    /// Returns the new user, or nil if something went wrong (shown on screen).
    func signUp() async -> UserModel? {
        banner = nil
        guard validate() else { return nil }

        isLoading = true
        defer { isLoading = false }

        do {
            return try await auth.signUp(fullName: fullName.trimmingCharacters(in: .whitespaces),
                                         username: username,
                                         email: email,
                                         password: password,
                                         role: role)
        } catch {
            show(AuthError.from(error))
            return nil
        }
    }

    private func show(_ error: AuthError) {
        let message = error.errorDescription
        switch error {
        case .invalidUsername, .usernameTaken:      usernameError = message
        case .emailAlreadyRegistered, .invalidEmail: emailError = message
        case .passwordTooShort:                     passwordError = message
        default:                                    banner = .error(message ?? "Something went wrong. Please try again.")
        }
    }
}
