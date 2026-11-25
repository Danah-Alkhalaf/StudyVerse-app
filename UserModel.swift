//
//  UserModel.swift
//  StudyVerse
//
//  Branch: User-Model
//  Owner: Maira Zaman
//
//  Firestore path: users/{uid}
//  Username index: usernames/{username}  ->  UsernameRecord
//
//  NOTE on coins / XP / level:
//  Fatima's ProgressModel already stores them in users/{uid}/progress/summary
//  (XPData + CoinsData). To avoid two copies that can disagree, this model
//  does NOT repeat them. Read coins/XP from ProgressModel instead.
//

import Foundation
import FirebaseFirestore

// MARK: - Role & Status

enum UserRole: String, Codable, CaseIterable {
    case student
    case tutor
    case admin
}

/// Students start "active". Tutors start "pending" until an admin
/// (Amnah's TutorApprovalView) sets "approved" or "rejected".
enum AccountStatus: String, Codable {
    case active
    case pending
    case approved
    case rejected

    /// Starting status for a brand new account.
    static func initial(for role: UserRole) -> AccountStatus {
        role == .tutor ? .pending : .active
    }

    /// True when the user is allowed past the login screen.
    var canLogIn: Bool { self == .active || self == .approved }
}

// MARK: - Avatar

struct AvatarConfig: Codable, Equatable {
    enum Body: String, Codable { case female, male }

    var body: Body = .female
    var skinTone: String = "default"
    var hair: String = "default"
    var hairColor: String = "default"
    var outfit: String = "default"
    var accessory: String = "none"
}

// MARK: - Pet

struct PetConfig: Codable, Equatable {
    var name: String = "Pet"
    var type: String = "cat"
    var collar: String = "none"
    var hat: String = "none"
}

// MARK: - Settings

struct UserSettings: Codable, Equatable {
    enum Theme: String, Codable { case light, dark, system }

    var theme: Theme = .system
    var accentColor: String = "default"
    var notifications: Bool = true
    var volume: Double = 0.8
}

// MARK: - UserModel

struct UserModel: Identifiable, Codable, Equatable {
    @DocumentID var id: String?          // = Firebase Auth uid
    var fullName: String
    var username: String                 // always saved in lowercase
    var email: String
    var role: UserRole
    var status: AccountStatus
    var avatar: AvatarConfig = AvatarConfig()
    var pet: PetConfig = PetConfig()
    var ownedItems: [String] = []        // shop item ids
    var settings: UserSettings = UserSettings()
    @ServerTimestamp var createdAt: Date? // Firestore fills this in when saved

    /// Builds a brand new user for sign up.
    static func new(fullName: String, username: String, email: String, role: UserRole) -> UserModel {
        UserModel(fullName: fullName,
                  username: username.lowercased(),
                  email: email.lowercased(),
                  role: role,
                  status: AccountStatus.initial(for: role))
    }

    // Firestore field names (agreed in the project spec, do not rename alone)
    enum CodingKeys: String, CodingKey {
        case id, fullName, username, email, role, status
        case avatar, pet, ownedItems, settings, createdAt
    }
}

// MARK: - Username record (usernames/{username})

/// One document per username, so we can check if a name is taken and
/// find the email when someone logs in with their username.
struct UsernameRecord: Codable {
    var uid: String
    var email: String
}

// MARK: - Sample data for SwiftUI previews

extension UserModel {
    static let preview = UserModel(
        id: "preview-user",
        fullName: "Maira Zaman",
        username: "maira",
        email: "maira@example.com",
        role: .student,
        status: .active
    )
}
