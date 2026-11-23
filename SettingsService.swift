//
//  SettingsService.swift
//  StudyVerse
//
//  Branch: Settings-View
//  Owner: Maira Zaman
//
//  Saves the settings map inside users/{uid} (only that field, nothing
//  else in the user document is touched).
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SettingsService {
    static let shared = SettingsService()

    private let db = Firestore.firestore()

    func save(_ settings: UserSettings) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notLoggedIn }
        let fields = try Firestore.Encoder().encode(settings)
        try await db.collection("users").document(uid).updateData(["settings": fields])
    }
}
