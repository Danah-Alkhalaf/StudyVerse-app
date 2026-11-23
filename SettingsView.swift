//
//  SettingsView.swift
//  StudyVerse
//
//  Branch: Settings-View
//  Owner: Maira Zaman
//
//  Appearance (Light / Dark / System), accent colour swatches,
//  notifications toggle, sound toggle + volume slider.
//  Every change saves itself to users/{uid}.settings and shows "Saved".
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(previewSettings: UserSettings? = nil) {
        _viewModel = State(initialValue: SettingsViewModel(previewSettings: previewSettings))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Settings", showsBack: true, onBack: { dismiss() }) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(AppTheme.primary)
                        .frame(width: AppTheme.minTapSize, height: AppTheme.minTapSize)
                        .accessibilityLabel("Saving")
                }
            }

            switch viewModel.state {
            case .loading:
                Spacer()
                ProgressView("Loading settings…").tint(AppTheme.primary)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            case .failed(let message):
                Spacer()
                VStack(spacing: AppTheme.spacing) {
                    Text("Couldn't load your settings")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: "Try Again") { Task { await viewModel.load() } }
                }
                .padding(.horizontal, AppTheme.screenPadding)
                Spacer()
            case .loaded:
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing) {
                        appearanceSection
                        accentSection
                        notificationsSection
                        soundSection
                    }
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.vertical, AppTheme.spacing)
                }
            }
        }
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { if viewModel.state != .loaded { await viewModel.load() } }
    }

    // MARK: Sections

    private var appearanceSection: some View {
        SettingsCard(title: "Appearance") {
            HStack(spacing: 4) {
                themeOption(.light, title: "Light", icon: "sun.max.fill")
                themeOption(.dark, title: "Dark", icon: "moon.fill")
                themeOption(.system, title: "System", icon: "circle.lefthalf.filled")
            }
            .padding(4)
            .background(Color.white.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous))
        }
    }

    private func themeOption(_ value: UserSettings.Theme, title: String, icon: String) -> some View {
        let isSelected = viewModel.theme == value
        return Button {
            viewModel.theme = value
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.headline)
                Text(title).font(.footnote.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.primary)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppTheme.buttonRadius - 4, style: .continuous)
                        .fill(AppTheme.primary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accentSection: some View {
        SettingsCard(title: "Accent color") {
            HStack(spacing: 0) {
                ForEach(AccentOption.allCases) { option in
                    let isSelected = viewModel.accent == option
                    Button {
                        viewModel.accent = option
                    } label: {
                        Circle()
                            .fill(option.color)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(4)
                            .overlay {
                                Circle().strokeBorder(isSelected ? option.color : .clear, lineWidth: 2)
                            }
                            .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.name)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var notificationsSection: some View {
        SettingsCard(title: "Notifications") {
            Toggle(isOn: $viewModel.notifications) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push notifications")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Quiz reminders, study plan tasks and messages.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .tint(AppTheme.primary)
        }
    }

    private var soundSection: some View {
        SettingsCard(title: "Sound") {
            VStack(spacing: 12) {
                Toggle(isOn: $viewModel.soundOn.animation()) {
                    Text("Sound effects")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .tint(AppTheme.primary)

                if viewModel.soundOn {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                            .accessibilityHidden(true)
                        Slider(value: $viewModel.volume, in: 0.05...1)
                            .tint(AppTheme.primary)
                            .accessibilityLabel("Volume")
                            .accessibilityValue("\(Int(viewModel.volume * 100)) percent")
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - Card

private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .padding(AppTheme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }
}

#Preview {
    NavigationStack { SettingsView(previewSettings: UserSettings()) }
}
