//
//  AccountManagementViewModel.swift
//  StudyVerse
//
//  Branch: Account-Management-View
//  Owner: Maira Zaman
//
//  AccountManagementViewModel: edit username (format + "taken" check) and
//  email, "Changes saved" toast.
//  ChangePasswordViewModel: current / new / confirm password sheet.
//  Both use AuthenticationService.
//

import Foundation
import Observation

@MainActor
@Observable
final class AccountManagementViewModel {
    enum State: Equatable { case loading, loaded, failed(String) }

    var state: State = .loading
    var username = ""
    var email = ""
    var usernameError: String?
    var emailError: String?
    var isSaving = false
    var banner: FeedbackMessage?
    /// Shown under the email field after a change was requested.
    var pendingEmail: String?

    private(set) var savedUsername = ""
    private(set) var savedEmail = ""
    private let auth: AuthenticationService

    init(previewUser: UserModel? = nil, auth: AuthenticationService? = nil) {
        self.auth = auth ?? .shared
        if let previewUser { fill(from: previewUser) }
    }

    var hasChanges: Bool {
        clean(username) != savedUsername || clean(email) != savedEmail
    }

    private func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespaces).lowercased()
    }

    // MARK: Load

    func load() async {
        if state != .loaded { state = .loading }
        do {
            try? await auth.syncEmailIfChanged()       // picks up a confirmed email change
            fill(from: try await auth.fetchCurrentUser())
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription
                            ?? "Couldn't load your account. Please try again.")
        }
    }

    private func fill(from user: UserModel) {
        savedUsername = user.username
        savedEmail = user.email
        username = user.username
        email = user.email
        state = .loaded
    }

    // MARK: Live username check

    /// Called half a second after typing stops: only reports "taken".
    func checkUsernameAvailability() async {
        let name = clean(username)
        guard name != savedUsername, AuthenticationService.isValidUsername(name) else {
            if usernameError == AuthError.usernameTaken.errorDescription { usernameError = nil }
            return
        }
        let taken = (try? await auth.isUsernameTaken(name)) ?? false
        guard name == clean(username) else { return }                // still typing
        if taken {
            usernameError = AuthError.usernameTaken.errorDescription
        } else if usernameError == AuthError.usernameTaken.errorDescription {
            usernameError = nil
        }
    }

    // MARK: Save

    func save() async {
        usernameError = nil
        emailError = nil
        banner = nil

        let newUsername = clean(username)
        let newEmail = clean(email)
        let usernameChanged = newUsername != savedUsername
        let emailChanged = newEmail != savedEmail

        if usernameChanged, !AuthenticationService.isValidUsername(newUsername) {
            usernameError = AuthError.invalidUsername.errorDescription
        }
        if emailChanged, !AuthenticationService.isValidEmail(newEmail) {
            emailError = AuthError.invalidEmail.errorDescription
        }
        guard usernameError == nil, emailError == nil, usernameChanged || emailChanged else { return }

        isSaving = true
        defer { isSaving = false }

        if usernameChanged {
            do {
                try await auth.changeUsername(to: newUsername)
                savedUsername = newUsername
                username = newUsername
            } catch {
                show(AuthError.from(error), forUsername: true)
                return
            }
        }

        if emailChanged {
            do {
                try await auth.requestEmailChange(to: newEmail)
                pendingEmail = newEmail
                email = savedEmail            // the real email changes after they confirm
                banner = .success("Changes saved", "Check \(newEmail) and tap the link to confirm your new email.")
            } catch {
                show(AuthError.from(error), forUsername: false)
                if usernameChanged { banner = .success("Username saved") }
            }
            return
        }

        banner = .success("Changes saved")
    }

    private func show(_ error: AuthError, forUsername: Bool) {
        switch error {
        case .invalidUsername, .usernameTaken:
            usernameError = error.errorDescription
        case .invalidEmail, .emailInUseByOther, .emailAlreadyRegistered:
            emailError = error.errorDescription
        default:
            banner = .error(error.errorDescription ?? "Couldn't save. Try again.")
        }
    }
}

// MARK: - Change password

@MainActor
@Observable
final class ChangePasswordViewModel {
    var current = ""
    var new = ""
    var confirm = ""
    var currentError: String?
    var newError: String?
    var confirmError: String?
    var banner: FeedbackMessage?
    var isSaving = false

    private let auth: AuthenticationService

    init(auth: AuthenticationService? = nil) {
        self.auth = auth ?? .shared
    }

    /// Returns true when the password was changed. The caller then logs the
    /// user out and shows Log In with "Password updated. Log in with your
    /// new password."
    func submit() async -> Bool {
        currentError = current.isEmpty ? "Enter your current password." : nil
        newError = AuthenticationService.isValidPassword(new) ? nil : AuthError.passwordTooShort.errorDescription
        confirmError = (newError == nil && confirm != new) ? AuthError.passwordsDontMatch.errorDescription : nil
        banner = nil
        guard currentError == nil, newError == nil, confirmError == nil else { return false }

        isSaving = true
        defer { isSaving = false }
        do {
            try await auth.changePassword(current: current, new: new)
            return true
        } catch {
            let authError = AuthError.from(error)
            switch authError {
            case .wrongCurrentPassword: currentError = authError.errorDescription; current = ""
            case .passwordTooShort:     newError = authError.errorDescription
            default:                    banner = .error(authError.errorDescription ?? "Couldn't change your password. Try again.")
            }
            return false
        }
    }
}
