//
//  SecondaryButton.swift
//  StudyVerse
//
//  Branch: Welcome-View
//  Owner: Maira Zaman
//
//  Second-choice button: teal card fill, purple bold text, same size as
//  PrimaryButton. Use `isOutline: true` for the 1.5pt purple outline style.
//

import SwiftUI

struct SecondaryButton: View {
    let title: String
    var isOutline: Bool = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
                .frame(maxWidth: .infinity, minHeight: AppTheme.buttonHeight)
                .background(isOutline ? Color.clear : AppTheme.card, in: shape)
                .overlay {
                    if isOutline { shape.strokeBorder(AppTheme.primary, lineWidth: 1.5) }
                }
                .contentShape(shape)
                .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Sign Up") {}
        SecondaryButton(title: "Sign Up", isOutline: true) {}
    }
    .padding(AppTheme.screenPadding)
}
