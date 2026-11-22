//
//  FeedbackBanner.swift
//  StudyVerse
//
//  Branch: feature/student-home-components
//  Owner: Fatima Hajeeh
//
//  Success / error toast that slides in from the top (e.g. "Plan created!",
//  "Goal updated!", "Couldn't save. Try again."). Auto-dismisses after 3s,
//  can be closed with the X, and is announced by VoiceOver.
//

import SwiftUI

struct FeedbackMessage: Equatable, Identifiable {
    enum Kind { case success, error, info }

    let id = UUID()
    let kind: Kind
    let title: String
    var subtitle: String? = nil

    static func success(_ title: String, _ subtitle: String? = nil) -> FeedbackMessage {
        .init(kind: .success, title: title, subtitle: subtitle)
    }
    static func error(_ title: String, _ subtitle: String? = nil) -> FeedbackMessage {
        .init(kind: .error, title: title, subtitle: subtitle)
    }
}

struct FeedbackBanner: View {
    let message: FeedbackMessage
    let onClose: () -> Void

    private var tint: Color {
        switch message.kind {
        case .success: return AppTheme.success
        case .error:   return AppTheme.error
        case .info:    return AppTheme.accent
        }
    }
    private var icon: String {
        switch message.kind {
        case .success: return "checkmark"
        case .error:   return "exclamationmark.triangle.fill"
        case .info:    return "info"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(message.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle = message.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: AppTheme.minTapSize, height: AppTheme.minTapSize)
            }
            .accessibilityLabel("Dismiss message")
        }
        .padding(12)
        .background(Color.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: AppTheme.primary.opacity(0.18), radius: 12, y: 6)
        .padding(.horizontal, AppTheme.screenPadding)
        .accessibilityElement(children: .combine)
        .onAppear {
            UIAccessibility.post(notification: .announcement,
                                 argument: [message.title, message.subtitle].compactMap { $0 }.joined(separator: ". "))
        }
    }
}

// MARK: - Modifier: .feedbackBanner($message)

struct FeedbackBannerModifier: ViewModifier {
    @Binding var message: FeedbackMessage?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let current = message {
                    FeedbackBanner(message: current) { message = nil }
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: current.id) {
                            try? await Task.sleep(for: .seconds(3))
                            if message?.id == current.id { message = nil }
                        }
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: message)
    }
}

extension View {
    func feedbackBanner(_ message: Binding<FeedbackMessage?>) -> some View {
        modifier(FeedbackBannerModifier(message: message))
    }
}

#Preview {
    struct Demo: View {
        @State var message: FeedbackMessage? = .success("Plan created!", "24 days · about 3 quests per day")
        var body: some View {
            Color.clear.studyverseBackground().feedbackBanner($message)
        }
    }
    return Demo()
}
