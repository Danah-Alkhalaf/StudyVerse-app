//
//  PrimaryButton.swift
//  StudyVerse
//
//  Branch: Welcome-View
//  Owner: Maira Zaman
//
//  Main call-to-action button: purple fill, white bold text, height 50,
//  radius 16. Shows a spinner while `isLoading` is true.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: AppTheme.buttonHeight)
            .background(AppTheme.primary.opacity(isEnabled ? 1 : 0.5),
                        in: RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "\(title), loading" : title)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Log In") {}
        PrimaryButton(title: "Log In", isLoading: true) {}
        PrimaryButton(title: "Log In") {}.disabled(true)
    }
    .padding(AppTheme.screenPadding)
}
