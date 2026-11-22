//
//  StudentHomeViewModel.swift
//  StudyVerse
//
//  Branch: feature/student-home-ui
//  Owner: Fatima Hajeeh
//
//  Live data for the home screen:
//  - users/{uid}/progress/summary   -> XP, level, streak, coins
//  - leaderboard (top 3 by xp)      -> preview card
//  Upcoming tasks come from the Study Plan view model once it is merged.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class StudentHomeViewModel: ObservableObject {
    @Published var progress: ProgressModel
    @Published var topThree: [LeaderboardEntry] = []
    @Published var upcomingTasks: [StudyTask] = []
    @Published var unreadCount: Int = 0
    @Published var feedback: FeedbackMessage?

    private var listeners: [ListenerRegistration] = []
    private let db = Firestore.firestore()

    /// Pass sample data for previews, leave nil for real data.
    init(progress: ProgressModel? = nil,
         topThree: [LeaderboardEntry] = [],
         upcomingTasks: [StudyTask] = [],
         unreadCount: Int = 0) {
        self.progress = progress ?? ProgressModel.new(for: Auth.auth().currentUser?.uid ?? "")
        self.topThree = topThree
        self.upcomingTasks = upcomingTasks
        self.unreadCount = unreadCount
    }

    var username: String {
        let name = Auth.auth().currentUser?.displayName ?? ""
        return name.isEmpty ? "Username" : name
    }

    func startListening() {
        guard listeners.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }

        let progressRef = db.collection("users").document(uid)
            .collection("progress").document("summary")

        listeners.append(progressRef.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                if error != nil {
                    self.feedback = .error("Couldn't load your progress", "Check your connection and try again.")
                    return
                }
                guard let snapshot else { return }
                if snapshot.exists {
                    if let model = try? snapshot.data(as: ProgressModel.self) { self.progress = model }
                } else {
                    try? progressRef.setData(from: ProgressModel.new(for: uid))   // first launch
                }
            }
        })

        listeners.append(db.collection("leaderboard")
            .order(by: "xp", descending: true).limit(to: 3)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    self?.topThree = snapshot?.documents.compactMap { try? $0.data(as: LeaderboardEntry.self) } ?? []
                }
            })
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    deinit { listeners.forEach { $0.remove() } }
}
