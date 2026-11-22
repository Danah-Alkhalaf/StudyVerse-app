//
//  LeaderboardViewModel.swift
//  StudyVerse
//
//  Branch: feature/leaderboard
//  Owner: Fatima Hajeeh
//
//  Firestore: leaderboard/{uid} with fields name, xp, weeklyXP, monthlyXP.
//  (Connecting it to live XP updates is the 29 Nov task.)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class LeaderboardViewModel: ObservableObject {
    enum State: Equatable { case loading, loaded, empty, failed(String) }

    @Published var period: LeaderboardPeriod = .weekly { didSet { Task { await load() } } }
    @Published private(set) var entries: [LeaderboardEntry] = []
    @Published private(set) var state: State = .loading
    @Published private(set) var myRank: Int?
    @Published private(set) var myXP: Int = 0

    private let db = Firestore.firestore()
    private let preview: Bool

    init(previewEntries: [LeaderboardEntry]? = nil) {
        if let previewEntries {
            preview = true
            entries = previewEntries
            state = .loaded
            myRank = 12
            myXP = 1300
        } else {
            preview = false
        }
    }

    var podium: [LeaderboardEntry] { Array(entries.prefix(3)) }
    var rest: [LeaderboardEntry] { Array(entries.dropFirst(3).prefix(7)) }

    private var xpField: String {
        switch period {
        case .weekly:  return "weeklyXP"
        case .monthly: return "monthlyXP"
        case .allTime: return "xp"
        }
    }

    func load() async {
        guard !preview else { return }
        state = .loading
        do {
            let snapshot = try await db.collection("leaderboard")
                .order(by: xpField, descending: true).limit(to: 10).getDocuments()

            entries = snapshot.documents.compactMap { doc in
                guard let name = doc["name"] as? String else { return nil }
                return LeaderboardEntry(id: doc.documentID, name: name, xp: doc[xpField] as? Int ?? 0)
            }
            await loadMyRank()
            state = entries.isEmpty ? .empty : .loaded
        } catch {
            state = .failed("Couldn't load the leaderboard. Check your connection and try again.")
        }
    }

    private func loadMyRank() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let me = try await db.collection("leaderboard").document(uid).getDocument()
            myXP = me[xpField] as? Int ?? 0
            let ahead = try await db.collection("leaderboard")
                .whereField(xpField, isGreaterThan: myXP).count.getAggregation(source: .server)
            myRank = Int(truncating: ahead.count) + 1
        } catch {
            myRank = nil      // the "You" row simply hides
        }
    }
}
