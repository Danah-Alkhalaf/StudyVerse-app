//
//  ProfileView.swift
//  StudyVerse
//
//  Branch: Profile-View
//  Owner: Maira Zaman
//
//  Avatar circle (placeholder until AvatarCustomizationView), full name,
//  @username, "Edit avatar", and rows: Progress (Fatima's
//  ProgressTrackingView), Shop ("New" chip), Account, Settings, Report an
//  Issue. "Log out" asks "Log out?" first, then calls onLoggedOut so the
//  app shows WelcomeView again.
//
//  Must be shown inside a NavigationStack (the rows push screens onto it).
//

import SwiftUI

enum ProfileRoute: Hashable {
    case editAvatar
    case progress
    case shop
    case account
    case settings
    case reportIssue
}

struct ProfileView: View {
    var showsBack: Bool = false
    var onLoggedOut: () -> Void = {}
    /// After a password change the user is logged out; the app should show
    /// WelcomeView(startAt: [.login(passwordJustUpdated: true)]).
    var onPasswordChanged: () -> Void = {}

    @State private var viewModel: ProfileViewModel
    @State private var confirmsLogOut = false
    @Environment(\.dismiss) private var dismiss

    init(showsBack: Bool = false,
         previewUser: UserModel? = nil,
         onLoggedOut: @escaping () -> Void = {},
         onPasswordChanged: @escaping () -> Void = {}) {
        self.showsBack = showsBack
        self.onLoggedOut = onLoggedOut
        self.onPasswordChanged = onPasswordChanged
        _viewModel = State(initialValue: ProfileViewModel(previewUser: previewUser))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Profile", showsBack: showsBack, onBack: { dismiss() })

            switch viewModel.state {
            case .loading:
                Spacer()
                ProgressView("Loading your profile…")
                    .tint(AppTheme.primary)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()

            case .failed(let message):
                ProfileErrorState(message: message) {
                    Task { await viewModel.load() }
                }

            case .loaded(let user):
                ScrollView {
                    VStack(spacing: AppTheme.spacing) {
                        identity(user)
                        rows
                        SecondaryButton(title: "Log out", isOutline: true) {
                            confirmsLogOut = true
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.vertical, AppTheme.spacing)
                }
                .refreshable { await viewModel.load() }
            }
        }
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { if viewModel.user == nil { await viewModel.load() } }
        .alert("Log out?", isPresented: $confirmsLogOut) {
            Button("Cancel", role: .cancel) {}
            Button("Log out", role: .destructive) {
                if viewModel.logOut() { onLoggedOut() }
            }
        } message: {
            Text("You'll need to log in again to use StudyVerse.")
        }
        .navigationDestination(for: ProfileRoute.self) { route in
            destination(for: route)
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Avatar, name, username

    private func identity(_ user: UserModel) -> some View {
        VStack(spacing: 8) {
            AvatarCircle(name: user.fullName)

            Text(user.fullName)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("@\(user.username)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            NavigationLink(value: ProfileRoute.editAvatar) {
                Label("Edit avatar", systemImage: "paintbrush.pointed.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 16)
                    .frame(minHeight: AppTheme.minTapSize)
                    .background(AppTheme.card, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: Rows

    private var rows: some View {
        VStack(spacing: 0) {
            ProfileRow(route: .progress, title: "Progress", icon: "chart.line.uptrend.xyaxis")
            RowDivider()
            ProfileRow(route: .shop, title: "Shop", icon: "bag.fill", showsNewChip: true)
            RowDivider()
            ProfileRow(route: .account, title: "Account", icon: "person.crop.circle")
            RowDivider()
            ProfileRow(route: .settings, title: "Settings", icon: "gearshape.fill")
            RowDivider()
            ProfileRow(route: .reportIssue, title: "Report an Issue", icon: "exclamationmark.bubble.fill")
        }
        .padding(.vertical, 4)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }

    @ViewBuilder
    private func destination(for route: ProfileRoute) -> some View {
        switch route {
        case .progress:
            ProgressTrackingView()                              // Fatima's screen
        case .editAvatar:
            ComingSoonScreen(title: "Edit Avatar")              // AvatarCustomizationView (28 Nov)
        case .shop:
            ComingSoonScreen(title: "Shop")                     // ShopView (1 Dec)
        case .account:
            AccountManagementView(onPasswordChanged: onPasswordChanged)
        case .settings:
            SettingsView()
        case .reportIssue:
            ComingSoonScreen(title: "Report an Issue")          // ReportIssueView (next branch)
        }
    }
}

// MARK: - Pieces

/// Big round avatar. Shows initials until the real avatar (AvatarConfig)
/// is drawn by AvatarCustomizationView.
struct AvatarCircle: View {
    let name: String
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 104

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    var body: some View {
        Text(initials.isEmpty ? "?" : initials)
            .font(.largeTitle.bold())
            .foregroundStyle(AppTheme.primary)
            .frame(width: size, height: size)
            .background(AppTheme.navEnd, in: Circle())
            .overlay { Circle().strokeBorder(Color.white, lineWidth: 4) }
            .shadow(color: AppTheme.primary.opacity(0.15), radius: 12, y: 6)
            .accessibilityHidden(true)
    }
}

private struct ProfileRow: View {
    let route: ProfileRoute
    let title: String
    let icon: String
    var showsNewChip = false

    var body: some View {
        NavigationLink(value: route) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                if showsNewChip {
                    Text("New")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.chipYellow, in: Capsule())
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.spacing)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showsNewChip ? "\(title), new" : title)
    }
}

private struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.primary.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, AppTheme.spacing + 52)
    }
}

private struct ProfileErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.error)
            Text("Couldn't load your profile")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Try Again", action: onRetry)
                .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, AppTheme.screenPadding)
    }
}

// MARK: - Temporary placeholder

/// Shown for screens that are not built yet (Edit Avatar, Shop, ...).
struct ComingSoonScreen: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: title, showsBack: true, onBack: { dismiss() })
            Spacer()
            Image(systemName: "hammer.fill")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.primary.opacity(0.5))
            Text("Coming soon")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 8)
            Spacer()
        }
        .studyverseBackground()
    }
}

#Preview {
    NavigationStack {
        ProfileView(previewUser: .preview)
    }
}
