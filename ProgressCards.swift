//
//  ProgressCards.swift
//  StudyVerse
//
//  Branch: feature/student-home-components
//  Owner: Fatima Hajeeh
//
//  Reusable building blocks. Fonts are semantic text styles only (Dynamic Type).
//  All main cards use #cdeaed only.
//

import SwiftUI

// MARK: - Card

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View { modifier(CardStyle(padding: padding)) }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color.white : AppTheme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(isEnabled ? AppTheme.primary : AppTheme.primary.opacity(0.25),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.primary)
                    .frame(minHeight: AppTheme.minTapSize)
                }
            }
        }
    }
}

// MARK: - Pills / chips

struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.cardInner, in: Capsule())
    }
}

/// Square icon holder used inside cards.
struct IconBadge: View {
    let systemImage: String
    var tint: Color = AppTheme.primary
    var body: some View {
        Image(systemName: systemImage)
            .font(.title3)
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(AppTheme.cardInner, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Avatar (initials)

struct InitialsAvatar: View {
    let name: String
    var size: Font = .footnote

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var body: some View {
        Text(initials)
            .font(size.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 40, height: 40)
            .background(AppTheme.avatarFill, in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - XP progress bar

struct XPBar: View {
    let progress: Double      // 0...1
    var body: some View {
        ProgressView(value: min(max(progress, 0), 1))
            .progressViewStyle(.linear)
            .tint(AppTheme.accent)
            .scaleEffect(x: 1, y: 1.8, anchor: .center)
            .background(Color.white.opacity(0.6), in: Capsule())
            .clipShape(Capsule())
    }
}

// MARK: - Empty state (dashed card)

struct EmptyStateCard<Actions: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(spacing: 12) {
            IconBadge(systemImage: systemImage)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            actions()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        }
        .accessibilityElement(children: .combine)
    }
}

extension EmptyStateCard where Actions == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.init(systemImage: systemImage, title: title, message: message) { EmptyView() }
    }
}
