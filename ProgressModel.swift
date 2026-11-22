//
//  ProgressModel.swift
//  StudyVerse
//
//  Branch: feature/progress-model
//  Owner: Fatima Hajeeh
//
//  Firestore path: users/{uid}/progress/summary
//  History:        users/{uid}/xpTransactions/{id}
//                  users/{uid}/coinTransactions/{id}
//
//  NOTE: this file references XPData and CoinsData, which are defined in the
//  next branch. Until it's merged, add the two placeholder structs at the
//  bottom of this file (see the commented block) so the project compiles.
//

import Foundation
import FirebaseFirestore

// MARK: - Study Stats

struct StudyStats: Codable, Equatable {
    var quizzesCompleted: Int = 0
    var perfectScores: Int = 0
    var multiplayerWins: Int = 0
    var tasksCompleted: Int = 0
    var materialsStudied: Int = 0
    var totalStudyMinutes: Int = 0
}

// MARK: - Streak

struct StreakData: Codable, Equatable {
    var current: Int = 0
    var longest: Int = 0
    var lastActiveDate: Date?

    /// Call once per day when the student does something meaningful.
    mutating func registerActivity(on date: Date = Date(),
                                   calendar: Calendar = .current) {
        guard let last = lastActiveDate else {
            current = 1; longest = max(longest, 1); lastActiveDate = date
            return
        }
        if calendar.isDate(last, inSameDayAs: date) { return }          // already counted today

        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
        current = calendar.isDate(last, inSameDayAs: yesterday) ? current + 1 : 1
        longest = max(longest, current)
        lastActiveDate = date
    }
}

// MARK: - ProgressModel

struct ProgressModel: Identifiable, Codable, Equatable {
    @DocumentID var id: String?          // document id
    var userID: String                   // matches UserModel / Firebase Auth uid
    var xp: XPData = XPData()
    var coins: CoinsData = CoinsData()
    var streak: StreakData = StreakData()
    var stats: StudyStats = StudyStats()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    /// Fresh progress for a brand new account (call after registration).
    static func new(for userID: String) -> ProgressModel {
        ProgressModel(userID: userID)
    }

    // MARK: Mutations (local only, the service saves to Firestore)

    @discardableResult
    mutating func awardXP(_ source: XPSource, amount: Int? = nil) -> XPGainResult {
        let result = xp.add(amount ?? source.defaultAmount)
        updatedAt = Date()
        return result
    }

    mutating func awardCoins(_ source: CoinSource, amount: Int? = nil) throws {
        try coins.earn(amount ?? source.defaultAmount)
        updatedAt = Date()
    }

    mutating func spendCoins(_ amount: Int) throws {
        try coins.spend(amount)
        updatedAt = Date()
    }

    mutating func registerActivity() {
        streak.registerActivity()
        updatedAt = Date()
    }

    // Firestore field names
    enum CodingKeys: String, CodingKey {
        case id, userID, xp, coins, streak, stats, createdAt, updatedAt
    }
}

// MARK: - Sample data for SwiftUI previews

extension ProgressModel {
    static let preview = ProgressModel(
        userID: "preview-user",
        xp: XPData(totalXP: 340, level: 3),
        coins: CoinsData(balance: 120, totalEarned: 200, totalSpent: 80),
        streak: StreakData(current: 4, longest: 7, lastActiveDate: Date()),
        stats: StudyStats(quizzesCompleted: 6, perfectScores: 1, multiplayerWins: 2,
                          tasksCompleted: 9, materialsStudied: 4, totalStudyMinutes: 310)
    )
}

/* TEMP placeholders ONLY if XPModel/CoinsModel aren't merged yet:
struct XPData: Codable, Equatable { var totalXP = 0; var level = 1 }
struct CoinsData: Codable, Equatable { var balance = 0; var totalEarned = 0; var totalSpent = 0 }
*/
