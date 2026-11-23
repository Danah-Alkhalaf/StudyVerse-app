//
//  VerificationService.swift
//  StudyVerse
//
//  Branch: Tutor-Verification
//  Owner: Maira Zaman
//
//  Saves a tutor's verification details to tutorVerifications/{uid}.
//  Amnah's TutorApprovalView reads this document and sets users/{uid}.status.
//
//  Firebase Storage needs a paid plan, so for now the proof file is saved
//  INSIDE the Firestore document as base64 text. All of that happens in
//  `saveProof(_:into:)`, so switching to Storage later only changes that one
//  function.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firestore document

struct TutorVerification: Codable {
    var institution: String
    var department: String
    var staffId: String
    var workEmail: String
    var courses: [String]

    // Proof of employment
    var proofFileName: String = ""
    var proofMimeType: String = ""
    var proofBase64: String?      // used now (no Storage)
    var proofURL: String?         // for later, when we switch to Storage

    @ServerTimestamp var submittedAt: Date?
}

enum VerificationError: LocalizedError {
    case notLoggedIn
    case network
    case unknown

    var errorDescription: String? {
        switch self {
        case .notLoggedIn: return "You are not logged in. Please log in again."
        case .network:     return "No internet connection. Check your connection and try again."
        case .unknown:     return "Couldn't send your details. Please try again."
        }
    }
}

// MARK: - Service

@MainActor
final class VerificationService {

    static let shared = VerificationService()

    private let db = Firestore.firestore()

    /// Saves the details and the proof file for the logged-in tutor.
    /// Sending again (Edit Details) replaces the old document.
    func submit(institution: String,
                department: String,
                staffId: String,
                workEmail: String,
                courses: [String],
                proof: ProofFile) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw VerificationError.notLoggedIn }

        var verification = TutorVerification(institution: institution,
                                             department: department,
                                             staffId: staffId,
                                             workEmail: workEmail.lowercased(),
                                             courses: courses)
        do {
            try await saveProof(proof, into: &verification)

            let fields = try Firestore.Encoder().encode(verification)
            try await db.collection("tutorVerifications").document(uid).setData(fields)
        } catch let error as NSError where error.domain == FirestoreErrorDomain
                                        && error.code == FirestoreErrorCode.unavailable.rawValue {
            throw VerificationError.network
        } catch {
            throw VerificationError.unknown
        }
    }

    /// THE ONE PLACE that stores the proof file.
    ///
    /// Now:   puts the file in the document as base64 text.
    /// Later (Storage): upload `proof.data` to "verifications/{uid}/proof.pdf"
    ///        (or .jpg), set `verification.proofURL` to the download URL and
    ///        leave `proofBase64` nil. Nothing else needs to change.
    private func saveProof(_ proof: ProofFile, into verification: inout TutorVerification) async throws {
        verification.proofFileName = proof.fileName
        verification.proofMimeType = proof.mimeType
        verification.proofBase64 = proof.data.base64EncodedString()
        verification.proofURL = nil
    }
}
