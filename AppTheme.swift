//
//  AppTheme.swift
//  StudyVerse
//
//  Branch: feature/app-theme
//  Owner: Fatima Hajeeh
//
//  Single source of truth for colors and layout values.
//  Colors taken from the Figma spec; the ones marked (estimated) were read
//  from the screenshots, so swap in the exact hex if they look off.
//

import SwiftUI

extension Color {
    /// Usage: Color(hex: "#cdeaed")
    init(hex: String, opacity: Double = 1) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(.sRGB,
                  red:   Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue:  Double(value & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum AppTheme {

    // MARK: Brand
    static let primary    = Color(hex: "#494381")   // indigo: buttons, titles, active states
    static let accent     = Color(hex: "#3A8FB0")   // (estimated) progress bars, +XP text
    static let card       = Color(hex: "#cdeaed")   // every main card uses this only
    static let cardInner  = Color(hex: "#eaf6f7")   // (estimated) chips / inner tiles on a card
    static let navEnd     = Color(hex: "#b8def1")
    static let avatarFill = Color(hex: "#b5dcef")   // (estimated) initials avatars

    // MARK: Status
    static let coin    = Color(hex: "#D99A1E")      // (estimated)
    static let streak  = Color(hex: "#E8742A")      // (estimated)
    static let success = Color(hex: "#2E9E6B")      // (estimated)
    static let error   = Color(hex: "#E5484D")      // (estimated)

    // MARK: Text
    static let textPrimary   = Color(hex: "#494381")
    static let textSecondary = Color(hex: "#6B6A8F") // (estimated)

    // MARK: Background
    static let backgroundBase = Color(hex: "#F3FAFB") // (estimated) soft near-white
    static let topGlow        = Color(hex: "#cdeaed", opacity: 0.75)

    // MARK: Layout
    static let screenPadding: CGFloat = 24
    static let cardRadius: CGFloat = 24
    static let spacing: CGFloat = 16
    static let minTapSize: CGFloat = 44     // Apple HIG minimum touch target
}
