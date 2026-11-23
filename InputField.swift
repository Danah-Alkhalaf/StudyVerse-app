//
//  InputField.swift
//  StudyVerse
//
//  Branch: Welcome-View
//  Owner: Maira Zaman
//
//  Text input from the prototype: bold label above, white box (height 48,
//  radius 14) with a 1.2pt blue border. When `error` is set the border turns
//  red and the message appears below with an alert icon (pass "" for a red
//  border without a message).
//  `isSecure: true` hides the text and adds a show/hide eye button.
//

import SwiftUI

struct InputField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String
    var error: String? = nil
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    @State private var isRevealed = false

    private var hasError: Bool { error != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote.bold())
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 8) {
                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboard)
                    }
                }
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(minWidth: AppTheme.minTapSize, minHeight: AppTheme.minTapSize)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, isSecure ? 2 : 14)
            .frame(minHeight: AppTheme.inputHeight)
            .background(Color.white,
                        in: RoundedRectangle(cornerRadius: AppTheme.inputRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.inputRadius, style: .continuous)
                    .strokeBorder(hasError ? AppTheme.error : AppTheme.inputBorder, lineWidth: 1.2)
            }
            .accessibilityLabel(label)
            .accessibilityHint(error ?? "")

            // An empty string ("") gives a red border with no message,
            // e.g. the username box when the password message is shown.
            if let error, !error.isEmpty {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.error)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: error)
    }
}

#Preview {
    struct Demo: View {
        @State var name = ""
        @State var password = "secret"
        var body: some View {
            VStack(spacing: 20) {
                InputField(label: "Username or email", placeholder: "e.g. maira_z", text: $name)
                InputField(label: "Password", text: $password,
                           error: "Incorrect username or password. Try again.", isSecure: true)
            }
            .padding(AppTheme.screenPadding)
            .studyverseBackground()
        }
    }
    return Demo()
}
