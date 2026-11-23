//
//  AuthenticationService.swift
//  StudyVerse
//
//  Branch: User-Model
//  Owner: Maira Zaman
//
//  All Firebase Authentication work lives here, so screens (WelcomeView,
//  LoginView, registration, ForgotPasswordView) never talk to Firebase
//  directly. ViewModels call these functions and show the error's message.
//
//  Writes on sign up:
//  - users/{uid}                    -> UserModel
//  - usernames/{username}           -> UsernameRecord (uid + email)
//  - users/{uid}/progress/summary   -> Fatima's ProgressModel (starting coins)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Friendly errors (messages from CLAUDE.md / the prototype)

enum AuthError: LocalizedError, Equatable {
    case incorrectCredentials
    case pendingApproval
    case accountRejected
    case emailAlreadyRegistered
    case passwordTooShort
    case invalidUsername
    case usernameTaken
    case noAccountForEmail
    case invalidEmail
    case notLoggedIn
    case userDocumentMissing
    case network
    case wrongCurrentPassword
    case passwordsDontMatch
    case requiresRecentLogin
    case emailInUseByOther
    case unknown

    var errorDescription: String? {
        switch self {
        case .incorrectCredentials:   return "Incorrect username or password. Try again."
        case .pendingApproval:        return "Your tutor account is waiting for admin approval."
        case .accountRejected:        return "Your tutor account was not approved. Please contact support."
        case .emailAlreadyRegistered: return "This email is already registered. Log in instead."
        case .passwordTooShort:       return "Password must be at least 8 characters."
        case .invalidUsername:        return "3 to 20 characters. Letters, numbers and underscores only."
        case .usernameTaken:          return "This username is already taken. Try another."
        case .noAccountForEmail:      return "No account found with this email."
        case .invalidEmail:           return "Enter a valid email address."
        case .notLoggedIn:            return "You are not logged in."
        case .userDocumentMissing:    return "We couldn't find your account details. Please try again."
        case .network:                return "No internet connection. Check your connection and try again."
        case .wrongCurrentPassword:   return "Current password is incorrect."
        case .passwordsDontMatch:     return "Passwords don't match."
        case .requiresRecentLogin:    return "For your security, please log out and log in again, then try again."
        case .emailInUseByOther:      return "This email is already used by another account."
        case .unknown:                return "Something went wrong. Please try again."
        }
    }

    /// Turns a Firebase error into one of our friendly errors.
    static func from(_ error: Error) -> AuthError {
        if let authError = error as? AuthError { return authError }

        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown
        }
        switch code {
        case .wrongPassword, .userNotFound, .invalidCredential: return .incorrectCredentials
        case .emailAlreadyInUse:                                return .emailAlreadyRegistered
        case .weakPassword:                                     return .passwordTooShort
        case .invalidEmail:                                     return .invalidEmail
        case .networkError:                                     return .network
        case .requiresRecentLogin:                              return .requiresRecentLogin
        default:                                                return .unknown
        }
    }
}

// MARK: - AuthenticationService

@MainActor
final class AuthenticationService {

    static let shared = AuthenticationService()

    /// Demo starting balance from CLAUDE.md.
    static let startingCoins = 320
    static let minPasswordLength = 8

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private var users: CollectionReference { db.collection("users") }
    private var usernames: CollectionReference { db.collection("usernames") }

    /// The logged-in Firebase uid, or nil.
    var currentUID: String? { auth.currentUser?.uid }
    var isLoggedIn: Bool { auth.currentUser != nil }

    // MARK: Validation (no Firebase needed, use it for live form errors)

    /// 3 to 20 characters: letters, numbers and underscores.
    static func isValidUsername(_ username: String) -> Bool {
        username.wholeMatch(of: #/[A-Za-z0-9_]{3,20}/#) != nil
    }

    /// Simple "something@something.something" check before calling Firebase.
    static func isValidEmail(_ email: String) -> Bool {
        email.wholeMatch(of: #/[^@\s]+@[^@\s]+\.[^@\s]+/#) != nil
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= minPasswordLength
    }

    // MARK: Username check

    /// True if someone already uses this username (not case-sensitive).
    func isUsernameTaken(_ username: String) async throws -> Bool {
        do {
            let snapshot = try await usernames.document(username.lowercased()).getDocument()
            return snapshot.exists
        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: Sign up

    /// Creates the login, the user document, the username record and the
    /// starting progress. Tutors are saved with status "pending" and stay
    /// logged in so they can submit the Tutor Verification screen.
    @discardableResult
    func signUp(fullName: String,
                username: String,
                email: String,
                password: String,
                role: UserRole) async throws -> UserModel {
        let username = username.trimmingCharacters(in: .whitespaces).lowercased()
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()

        guard Self.isValidUsername(username) else { throw AuthError.invalidUsername }
        guard Self.isValidPassword(password) else { throw AuthError.passwordTooShort }
        if try await isUsernameTaken(username) { throw AuthError.usernameTaken }

        // 1. Create the Firebase Auth account
        let authResult: AuthDataResult
        do {
            authResult = try await auth.createUser(withEmail: email, password: password)
        } catch {
            throw AuthError.from(error)
        }
        let uid = authResult.user.uid

        let newUser = UserModel.new(fullName: fullName, username: username, email: email, role: role)
        let record = UsernameRecord(uid: uid, email: email)

        var progress = ProgressModel.new(for: uid)          // Fatima's model
        progress.coins.balance = Self.startingCoins

        let userRef = users.document(uid)
        let usernameRef = usernames.document(username)
        let progressRef = userRef.collection("progress").document("summary")

        // 2. Save everything in ONE transaction, so two people can't grab
        //    the same username at the same moment.
        do {
            let result = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    if try transaction.getDocument(usernameRef).exists {
                        return NSNumber(value: false)        // taken in the meantime
                    }
                    try transaction.setData(from: newUser, forDocument: userRef)
                    try transaction.setData(from: record, forDocument: usernameRef)
                    try transaction.setData(from: progress, forDocument: progressRef)
                    return NSNumber(value: true)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            guard (result as? NSNumber)?.boolValue == true else {
                throw AuthError.usernameTaken
            }
        } catch {
            // Don't leave a half-made account behind.
            try? await authResult.user.delete()
            throw AuthError.from(error)
        }

        // 3. Show the username on Fatima's home screen (it reads displayName)
        let change = authResult.user.createProfileChangeRequest()
        change.displayName = username
        try? await change.commitChanges()

        // Everyone stays logged in after sign up, so new tutors can go straight
        // to the Tutor Verification screen. Pending tutors are only blocked
        // the next time they log in (see logIn).

        var saved = newUser
        saved.id = uid
        return saved
    }

    // MARK: Log in

    /// Accepts a username or an email. Tutors who are not approved yet are
    /// logged straight back out with the "waiting for approval" message.
    @discardableResult
    func logIn(usernameOrEmail: String, password: String) async throws -> UserModel {
        let input = usernameOrEmail.trimmingCharacters(in: .whitespaces).lowercased()

        do {
            let email = input.contains("@") ? input : try await email(forUsername: input)
            try await auth.signIn(withEmail: email, password: password)
            try? await syncEmailIfChanged()

            let user = try await fetchCurrentUser()
            guard user.status.canLogIn else {
                try? auth.signOut()
                throw user.status == .rejected ? AuthError.accountRejected : AuthError.pendingApproval
            }
            return user
        } catch {
            throw AuthError.from(error)
        }
    }

    /// Looks up the email saved for a username. Unknown usernames get the
    /// same message as a wrong password, so we don't reveal who has an account.
    private func email(forUsername username: String) async throws -> String {
        let snapshot = try await usernames.document(username).getDocument()
        guard snapshot.exists, let record = try? snapshot.data(as: UsernameRecord.self) else {
            throw AuthError.incorrectCredentials
        }
        return record.email
    }

    // MARK: Log out

    func logOut() throws {
        do {
            try auth.signOut()
        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: Password reset

    /// Sends the reset email. Note: if "email enumeration protection" is on in
    /// the Firebase console (the default), Firebase never says the email is
    /// unknown, so "No account found with this email." will not appear.
    func sendPasswordReset(to email: String) async throws {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            let mapped = AuthError.from(error)
            throw mapped == .incorrectCredentials ? AuthError.noAccountForEmail : mapped
        }
    }

    // MARK: Current user document

    /// Reads users/{uid} for whoever is logged in.
    func fetchCurrentUser() async throws -> UserModel {
        guard let uid = currentUID else { throw AuthError.notLoggedIn }
        do {
            let snapshot = try await users.document(uid).getDocument()
            guard snapshot.exists else { throw AuthError.userDocumentMissing }
            return try snapshot.data(as: UserModel.self)
        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: Account management (AccountManagementView)

    /// Changes the username in one transaction: claims usernames/{new},
    /// frees usernames/{old} and updates users/{uid}.username, so two people
    /// can never end up with the same name.
    func changeUsername(to newUsername: String) async throws {
        guard let user = auth.currentUser else { throw AuthError.notLoggedIn }
        let new = newUsername.trimmingCharacters(in: .whitespaces).lowercased()
        guard Self.isValidUsername(new) else { throw AuthError.invalidUsername }

        let userRef = users.document(user.uid)
        let newRef = usernames.document(new)
        let usernamesRef = usernames              // captured for the transaction block
        do {
            let result = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let userSnap = try transaction.getDocument(userRef)
                    let old = (userSnap.get("username") as? String) ?? ""
                    let email = (userSnap.get("email") as? String) ?? (user.email ?? "")
                    if old == new { return NSNumber(value: true) }             // nothing to do
                    if try transaction.getDocument(newRef).exists {
                        return NSNumber(value: false)                         // taken
                    }
                    try transaction.setData(from: UsernameRecord(uid: user.uid, email: email), forDocument: newRef)
                    if !old.isEmpty { transaction.deleteDocument(usernamesRef.document(old)) }
                    transaction.updateData(["username": new], forDocument: userRef)
                    return NSNumber(value: true)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            guard (result as? NSNumber)?.boolValue == true else { throw AuthError.usernameTaken }
        } catch {
            throw AuthError.from(error)
        }

        let change = user.createProfileChangeRequest()          // Fatima's home reads this
        change.displayName = new
        try? await change.commitChanges()
    }

    /// Firebase's safe way to change email: it sends a link to the NEW
    /// address, and the email only changes after the user taps it.
    /// users/{uid}.email is then updated by syncEmailIfChanged().
    func requestEmailChange(to newEmail: String) async throws {
        guard let user = auth.currentUser else { throw AuthError.notLoggedIn }
        let email = newEmail.trimmingCharacters(in: .whitespaces).lowercased()
        guard Self.isValidEmail(email) else { throw AuthError.invalidEmail }
        do {
            try await user.sendEmailVerification(beforeUpdatingEmail: email)
        } catch {
            let mapped = AuthError.from(error)
            throw mapped == .emailAlreadyRegistered ? AuthError.emailInUseByOther : mapped
        }
    }

    /// If the login email changed (the user tapped the confirmation link),
    /// copy it into users/{uid}.email and usernames/{username}.email so
    /// logging in with the username keeps working.
    func syncEmailIfChanged() async throws {
        guard let user = auth.currentUser else { return }
        try await user.reload()
        guard let authEmail = auth.currentUser?.email?.lowercased() else { return }

        let userRef = users.document(user.uid)
        let snapshot = try await userRef.getDocument()
        let storedEmail = (snapshot.get("email") as? String) ?? ""
        let username = (snapshot.get("username") as? String) ?? ""
        guard storedEmail != authEmail else { return }

        let batch = db.batch()
        batch.updateData(["email": authEmail], forDocument: userRef)
        if !username.isEmpty {
            batch.updateData(["email": authEmail], forDocument: usernames.document(username))
        }
        try await batch.commit()
    }

    /// Checks the current password first (Firebase requires a recent log in
    /// to change a password), then sets the new one.
    func changePassword(current: String, new: String) async throws {
        guard let user = auth.currentUser, let email = user.email else { throw AuthError.notLoggedIn }
        guard Self.isValidPassword(new) else { throw AuthError.passwordTooShort }

        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: current)
            try await user.reauthenticate(with: credential)
        } catch {
            let mapped = AuthError.from(error)
            throw mapped == .incorrectCredentials ? AuthError.wrongCurrentPassword : mapped
        }

        do {
            try await user.updatePassword(to: new)
        } catch {
            throw AuthError.from(error)
        }
    }
}
