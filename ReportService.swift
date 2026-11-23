//
//  ReportService.swift
//  StudyVerse
//
//  Branch: Report-Issue-View
//  Owner: Maira Zaman
//
//  Saves a problem report to reports/{id} (Amnah's SupportTicketsView reads
//  these). Like tutor verification, the optional screenshot is stored INSIDE
//  the document as base64 (no Firebase Storage). All of that happens in
//  `saveScreenshot(_:into:)`, so switching to Storage later only changes
//  that one function (upload to "reports/{id}.jpg", set screenshotURL).
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Categories

/// Stored as the rawValue in reports/{id}.category.
enum ReportCategory: String, CaseIterable, Identifiable, Codable {
    case bug
    case account
    case quiz
    case chat
    case inappropriate
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bug:           return "Something isn't working"
        case .account:       return "Account or log in problem"
        case .quiz:          return "Quiz or study content"
        case .chat:          return "Chat or messages"
        case .inappropriate: return "Inappropriate content or user"
        case .other:         return "Other"
        }
    }
}

// MARK: - Firestore document

struct IssueReport: Codable {
    var uid: String
    var category: ReportCategory
    var otherText: String
    var description: String

    var screenshotFileName: String?
    var screenshotMimeType: String?
    var screenshotBase64: String?    // used now (no Storage)
    var screenshotURL: String?       // for later, with Storage

    var status: String = "open"
    @ServerTimestamp var createdAt: Date?
}

// MARK: - Service

@MainActor
final class ReportService {
    static let shared = ReportService()

    private let db = Firestore.firestore()

    func submit(category: ReportCategory,
                otherText: String,
                description: String,
                screenshot: ProofFile?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notLoggedIn }

        var report = IssueReport(uid: uid,
                                 category: category,
                                 otherText: category == .other ? otherText : "",
                                 description: description)
        let ref = db.collection("reports").document()          // new random id
        do {
            if let screenshot { try await saveScreenshot(screenshot, into: &report) }
            try await ref.setData(Firestore.Encoder().encode(report))
        } catch let error as NSError where error.domain == FirestoreErrorDomain
                                        && error.code == FirestoreErrorCode.unavailable.rawValue {
            throw AuthError.network
        }
    }

    /// THE ONE PLACE that stores the screenshot.
    /// Now: base64 text in the document. Later (Storage): upload
    /// `screenshot.data` to "reports/{id}.jpg", set `report.screenshotURL`,
    /// leave `screenshotBase64` nil.
    private func saveScreenshot(_ screenshot: ProofFile, into report: inout IssueReport) async throws {
        report.screenshotFileName = screenshot.fileName
        report.screenshotMimeType = screenshot.mimeType
        report.screenshotBase64 = screenshot.data.base64EncodedString()
        report.screenshotURL = nil
    }
}
