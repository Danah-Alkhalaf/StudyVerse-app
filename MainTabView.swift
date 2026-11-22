//
//  MainTabView.swift
//  StudyVerse
//
//  Branch: feature/student-home-ui
//  Owner: Fatima Hajeeh
//
//  Hosts the 4 student tabs and the floating pill navbar.
//  Courses and Chats are placeholders until Dana's and Malak's screens merge.
//

import SwiftUI

struct MainTabView: View {
    @State private var selection: StudyverseTab = .home

    var body: some View {
        ZStack {
            switch selection {
            case .home:
                StudentHomeView(onOpenPlan: { selection = .plan })
            case .courses:
                PlaceholderScreen(title: "Courses")          // Dana
            case .chats:
                PlaceholderScreen(title: "Chats")            // Malak
            case .plan:
                StudyPlanView()
            }
        }
        // Navbar floats above the content on every tab.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $selection)
        }
    }
}

private struct PlaceholderScreen: View {
    let title: String
    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: title)
            Spacer()
            EmptyStateCard(systemImage: "hammer", title: "Coming soon",
                           message: "This screen is being built by a teammate.")
                .padding(.horizontal, AppTheme.screenPadding)
            Spacer()
        }
        .studyverseBackground()
    }
}

#Preview { MainTabView() }
