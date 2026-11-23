//
//  ProfileViewModel.swift
//  StudyVerse
//
//  Branch: Profile-View
//  Owner: Maira Zaman
//
//  Loads the logged-in user's users/{uid} document for ProfileView and
//  handles Log out. States: loading -> loaded(user) or failed(message).
//  No coins / XP / level here (those are on Fatima's screens).
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    enum State: Equatable {
        case loading
        case loaded(UserModel)
        case failed(String)
    }

    var state: State = .loading
    var banner: FeedbackMessage?

    private let auth: AuthenticationService

    /// Pass `previewUser` for SwiftUI previews / tests; leave nil for real data.
    init(previewUser: UserModel? = nil, auth: AuthenticationService? = nil) {
        self.auth = auth ?? .shared
        if let previewUser { state = .loaded(previewUser) }
    }

    var user: UserModel? {
        if case .loaded(let user) = state { return user }
        return nil
    }

    func load() async {
        if user == nil { state = .loading }
        do {
            state = .loaded(try await auth.fetchCurrentUser())
        } catch {
            // Keep showing old data if we had it; only show the error screen
            // when there is nothing to show.
            let message = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't load your profile. Please try again."
            if user == nil {
                state = .failed(message)
            } else {
                banner = .error("Couldn't refresh your profile", message)
            }
        }
    }

    /// Returns true when logged out (the app then shows WelcomeView).
    func logOut() -> Bool {
        do {
            try auth.logOut()
            return true
        } catch {
            banner = .error("Couldn't log out. Please try again.")
            return false
        }
    }
}
