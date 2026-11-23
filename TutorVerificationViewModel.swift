//
//  TutorVerificationViewModel.swift
//  StudyVerse
//
//  Branch: Tutor-Verification
//  Owner: Maira Zaman
//
//  Holds the Tutor Verification form: details, course chips, the proof file
//  and the confirm checkbox. Checks everything, then sends it through
//  VerificationService.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class TutorVerificationViewModel {
    var institution = ""
    var department = ""
    var staffId = ""
    var workEmail = ""
    var courses: [String] = []
    var newCourse = ""
    var proof: ProofFile?
    var isConfirmed = false

    var isProcessingFile = false
    var isSubmitting = false

    var institutionError: String?
    var departmentError: String?
    var staffIdError: String?
    var workEmailError: String?
    var coursesError: String?
    var proofError: String?
    var confirmError: String?
    var banner: FeedbackMessage?

    private let service: VerificationService

    init(service: VerificationService? = nil) {
        self.service = service ?? .shared
    }

    // MARK: Courses

    func addCourse() {
        let course = newCourse.trimmingCharacters(in: .whitespaces)
        guard !course.isEmpty else { return }
        if !courses.contains(where: { $0.caseInsensitiveCompare(course) == .orderedSame }) {
            courses.append(course)
        }
        newCourse = ""
        coursesError = nil
    }

    func removeCourse(_ course: String) {
        courses.removeAll { $0 == course }
    }

    // MARK: Proof file

    func loadPhoto(_ item: PhotosPickerItem) async {
        isProcessingFile = true
        defer { isProcessingFile = false }
        proofError = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ProofFileError.unreadable
            }
            proof = try await ProofFile.fromImage(data)
        } catch {
            proofError = (error as? ProofFileError ?? .unreadable).errorDescription
        }
    }

    func loadPDF(_ result: Result<URL, Error>) {
        proofError = nil
        do {
            proof = try ProofFile.fromPDF(at: try result.get())
        } catch {
            proofError = (error as? ProofFileError ?? .unreadable).errorDescription
        }
    }

    func removeProof() {
        proof = nil
    }

    // MARK: Submit

    /// Checks every field at once so all problems show together.
    func validate() -> Bool {
        func isBlank(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespaces).isEmpty }

        institutionError = isBlank(institution) ? "Enter your institution." : nil
        departmentError  = isBlank(department) ? "Enter your department." : nil
        staffIdError     = isBlank(staffId) ? "Enter your staff ID." : nil
        workEmailError   = AuthenticationService.isValidEmail(workEmail.trimmingCharacters(in: .whitespaces))
                           ? nil : "Enter a valid email address."
        coursesError     = courses.isEmpty ? "Add at least one course you teach." : nil
        if proof == nil, proofError == nil { proofError = "Upload proof of employment." }
        if proof != nil { proofError = nil }
        confirmError     = isConfirmed ? nil : "Please confirm your details are correct."

        return [institutionError, departmentError, staffIdError, workEmailError,
                coursesError, proofError, confirmError].allSatisfy { $0 == nil }
    }

    /// Returns true when the details were saved.
    func submit() async -> Bool {
        banner = nil
        if !newCourse.trimmingCharacters(in: .whitespaces).isEmpty { addCourse() }   // typed but not added
        guard validate(), let proof else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await service.submit(institution: institution.trimmingCharacters(in: .whitespaces),
                                     department: department.trimmingCharacters(in: .whitespaces),
                                     staffId: staffId.trimmingCharacters(in: .whitespaces),
                                     workEmail: workEmail.trimmingCharacters(in: .whitespaces),
                                     courses: courses,
                                     proof: proof)
            return true
        } catch {
            banner = .error((error as? LocalizedError)?.errorDescription
                            ?? "Couldn't send your details. Please try again.")
            return false
        }
    }
}
