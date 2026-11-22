//
//  FloatingTabBar.swift
//  StudyVerse
//
//  Branch: feature/app-theme
//  Owner: Fatima Hajeeh
//
//  Floating pill navbar (icons only, per the design):
//  - 135° gradient #cdeaed (92%) -> #b8def1 (80%)
//  - background blur, 1.5pt white border at 90%
//  - shadow #494381 at 28%, blur 32, y-offset 10
//  - active tab: white capsule at 80% with a soft shadow
//

import SwiftUI

enum StudyverseTab: Int, CaseIterable, Identifiable {
    case home, courses, chats, plan

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .home:    return "house"
        case .courses: return "book"
        case .chats:   return "bubble.left"
        case .plan:    return "calendar.badge.checkmark"
        }
    }

    var activeIcon: String {
        switch self {
        case .home:    return "house.fill"
        case .courses: return "book.fill"
        case .chats:   return "bubble.left.fill"
        case .plan:    return "calendar.badge.checkmark"
        }
    }

    /// Icons have no visible text, so VoiceOver needs these.
    var accessibilityName: String {
        switch self {
        case .home:    return "Home"
        case .courses: return "Courses"
        case .chats:   return "Chats"
        case .plan:    return "Study Plan"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: StudyverseTab
    @Namespace private var capsuleNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StudyverseTab.allCases) { tab in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = tab
                    }
                } label: {
                    ZStack {
                        if selection == tab {
                            Capsule()
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: AppTheme.primary.opacity(0.15), radius: 6, y: 3)
                                .matchedGeometryEffect(id: "activeCapsule", in: capsuleNamespace)
                        }
                        Image(systemName: selection == tab ? tab.activeIcon : tab.icon)
                            .font(.title3)
                            .foregroundStyle(AppTheme.primary)
                    }
                    .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize + 12)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.accessibilityName)
                .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
            }
        }
        .padding(6)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)          // background blur
                .overlay {
                    Capsule().fill(
                        LinearGradient(
                            colors: [AppTheme.card.opacity(0.92),
                                     AppTheme.navEnd.opacity(0.80)],
                            startPoint: .topLeading,       // 135°
                            endPoint: .bottomTrailing)
                    )
                }
        }
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
        }
        .shadow(color: AppTheme.primary.opacity(0.28), radius: 16, x: 0, y: 10)
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.bottom, 8)
    }
}

#Preview {
    struct Demo: View {
        @State var tab: StudyverseTab = .home
        var body: some View {
            Color.clear
                .studyverseBackground()
                .safeAreaInset(edge: .bottom) { FloatingTabBar(selection: $tab) }
        }
    }
    return Demo()
}
