//
//  AccountManagementView.swift
//  StudyVerse
//
//  Branch: Account-Management-View
//  Owner: Maira Zaman
//
//  Edit username (format + "taken" check) and email, "Save Changes" with a
//  "Changes saved" toast, and a Change Password sheet (current, new,
//  confirm). After a password change the user is logged out and sees Log In
//  with "Password updated. Log in with your new password." (onPasswordChanged).
//

import SwiftUI

struct AccountManagementView: View {
    var onPasswordChanged: () -> Void = {}

    @State private var viewModel: AccountManagementViewModel
    @State private var showsPasswordSheet = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    private enum Field { case username, email }

    init(previewUser: UserModel? = nil, onPasswordChanged: @escaping () -> Void = {}) {
        self.onPasswordChanged = onPasswordChanged
        _viewModel = State(initialValue: AccountManagementViewModel(previewUser: previewUser))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Account", showsBack: true, onBack: { dismiss() })

            switch viewModel.state {
            case .loading:
                Spacer()
                ProgressView("Loading your account…").tint(AppTheme.primary)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            case .failed(let message):
                Spacer()
                VStack(spacing: AppTheme.spacing) {
                    Text("Couldn't load your account")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: "Try Again") { Task { await viewModel.load() } }
                }
                .padding(.horizontal, AppTheme.screenPadding)
                Spacer()
            case .loaded:
                form
            }
        }
        .disabled(viewModel.isSaving)
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { if viewModel.state != .loaded { await viewModel.load() } }
        .task(id: viewModel.username) {
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            await viewModel.checkUsernameAvailability()
        }
        .sheet(isPresented: $showsPasswordSheet) {
            ChangePasswordSheet {
                showsPasswordSheet = false
                try? AuthenticationService.shared.logOut()
                onPasswordChanged()
            }
            .presentationDetents([.large])
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    Text("Your details")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    InputField(label: "Username", placeholder: "e.g. maira_z",
                               text: $viewModel.username, error: viewModel.usernameError,
                               contentType: .username)
                        .focused($focus, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focus = .email }

                    VStack(alignment: .leading, spacing: 6) {
                        InputField(label: "Email", placeholder: "you@example.com",
                                   text: $viewModel.email, error: viewModel.emailError,
                                   keyboard: .emailAddress, contentType: .emailAddress)
                            .focused($focus, equals: .email)
                            .submitLabel(.done)

                        if let pending = viewModel.pendingEmail {
                            Label("Waiting for you to confirm \(pending)", systemImage: "envelope.badge")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(AppTheme.spacing)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))

                PrimaryButton(title: "Save Changes", isLoading: viewModel.isSaving) {
                    focus = nil
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.hasChanges)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Security")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Button {
                        showsPasswordSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primary)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text("Change password")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(minHeight: AppTheme.minTapSize)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(AppTheme.spacing)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                .padding(.top, 8)
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.vertical, AppTheme.spacing)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Change password sheet

struct ChangePasswordSheet: View {
    let onChanged: () -> Void

    @State private var viewModel = ChangePasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    private enum Field { case current, new, confirm }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Change password")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                HeaderCircleButton(systemImage: "xmark", label: "Close") { dismiss() }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 24)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    InputField(label: "Current password", text: $viewModel.current,
                               error: viewModel.currentError, isSecure: true, contentType: .password)
                        .focused($focus, equals: .current)
                        .submitLabel(.next)
                        .onSubmit { focus = .new }

                    InputField(label: "New password", placeholder: "At least 8 characters",
                               text: $viewModel.new, error: viewModel.newError,
                               isSecure: true, contentType: .newPassword)
                        .focused($focus, equals: .new)
                        .submitLabel(.next)
                        .onSubmit { focus = .confirm }

                    InputField(label: "Confirm new password", text: $viewModel.confirm,
                               error: viewModel.confirmError, isSecure: true, contentType: .newPassword)
                        .focused($focus, equals: .confirm)
                        .submitLabel(.go)
                        .onSubmit(submit)

                    Text("You'll be logged out and asked to log in with your new password.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)

                    PrimaryButton(title: "Update Password", isLoading: viewModel.isSaving, action: submit)
                        .padding(.top, 8)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.vertical, AppTheme.spacing)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .disabled(viewModel.isSaving)
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
    }

    private func submit() {
        focus = nil
        Task {
            if await viewModel.submit() { onChanged() }
        }
    }
}

#Preview {
    NavigationStack { AccountManagementView(previewUser: .preview) }
}
