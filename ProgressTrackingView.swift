//
//  ProgressTrackingView.swift
//  StudyVerse
//
//  Branch: feature/progress-tracking
//  Owner: Fatima Hajeeh
//
//  Level card, study hours (stats + bar chart), 7-day streak, recent activity.
//  Includes loading and error states.
//

import SwiftUI
import Charts

struct ProgressTrackingView: View {
    @StateObject private var viewModel: ProgressViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProgressViewModel = ProgressViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Progress", showsBack: true, onBack: { dismiss() })

            switch viewModel.state {
            case .loading:
                Spacer(); ProgressView("Loading your progress…").tint(AppTheme.primary); Spacer()

            case .failed(let message):
                Spacer()
                EmptyStateCard(systemImage: "wifi.exclamationmark", title: "Something went wrong", message: message) {
                    Button("Try Again") { Task { await viewModel.load() } }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, AppTheme.screenPadding)
                Spacer()

            case .loaded:
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        levelCard
                        studyHoursCard
                        streakCard
                        recentActivity
                    }
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .studyverseBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }

    // MARK: Level

    private var levelCard: some View {
        let xp = viewModel.progress.xp
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Chip(text: "Level \(xp.level)")
                Spacer()
                Text("\(xp.totalXP.formatted()) / \(xp.xpForNextLevel.formatted()) XP")
                    .font(.headline).foregroundStyle(AppTheme.textPrimary)
            }
            XPBar(progress: xp.levelProgress)
            Text("\(viewModel.xpToNextLevel.formatted()) XP to reach Level \(xp.level + 1)")
                .font(.footnote).foregroundStyle(AppTheme.textSecondary)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: Study hours

    private var studyHoursCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Study Hours").font(.title3.bold())
                Spacer()
                Chip(text: "This week")
            }
            HStack(spacing: 8) {
                miniStat("Study time", viewModel.weekHoursText)
                miniStat("Weekly goal", "\(Int(viewModel.weeklyGoalHours)) h")
                miniStat("XP earned", "+\(viewModel.weekXP)", tint: AppTheme.accent)
            }

            Chart(viewModel.week) { day in
                BarMark(x: .value("Day", day.letter), y: .value("Hours", max(day.hours, 0.03)))
                    .foregroundStyle(AppTheme.accent.opacity(0.6))
                    .cornerRadius(8)
                    .annotation(position: .top) {
                        Text(day.minutes == 0 ? "0h" : String(format: "%gh", day.hours))
                            .font(.caption2).foregroundStyle(AppTheme.textSecondary)
                    }
            }
            .chartYAxis(.hidden)
            .frame(height: 120)
            .accessibilityLabel("Study hours this week")
            .accessibilityValue(viewModel.week.map { "\($0.date.formatted(.dateTime.weekday(.wide))) \($0.minutes) minutes" }.joined(separator: ", "))
        }
        .foregroundStyle(AppTheme.textPrimary)
        .cardStyle()
    }

    private func miniStat(_ title: String, _ value: String, tint: Color = AppTheme.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(AppTheme.textSecondary)
            Text(value).font(.headline).foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.cardInner, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Streak

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill").foregroundStyle(AppTheme.streak)
                Text("\(viewModel.progress.streak.current)-day streak").font(.title3.bold())
                Spacer()
                Text("Longest: \(viewModel.progress.streak.longest) days")
                    .font(.footnote).foregroundStyle(AppTheme.textSecondary)
            }
            HStack {
                ForEach(Array(viewModel.streakDays.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 4) {
                        Image(systemName: day.done ? "checkmark" : "")
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(day.done ? AppTheme.primary : AppTheme.cardInner, in: Circle())
                        Text(day.letter).font(.caption2).foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(viewModel.streakDays.filter(\.done).count) of 7 days studied this week")
        }
        .foregroundStyle(AppTheme.textPrimary)
        .cardStyle()
    }

    // MARK: Recent activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Activity")
            if viewModel.activity.isEmpty {
                EmptyStateCard(systemImage: "clock.arrow.circlepath", title: "No activity yet",
                               message: "Finish a quiz or quest and it will show up here.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.activity.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            IconBadge(systemImage: item.systemImage)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                                Text(item.subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Text("+\(item.xp) XP").font(.subheadline.bold()).foregroundStyle(AppTheme.accent)
                        }
                        .padding(.vertical, 8)
                        .accessibilityElement(children: .combine)

                        if index < viewModel.activity.count - 1 { Divider().overlay(Color.white.opacity(0.7)) }
                    }
                }
                .cardStyle(padding: 12)
            }
        }
    }
}

#Preview {
    ProgressTrackingView(viewModel: ProgressViewModel(previewData: true))
}
