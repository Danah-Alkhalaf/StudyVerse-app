//
//  AppAppearance.swift
//  StudyVerse
//
//  Branch: Settings-View
//  Owner: Maira Zaman
//
//  The app-wide theme (Light / Dark / System) and accent colour.
//  SettingsView changes it; the app's root view applies it with ONE line:
//
//      WindowGroup { RootView().studyverseAppearance() }
//
//  It is also saved on the phone (UserDefaults), so the right theme shows
//  immediately on launch, before Firestore has loaded.
//

import SwiftUI
import Observation

// MARK: - Accent colour options

/// Stored in users/{uid}.settings.accentColor as the rawValue.
/// "default" (the value new accounts get) means purple.
enum AccentOption: String, CaseIterable, Identifiable {
    case purple, blue, green, orange, pink

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .purple: return AppTheme.primary          // #494381
        case .blue:   return AppTheme.accent           // #3A8FB0
        case .green:  return AppTheme.success          // #2E9E6B
        case .orange: return AppTheme.streak           // #E8742A
        case .pink:   return Color(hex: "#C2588F")
        }
    }

    var name: String { rawValue.capitalized }

    /// Turns the saved string back into an option ("default" or unknown -> purple).
    init(saved: String) {
        self = AccentOption(rawValue: saved) ?? .purple
    }
}

// MARK: - Shared appearance

@MainActor
@Observable
final class AppAppearance {
    static let shared = AppAppearance()

    var theme: UserSettings.Theme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }
    var accent: AccentOption {
        didSet { UserDefaults.standard.set(accent.rawValue, forKey: Keys.accent) }
    }

    /// nil = follow the iPhone's own setting (System).
    var colorScheme: ColorScheme? {
        switch theme {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    private enum Keys {
        static let theme = "studyverse.theme"
        static let accent = "studyverse.accent"
    }

    private init() {
        let defaults = UserDefaults.standard
        theme = UserSettings.Theme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .system
        accent = AccentOption(saved: defaults.string(forKey: Keys.accent) ?? "")
    }

    /// Call after loading a user (log in, profile load) so the app matches
    /// what they saved on any device.
    func apply(_ settings: UserSettings) {
        theme = settings.theme
        accent = AccentOption(saved: settings.accentColor)
    }
}

// MARK: - Root modifier

private struct StudyverseAppearanceModifier: ViewModifier {
    @State private var appearance = AppAppearance.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(appearance.colorScheme)
            .tint(appearance.accent.color)
    }
}

extension View {
    /// Apply once, on the app's root view.
    func studyverseAppearance() -> some View { modifier(StudyverseAppearanceModifier()) }
}
