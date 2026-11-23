//
//  ReportIssueViewModel.swift
//  StudyVerse
//
//  Branch: Report-Issue-View
//  Owner: Maira Zaman
//
//  Holds the report form: category (with "Other" + text), description
//  (at least 10 characters), optional screenshot (compressed JPEG under
//  500 KB, like the tutor proof file). Sends it with ReportService and
//  shows the "Report sent" popup.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class ReportIssueViewModel {
    static let minDescriptionLength = 10

    var category: ReportCategory? {
        didSet { if category != nil { categoryError = nil } }
    }
    var otherText = ""
    var description = ""
    var screenshot: ProofFile?

    var categoryError: String?
    var otherError: String?
    var descriptionError: String?
    var screenshotError: String?

    var isProcessingImage = false
    var isSubmitting = false
    var showsSentPopup = false
    var banner: FeedbackMessage?

    private let service: ReportService

    init(service: ReportService? = nil) {
        self.service = service ?? .shared
    }

    // MARK: Screenshot

    func loadScreenshot(_ item: PhotosPickerItem) async {
        isProcessingImage = true
        defer { isProcessingImage = false }
        screenshotError = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ProofFileError.unreadable
            }
            screenshot = try await ProofFile.fromImage(data, fileName: "screenshot.jpg")
        } catch {
            screenshotError = (error as? ProofFileError ?? .unreadable).errorDescription
        }
    }

    func removeScreenshot() { screenshot = nil }

    // MARK: Submit

    func validate() -> Bool {
        categoryError = category == nil ? "Choose what the problem is about." : nil
        otherError = (category == .other && otherText.trimmingCharacters(in: .whitespaces).isEmpty)
            ? "Tell us what the problem is about." : nil
        descriptionError = description.trimmingCharacters(in: .whitespacesAndNewlines).count < Self.minDescriptionLength
            ? "Please describe the issue (at least 10 characters)." : nil
        return categoryError == nil && otherError == nil && descriptionError == nil
    }

    func submit() async {
        banner = nil
        guard validate(), let category else { return }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.submit(category: category,
                                     otherText: otherText.trimmingCharacters(in: .whitespaces),
                                     description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                                     screenshot: screenshot)
            showsSentPopup = true
        } catch {
            banner = .error((error as? LocalizedError)?.errorDescription
                            ?? "Couldn't send your report. Please try again.")
        }
    }
}
