//
//  StudentHomeView.swift
//  StudyVerse
//
//  Branch: feature/student-home-ui
//  Owner: Fatima Hajeeh
//
//  Matches Figma: logo + bell (with unread badge), profile/XP card,
//  streak + coins tiles, leaderboard top 3, upcoming tasks
//  (horizontal cards, or the dashed "No tasks yet" empty state).
//

import SwiftUI

enum HomeRoute: Hashable {
    case leaderboard, progress, notifications
}

struct StudentHomeView: View {
    @StateObject private var viewModel: StudentHomeViewModel
    var onOpenPlan: () -> Void = {}

    init(viewModel: StudentHomeViewModel = StudentHomeViewModel(),
         onOpenPlan: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onOpenPlan = onOpenPlan
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topBar
                    profileCard
                    statTiles
                    leaderboardSection
                    upcomingSection
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.top, 25)                       // + safe area ≈ 84pt
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .studyverseBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .leaderboard:    LeaderboardView()
                case .progress:       ProgressTrackingView()
                case .notifications:  NotificationsView()
                }
            }
        }
        .feedbackBanner($viewModel.feedback)
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Image("StudyverseLogo")        // add the logo to Assets.xcassets
                .resizable().scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            Text("Studyverse")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            NavigationLink(value: HomeRoute.notifications) {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        if viewModel.unreadCount > 0 {
                            Text("\(min(viewModel.unreadCount, 99))")
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.primary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(hex: "#FFF1A8"), in: Capsule())   // (estimated) badge yellow
                                .offset(x: 6, y: -6)
                        }
                    }
            }
            .accessibilityLabel("Notifications")
            .accessibilityValue(viewModel.unreadCount == 0 ? "No unread" : "\(viewModel.unreadCount) unread")
        }
    }

    // MARK: Profile / XP

    private var profileCard: some View {
        NavigationLink(value: HomeRoute.progress) {
            HStack(spacing: 14) {
                Image(systemName: "person")
                    .font(.title2)
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 56, height: 56)
                    .background(AppTheme.cardInner, in: Circle())

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.username)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Chip(text: "Level \(viewModel.progress.xp.level)")
                    }
                    XPBar(progress: viewModel.progress.xp.levelProgress)
                    Text("\(viewModel.progress.xp.totalXP.formatted()) / \(viewModel.progress.xp.xpForNextLevel.formatted()) XP")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.username), level \(viewModel.progress.xp.level)")
        .accessibilityValue("\(viewModel.progress.xp.totalXP) of \(viewModel.progress.xp.xpForNextLevel) XP")
        .accessibilityHint("Opens your progress")
    }

    // MARK: Streak + coins

    private var statTiles: some View {
        HStack(spacing: 12) {
            statTile(icon: "flame", tint: AppTheme.streak, title: "Daily Streak",
                     value: "\(viewModel.progress.streak.current) \(viewModel.progress.streak.current == 1 ? "day" : "days")")
            statTile(icon: "bitcoinsign.circle", tint: AppTheme.coin, title: "Coins",
                     value: viewModel.progress.coins.balance.formatted())
        }
    }

    private func statTile(icon: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            IconBadge(systemImage: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(AppTheme.textSecondary)
                Text(value).font(.headline).foregroundStyle(AppTheme.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: Leaderboard preview

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: HomeRoute.leaderboard) {
                SectionHeader(title: "Leaderboard", actionTitle: "View all") {}
                    .allowsHitTesting(false)
            }
            .buttonStyle(.plain)

            if viewModel.topThree.isEmpty {
                EmptyStateCard(systemImage: "trophy", title: "No rankings yet",
                               message: "Earn XP to appear on the leaderboard.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.topThree.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 12) {
                            Text("\(index + 1)").font(.subheadline.bold()).frame(width: 20)
                            InitialsAvatar(name: entry.name)
                            Text(entry.name).font(.subheadline.weight(.medium)).lineLimit(1)
                            Spacer()
                            Text("\(entry.xp.formatted()) XP").font(.subheadline.bold())
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.vertical, 10)
                        .accessibilityElement(children: .combine)

                        if index < viewModel.topThree.count - 1 { Divider().overlay(Color.white.opacity(0.7)) }
                    }
                }
                .cardStyle(padding: 14)
            }
        }
    }

    // MARK: Upcoming tasks

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.upcomingTasks.isEmpty {
                SectionHeader(title: "Upcoming Tasks")
                HStack(spacing: 12) {
                    IconBadge(systemImage: "calendar.badge.checkmark")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No tasks yet").font(.headline).foregroundStyle(AppTheme.textPrimary)
                        Text("Create a study plan to get daily tasks.")
                            .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Button("Create Plan", action: onOpenPlan)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(minHeight: AppTheme.minTapSize)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(14)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .strokeBorder(AppTheme.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                }
            } else {
                SectionHeader(title: "Upcoming Tasks", actionTitle: "View plan", action: onOpenPlan)
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.upcomingTasks) { task in
                            UpcomingTaskCard(task: task, action: onOpenPlan)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
        }
    }
}

// MARK: - Task card

struct UpcomingTaskCard: View {
    let task: StudyTask
    var action: () -> Void = {}

    private var dayText: String {
        Calendar.current.isDateInToday(task.date) ? "Today"
        : Calendar.current.isDateInTomorrow(task.date) ? "Tomorrow"
        : task.date.formatted(.dateTime.weekday(.abbreviated))
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    IconBadge(systemImage: task.kind.systemImage)
                    Chip(text: dayText)
                    Spacer()
                    Text("+\(task.xpReward) XP").font(.subheadline.bold()).foregroundStyle(AppTheme.accent)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title).font(.headline).foregroundStyle(AppTheme.textPrimary)
                        Text(task.courseName ?? "\(task.kind.title) · \(task.minutes) min")
                            .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(AppTheme.primary)
                }
            }
            .frame(width: 270, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens your study plan")
    }
}

#Preview("With tasks") {
    StudentHomeView(viewModel: .init(progress: .preview,
                                     topThree: Array(LeaderboardEntry.samples.prefix(3)),
                                     upcomingTasks: StudyTask.samples, unreadCount: 3))
}

#Preview("No tasks yet") {
    StudentHomeView(viewModel: .init(progress: .preview,
                                     topThree: Array(LeaderboardEntry.samples.prefix(3)), unreadCount: 3))
}
