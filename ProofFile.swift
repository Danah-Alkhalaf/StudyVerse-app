//
//  ProofFile.swift
//  StudyVerse
//
//  Branch: Tutor-Verification
//  Owner: Maira Zaman
//
//  A file the tutor picked as proof of employment (photo or PDF), already
//  made small enough to save. Photos are shrunk and turned into JPEG;
//  PDFs can't be compressed, so they must already be under the limit.
//  No Firebase in this file.
//

import Foundation
import UIKit

struct ProofFile: Equatable, Sendable {
    /// 500 KB. A Firestore document can hold at most 1 MB, and base64 makes
    /// the file about 1/3 bigger, so this keeps us safely under that.
    static let maxBytes = 500 * 1024

    enum Kind: String, Sendable { case image, pdf }

    let data: Data
    let fileName: String
    let kind: Kind

    var mimeType: String { kind == .pdf ? "application/pdf" : "image/jpeg" }

    /// e.g. "312 KB", for showing on screen
    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }

    // MARK: Making a ProofFile

    /// Turns a picked photo into a JPEG under 500 KB.
    /// Runs in the background so the screen doesn't freeze.
    static func fromImage(_ imageData: Data, fileName: String = "proof.jpg") async throws -> ProofFile {
        let jpeg = try await Task.detached(priority: .userInitiated) {
            try compressImage(imageData)
        }.value
        return ProofFile(data: jpeg, fileName: fileName, kind: .image)
    }

    /// Reads a PDF the tutor picked in the Files app.
    static func fromPDF(at url: URL) throws -> ProofFile {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer { if canAccess { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else { throw ProofFileError.unreadable }
        guard data.count <= maxBytes else { throw ProofFileError.tooLarge }
        return ProofFile(data: data, fileName: url.lastPathComponent, kind: .pdf)
    }

    /// Shrinks the picture step by step: first lower JPEG quality,
    /// then make the picture smaller, until it fits under 500 KB.
    private static func compressImage(_ data: Data) throws -> Data {
        guard var image = UIImage(data: data) else { throw ProofFileError.unreadable }
        image = image.resized(maxSide: 1600)

        for _ in 0..<4 {
            for quality in [0.8, 0.6, 0.45, 0.3] as [CGFloat] {
                if let jpeg = image.jpegData(compressionQuality: quality), jpeg.count <= maxBytes {
                    return jpeg
                }
            }
            image = image.resized(maxSide: max(image.size.width, image.size.height) * 0.7)
        }
        throw ProofFileError.tooLarge
    }
}

enum ProofFileError: LocalizedError {
    case tooLarge
    case unreadable

    var errorDescription: String? {
        switch self {
        case .tooLarge:   return "File is too large. Please choose a file under 500 KB."
        case .unreadable: return "We couldn't open that file. Please choose another one."
        }
    }
}

private extension UIImage {
    /// Returns a copy whose longest side is at most `maxSide` points.
    func resized(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        let scale = maxSide / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
