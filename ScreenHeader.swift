//
//  ScreenHeader.swift
//  StudyVerse
//
//  Branch: feature/app-theme
//  Owner: Fatima Hajeeh
//
//  Centered title header with optional back / trailing buttons.
//  It sits below the Dynamic Island using the real safe area (about 84pt from
//  the top on iPhone 15/16) instead of a hard-coded number, so it stays
//  correct on every device.
//

import SwiftUI

struct ScreenHeader<Trailing: View>: View {
    let title: String
    var showsBack: Bool = false
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ZStack {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack {
                if showsBack {
                    HeaderCircleButton(systemImage: "chevron.left",
                                       label: "Back") { onBack?() }
                }
                Spacer()
                trailing()
            }
        }
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.top, 25)               // + safe area (~59pt) = about 84pt
        .padding(.bottom, 8)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, showsBack: Bool = false, onBack: (() -> Void)? = nil) {
        self.init(title: title, showsBack: showsBack, onBack: onBack) { EmptyView() }
    }
}

/// Round 44pt button used for back / plus / bell / filter.
struct HeaderCircleButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
                .frame(width: AppTheme.minTapSize, height: AppTheme.minTapSize)
                .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityLabel(label)
    }
}
