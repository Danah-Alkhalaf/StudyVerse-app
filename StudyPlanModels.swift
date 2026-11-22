//
//  StudyPlanModels.swift
//  StudyVerse
//
//  Branch: feature/student-home-ui
//  Owner: Fatima Hajeeh
//
//  Small models shared by Home, Leaderboard and Study Plan screens.
//

import Foundation
import FirebaseFirestore

// MARK: - Study task / quest

enum StudyTaskKind: String, Codable, CaseIterable, Identifiable {
    case summary, flashcards, mistakes, quiz, groupQuiz
    var id: String { rawValue }

    var title: String {
        switch self {
        case .summary:    return "Summary"
        case .flashcards: return "Flashcards"
        case .mistakes:   return "Mistakes"
        case .quiz:       return "Quiz"
        case .groupQuiz:  return "Group quiz"
        }
    }

    var systemImage: String {
        switch self {
        case .summary:    return "doc.text"
        case .flashcards: return "rectangle.stack"
        case .mistakes:   return "arrow.counterclockwise"
        case .quiz:       return "questionmark.circle"
        case .groupQuiz:  return "person.2"
        }
    }
}

struct StudyTask: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var title: String
    var kind: StudyTaskKind
    var minutes: Int
    var xpReward: Int
    var date: Date
    var isDone: Bool = false
    var courseName: String? = nil
}

// MARK: - Leaderboard

struct LeaderboardEntry: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var xp: Int
    var rankChange: Int = 0        // +2 = moved up two places
}

enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case allTime = "All Time"
    var id: String { rawValue }
}

// MARK: - Sample data (previews only)

extension StudyTask {
    static let samples: [StudyTask] = [
        .init(title: "Read Chapter 3 summary", kind: .summary, minutes: 5, xpReward: 20, date: .now, isDone: true),
        .init(title: "Review 10 flashcards", kind: .flashcards, minutes: 8, xpReward: 30, date: .now, isDone: true),
        .init(title: "Redo 6 mistakes", kind: .mistakes, minutes: 7, xpReward: 20, date: .now)
    ]
}

extension LeaderboardEntry {
    static let samples: [LeaderboardEntry] = [
        .init(name: "Sara Ali", xp: 2450), .init(name: "Omar Hassan", xp: 2310),
        .init(name: "Lina Saleh", xp: 2180), .init(name: "Noor Hasan", xp: 2050),
        .init(name: "Yusuf Karim", xp: 1940), .init(name: "Mariam Adel", xp: 1820),
        .init(name: "Hamza Ali", xp: 1700), .init(name: "Dana Faris", xp: 1590)
    ]
}
