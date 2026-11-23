//
//  AuthBackHeader.swift
//  StudyVerse
//
//  Branch: Welcome-View
//  Owner: Maira Zaman
//
//  Header for the auth screens (Log In, Sign Up, Forgot Password): only the
//  back button, no small title, because the big title below already says
//  where you are. Reuses Fatima's HeaderCircleButton and the same spacing
//  as her ScreenHeader, so it lines up with every other screen.
//

import SwiftUI

struct AuthBackHeader: View {
    let onBack: () -> Void

    var body: some View {
        HStack {
            HeaderCircleButton(systemImage: "chevron.left", label: "Back", action: onBack)
            Spacer()
        }
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.top, 25)
        .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        AuthBackHeader {}
        Spacer()
    }
    .studyverseBackground()
}
