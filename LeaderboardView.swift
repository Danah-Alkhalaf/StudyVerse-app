//
//  LeaderboardView.swift
//  StudyVerse
//
//  Branch: feature/leaderboard
//  Owner: Fatima Hajeeh
//
//  Weekly / Monthly / All Time, podium for the top 3, list for 4-8,
//  and a pinned "You" row. Includes loading, empty and error states.
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel: LeaderboardViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: LeaderboardViewModel = LeaderboardViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Leaderboard", showsBack: true, onBack: { dismiss() })

            PeriodPicker(selection: $viewModel.period)
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.vertical, 8)

            switch viewModel.state {
            case .loading:
                Spacer(); ProgressView("Loading rankings…").tint(AppTheme.primary); Spacer()

            case .empty:
                Spacer()
                EmptyStateCard(systemImage: "trophy", title: "No rankings yet",
                               message: "Complete quizzes and quests to earn XP and appear here.")
                    .padding(.horizontal, AppTheme.screenPadding)
                Spacer()

            case .failed(let message):
                Spacer()
                EmptyStateCard(systemImage: "wifi.exclamationmark", title: "Something went wrong",
                               message: message) {
                    Button("Try Again") { Task { await viewModel.load() } }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, AppTheme.screenPadding)
                Spacer()

            case .loaded:
                ScrollView {
                    VStack(spacing: 16) {
                        Podium(entries: viewModel.podium)
                        if !viewModel.rest.isEmpty { rankedList }
                    }
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)

                if let rank = viewModel.myRank { youRow(rank: rank) }
            }
        }
        .studyverseBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }

    private var rankedList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.rest.enumerated()), id: \.element.id) { index, entry in
                HStack(spacing: 12) {
                    Text("\(index + 4)").font(.subheadline.bold()).frame(width: 24)
                    InitialsAvatar(name: entry.name)
                    Text(entry.name).font(.subheadline.weight(.medium)).lineLimit(1)
                    Spacer()
                    Text("\(entry.xp.formatted()) XP").font(.subheadline.bold())
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.vertical, 10)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Rank \(index + 4), \(entry.name), \(entry.xp) XP")

                if index < viewModel.rest.count - 1 { Divider().overlay(Color.white.opacity(0.7)) }
            }
        }
        .cardStyle(padding: 14)
    }

    private func youRow(rank: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)").font(.subheadline.bold()).frame(width: 24)
            Text("U").font(.footnote.bold()).foregroundStyle(AppTheme.primary)
                .frame(width: 40, height: 40).background(.white, in: Circle())
            Text("You").font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(viewModel.myXP.formatted()) XP").font(.subheadline.bold())
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(AppTheme.accent, lineWidth: 1.5) }
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your rank is \(rank), \(viewModel.myXP) XP")
    }
}

// MARK: - Period picker (white capsule on the selected segment)

private struct PeriodPicker: View {
    @Binding var selection: LeaderboardPeriod
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardPeriod.allCases) { period in
                Button { withAnimation(.snappy) { selection = period } } label: {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == period ? AppTheme.primary : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize)
                        .background {
                            if selection == period {
                                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white)
                                    .matchedGeometryEffect(id: "pick", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == period ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Podium (order on screen: 2nd, 1st, 3rd)

private struct Podium: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if entries.count > 1 { column(entries[1], rank: 2, height: 90) }
            if entries.count > 0 { column(entries[0], rank: 1, height: 130) }
            if entries.count > 2 { column(entries[2], rank: 3, height: 70) }
        }
    }

    private func column(_ entry: LeaderboardEntry, rank: Int, height: CGFloat) -> some View {
        VStack(spacing: 6) {
            if rank == 1 {
                Image(systemName: "crown.fill").foregroundStyle(AppTheme.coin)
            }
            InitialsAvatar(name: entry.name, size: rank == 1 ? .title3 : .subheadline)
                .scaleEffect(rank == 1 ? 1.3 : 1)
                .padding(.bottom, rank == 1 ? 6 : 0)
            Text(entry.name).font(.footnote.weight(.semibold)).lineLimit(1)
            Text("\(entry.xp.formatted()) XP").font(.caption).foregroundStyle(AppTheme.textSecondary)

            Text("\(rank)")
                .font(rank == 1 ? .largeTitle.bold() : .title.bold())
                .frame(maxWidth: .infinity, minHeight: height)
                .background(AppTheme.card, in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        }
        .foregroundStyle(AppTheme.textPrimary)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(entry.name), \(entry.xp) XP")
    }
}

#Preview {
    LeaderboardView(viewModel: LeaderboardViewModel(previewEntries: LeaderboardEntry.samples))
}
