//
//  CoinsModel.swift
//  StudyVerse
//
//  Branch: feature/xp-coins-structure
//  Owner: Fatima Hajeeh
//

import Foundation
import FirebaseFirestore

// MARK: - Coin Source / Spend Reason

enum CoinSource: String, Codable, CaseIterable {
    case quizCompleted
    case quizPerfectScore
    case multiplayerWin
    case studyPlanTaskDone
    case levelUp
    case dailyStreak

    var defaultAmount: Int {
        switch self {
        case .quizCompleted:     return 10
        case .quizPerfectScore:  return 25
        case .multiplayerWin:    return 20
        case .studyPlanTaskDone: return 5
        case .levelUp:           return 50
        case .dailyStreak:       return 5
        }
    }
}

enum CoinSpendReason: String, Codable {
    case shopPurchase      // Maira's ShopView / purchasing system
    case avatarItem
    case petItem
}

// MARK: - Errors

enum CoinError: LocalizedError {
    case insufficientCoins(needed: Int, available: Int)
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .insufficientCoins(let needed, let available):
            return "You need \(needed) coins but only have \(available)."
        case .invalidAmount:
            return "Amount must be greater than zero."
        }
    }
}

// MARK: - Coins Data

struct CoinsData: Codable, Equatable {
    var balance: Int = 0
    var totalEarned: Int = 0
    var totalSpent: Int = 0

    func canAfford(_ price: Int) -> Bool { balance >= price }

    mutating func earn(_ amount: Int) throws {
        guard amount > 0 else { throw CoinError.invalidAmount }
        balance += amount
        totalEarned += amount
    }

    mutating func spend(_ amount: Int) throws {
        guard amount > 0 else { throw CoinError.invalidAmount }
        guard balance >= amount else {
            throw CoinError.insufficientCoins(needed: amount, available: balance)
        }
        balance -= amount
        totalSpent += amount
    }
}

// MARK: - Coin Transaction (history / audit log)

struct CoinTransaction: Identifiable, Codable {
    enum Kind: String, Codable { case earned, spent }

    @DocumentID var id: String?
    var kind: Kind
    var amount: Int
    var source: String        // CoinSource or CoinSpendReason rawValue
    var note: String?
    var createdAt: Date = Date()
}
