//
//  ScreenBackground.swift
//  StudyVerse
//
//  Branch: feature/app-theme
//  Owner: Fatima Hajeeh
//
//  Soft vertical gradient behind the top 240pt of every screen:
//  #cdeaed at 75% fading to transparent.
//

import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(alignment: .top) {
                ZStack(alignment: .top) {
                    AppTheme.backgroundBase

                    LinearGradient(colors: [AppTheme.topGlow, .clear],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 240)
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    /// Apply once at the root of each screen.
    func studyverseBackground() -> some View { modifier(ScreenBackground()) }
}
