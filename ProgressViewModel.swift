//
//  ProgressViewModel.swift
//  StudyVerse
//
//  Branch: feature/progress-tracking
//  Owner: Fatima Hajeeh
//
//  Firestore:
//    users/{uid}/progress/summary      -> level, XP, streak
//    users/{uid}/studyLog/{yyyy-MM-dd} -> { date, minutes }
//    users/{uid}/xpTransactions        -> recent activity (see XPTransaction)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct DayStudy: Identifiable, Equatable {
    let date: Date
    let minutes: Int
    var id: Date { date }
    var letter: String { date.formatted(.dateTime.weekday(.narrow)) }
    var hours: Double { Double(minutes) / 60 }
}

struct ActivityItem: Identifiable, Equatable {
    let id = UUID()
    let systemImage: String
    let title: String
    let subtitle: String
    let xp: Int
}

@MainActor
final class ProgressViewModel: ObservableObject {
    enum State: Equatable { case loading, loaded, failed(String) }

    @Published private(set) var state: State = .loading
    @Published private(set) var progress: ProgressModel = .new(for: "")
    @Published private(set) var week: [DayStudy] = []
    @Published private(set) var activity: [ActivityItem] = []
    @Published var weeklyGoalHours: Double = 8

    private let db = Firestore.firestore()
    private let preview: Bool

    init(previewData: Bool = false) {
        preview = previewData
        if previewData {
            progress = .preview
            let start = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
            let mins = [60, 90, 30, 90, 60, 60, 0]
            week = mins.enumerated().map { DayStudy(date: Calendar.current.date(byAdding: .day, value: $0.offset, to: start)!, minutes: $0.element) }
            activity = [
                .init(systemImage: "questionmark.circle", title: "Quiz completed", subtitle: "Score 8 / 10 · 12 min", xp: 60),
                .init(systemImage: "doc.text", title: "PDF uploaded", subtitle: "Chapter 3 notes", xp: 20),
                .init(systemImage: "person.2", title: "Group quiz played", subtitle: "Ranked 2nd · 18 min", xp: 80)
            ]
            state = .loaded
        }
    }

    // MARK: Derived values for the cards

    var weekMinutes: Int { week.reduce(0) { $0 + $1.minutes } }
    var weekHoursText: String { "\(weekMinutes / 60)h \(weekMinutes % 60)m" }
    var weekXP: Int { activity.reduce(0) { $0 + $1.xp } }
    var xpToNextLevel: Int { max(progress.xp.xpForNextLevel - progress.xp.totalXP, 0) }

    /// True for each of the last 7 days that has study time (feeds the streak row).
    var streakDays: [(letter: String, done: Bool)] { week.map { ($0.letter, $0.minutes > 0) } }

    // MARK: Loading

    func load() async {
        guard !preview, let uid = Auth.auth().currentUser?.uid else { return }
        state = .loading
        do {
            let user = db.collection("users").document(uid)

            let summary = try await user.collection("progress").document("summary").getDocument()
            if let model = try? summary.data(as: ProgressModel.self) { progress = model }

            let start = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
            let logs = try await user.collection("studyLog")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start)).getDocuments()
            let minutesByDay = Dictionary(uniqueKeysWithValues: logs.documents.compactMap { doc -> (Date, Int)? in
                guard let ts = doc["date"] as? Timestamp else { return nil }
                return (Calendar.current.startOfDay(for: ts.dateValue()), doc["minutes"] as? Int ?? 0)
            })
            week = (0..<7).map { offset in
                let day = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: start))!
                return DayStudy(date: day, minutes: minutesByDay[day] ?? 0)
            }

            let tx = try await user.collection("xpTransactions")
                .order(by: "createdAt", descending: true).limit(to: 3).getDocuments()
            activity = tx.documents.compactMap { try? $0.data(as: XPTransaction.self) }.map {
                ActivityItem(systemImage: Self.icon(for: $0.source), title: Self.title(for: $0.source),
                             subtitle: $0.note ?? "", xp: $0.amount)
            }
            state = .loaded
        } catch {
            state = .failed("Couldn't load your progress. Check your connection and try again.")
        }
    }

    private static func icon(for source: XPSource) -> String {
        switch source {
        case .quizCompleted, .quizPerfectScore: return "questionmark.circle"
        case .multiplayerWin:                   return "person.2"
        case .studyPlanTaskDone:                return "checklist"
        case .materialStudied:                  return "doc.text"
        case .flashcardsReviewed:               return "rectangle.stack"
        case .dailyLogin:                       return "sun.max"
        }
    }

    private static func title(for source: XPSource) -> String {
        switch source {
        case .quizCompleted:      return "Quiz completed"
        case .quizPerfectScore:   return "Perfect score"
        case .multiplayerWin:     return "Group quiz played"
        case .studyPlanTaskDone:  return "Quest completed"
        case .materialStudied:    return "Material studied"
        case .flashcardsReviewed: return "Flashcards reviewed"
        case .dailyLogin:         return "Daily login"
        }
    }
}
