//
//  XPModel.swift
//  StudyVerse
//
//  Branch: feature/xp-coins-structure
//  Owner: Fatima Hajeeh
//

import Foundation

// MARK: - XP Source

/// Every action that can award XP. Other modules (Quiz, Study Plan, AI) should
/// pass one of these to the XP logic instead of hard-coding numbers.
enum XPSource: String, Codable, CaseIterable {
    case quizCompleted
    case quizPerfectScore
    case multiplayerWin
    case studyPlanTaskDone
    case materialStudied
    case flashcardsReviewed
    case dailyLogin

    /// Default XP amount. Tweak freely, this is the single place to change it.
    var defaultAmount: Int {
        switch self {
        case .quizCompleted:      return 50
        case .quizPerfectScore:   return 100
        case .multiplayerWin:     return 75
        case .studyPlanTaskDone:  return 30
        case .materialStudied:    return 20
        case .flashcardsReviewed: return 15
        case .dailyLogin:         return 10
        }
    }
}

// MARK: - Level Curve

/// Level math lives here so UI + logic always agree.
/// Level 1 = 0 XP, Level 2 = 100, Level 3 = 300, Level 4 = 600 ...
/// Rule: total XP needed to reach level L = 50 * L * (L - 1)
enum LevelCurve {
    static func xpRequired(toReach level: Int) -> Int {
        guard level > 1 else { return 0 }
        return 50 * level * (level - 1)
    }

    static func level(forTotalXP xp: Int) -> Int {
        var level = 1
        while xpRequired(toReach: level + 1) <= xp { level += 1 }
        return level
    }
}

// MARK: - XP Data

struct XPData: Codable, Equatable {
    var totalXP: Int = 0
    var level: Int = 1

    // Derived values for the UI (not stored in Firestore)
    var xpAtCurrentLevel: Int { LevelCurve.xpRequired(toReach: level) }
    var xpForNextLevel: Int { LevelCurve.xpRequired(toReach: level + 1) }
    var xpIntoLevel: Int { totalXP - xpAtCurrentLevel }
    var xpNeededForLevel: Int { xpForNextLevel - xpAtCurrentLevel }

    /// 0.0 ... 1.0 for ProgressView bars
    var levelProgress: Double {
        guard xpNeededForLevel > 0 else { return 0 }
        return min(max(Double(xpIntoLevel) / Double(xpNeededForLevel), 0), 1)
    }

    enum CodingKeys: String, CodingKey { case totalXP, level }
}

// MARK: - Result of adding XP

struct XPGainResult {
    let amount: Int
    let oldLevel: Int
    let newLevel: Int
    var didLevelUp: Bool { newLevel > oldLevel }
}

extension XPData {
    /// Adds XP (negative values are ignored) and recalculates the level.
    @discardableResult
    mutating func add(_ amount: Int) -> XPGainResult {
        let safe = max(amount, 0)
        let old = level
        totalXP += safe
        level = LevelCurve.level(forTotalXP: totalXP)
        return XPGainResult(amount: safe, oldLevel: old, newLevel: level)
    }
}

// MARK: - XP Transaction (history / audit log)

import FirebaseFirestore

struct XPTransaction: Identifiable, Codable {
    @DocumentID var id: String?
    var source: XPSource
    var amount: Int
    var note: String?
    var createdAt: Date = Date()
}
