//
//  SettingsViewModel.swift
//  StudyVerse
//
//  Branch: Settings-View
//  Owner: Maira Zaman
//
//  Loads users/{uid}.settings, and saves every change automatically
//  (half a second after the last change) with a "Saved" toast.
//  Appearance and accent are applied to the whole app straight away.
//
//  Volume: Firestore only stores `volume` (0...1). Sound OFF is saved as 0;
//  the last slider level is remembered on the phone so turning sound back
//  on restores it.
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    enum State: Equatable { case loading, loaded, failed(String) }

    var state: State = .loading
    var banner: FeedbackMessage?
    var isSaving = false

    var theme: UserSettings.Theme = .system {
        didSet { guard isReady, theme != oldValue else { return }
                 AppAppearance.shared.theme = theme; scheduleSave() }
    }
    var accent: AccentOption = .purple {
        didSet { guard isReady, accent != oldValue else { return }
                 AppAppearance.shared.accent = accent; scheduleSave() }
    }
    var notifications = true {
        didSet { guard isReady, notifications != oldValue else { return }; scheduleSave() }
    }
    var soundOn = true {
        didSet { guard isReady, soundOn != oldValue else { return }; scheduleSave() }
    }
    var volume: Double = 0.8 {
        didSet { guard isReady, volume != oldValue else { return }
                 if volume > 0 { UserDefaults.standard.set(volume, forKey: Self.lastVolumeKey) }
                 scheduleSave() }
    }

    private var isReady = false            // ignore didSet while loading
    private var saveTask: Task<Void, Never>?
    private let auth: AuthenticationService
    private let service: SettingsService
    private static let lastVolumeKey = "studyverse.lastVolume"

    init(previewSettings: UserSettings? = nil,
         auth: AuthenticationService? = nil,
         service: SettingsService? = nil) {
        self.auth = auth ?? .shared
        self.service = service ?? .shared
        if let previewSettings { fill(from: previewSettings) }
    }

    // MARK: Load

    func load() async {
        if state != .loaded { state = .loading }
        do {
            let user = try await auth.fetchCurrentUser()
            fill(from: user.settings)
            AppAppearance.shared.apply(user.settings)
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription
                            ?? "Couldn't load your settings. Please try again.")
        }
    }

    private func fill(from settings: UserSettings) {
        isReady = false
        theme = settings.theme
        accent = AccentOption(saved: settings.accentColor)
        notifications = settings.notifications
        soundOn = settings.volume > 0
        let remembered = UserDefaults.standard.double(forKey: Self.lastVolumeKey)
        volume = settings.volume > 0 ? settings.volume : (remembered > 0 ? remembered : 0.8)
        state = .loaded
        isReady = true
    }

    // MARK: Save

    /// What gets written to Firestore.
    var currentSettings: UserSettings {
        UserSettings(theme: theme,
                     accentColor: accent.rawValue,
                     notifications: notifications,
                     volume: soundOn ? volume : 0)
    }

    /// Waits until the user stops changing things (e.g. dragging the
    /// slider), then saves once.
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(600)) } catch { return }
            await self?.save()
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.save(currentSettings)
            banner = .success("Saved")
        } catch {
            banner = .error("Couldn't save. Try again.")
        }
    }
}
