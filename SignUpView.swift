//
//  SignUpView.swift
//  StudyVerse
//
//  Branch: Student-Registration
//  Owner: Maira Zaman
//
//  Create an account as a Student or a Tutor.
//  - Students go straight into the app after sign up.
//  - Tutors see an approval notice, the button says "Continue", and after
//    the account is created they go on to Tutor Verification.
//

import SwiftUI

struct SignUpView: View {
    var onStudentSignedUp: (UserModel) -> Void = { _ in }
    var onTutorSignedUp: (UserModel) -> Void = { _ in }
    var onLogIn: () -> Void = {}

    @State private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    private enum Field { case fullName, username, email, password }

    var body: some View {
        VStack(spacing: 0) {
            AuthBackHeader(onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create your account")
                            .font(.largeTitle.bold())
                        Text("Join StudyVerse and start levelling up.")
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .foregroundStyle(AppTheme.textPrimary)

                    RoleSwitch(role: $viewModel.role)

                    if viewModel.role == .tutor {
                        TutorApprovalNotice()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    InputField(label: "Full name",
                               placeholder: "e.g. Maira Zaman",
                               text: $viewModel.fullName,
                               error: viewModel.fullNameError,
                               contentType: .name,
                               capitalization: .words)
                        .focused($focus, equals: .fullName)
                        .submitLabel(.next)
                        .onSubmit { focus = .username }

                    InputField(label: "Username",
                               placeholder: "e.g. maira_z",
                               text: $viewModel.username,
                               error: viewModel.usernameError,
                               contentType: .username)
                        .focused($focus, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focus = .email }

                    InputField(label: "Email",
                               placeholder: "you@example.com",
                               text: $viewModel.email,
                               error: viewModel.emailError,
                               keyboard: .emailAddress,
                               contentType: .emailAddress)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }

                    InputField(label: "Password",
                               placeholder: "At least 8 characters",
                               text: $viewModel.password,
                               error: viewModel.passwordError,
                               isSecure: true,
                               contentType: .newPassword)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit(signUp)

                    Text("By signing up you agree to the Terms and Privacy Policy.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    PrimaryButton(title: viewModel.buttonTitle,
                                  isLoading: viewModel.isLoading,
                                  action: signUp)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(AppTheme.textSecondary)
                        Button("Log In", action: onLogIn)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.primary)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.vertical, AppTheme.spacing)
                .animation(.easeInOut(duration: 0.25), value: viewModel.role)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .disabled(viewModel.isLoading)
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        // Check "username taken" half a second after the user stops typing.
        .task(id: viewModel.username) {
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            await viewModel.checkUsernameAvailability()
        }
    }

    private func signUp() {
        focus = nil
        Task {
            guard let user = await viewModel.signUp() else { return }
            if user.role == .tutor {
                onTutorSignedUp(user)
            } else {
                onStudentSignedUp(user)
            }
        }
    }
}

// MARK: - Student | Tutor switch

private struct RoleSwitch: View {
    @Binding var role: UserRole

    var body: some View {
        HStack(spacing: 4) {
            option(.student, title: "Student", icon: "graduationcap.fill")
            option(.tutor, title: "Tutor", icon: "person.crop.rectangle.fill")
        }
        .padding(4)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Account type")
    }

    private func option(_ value: UserRole, title: String, icon: String) -> some View {
        let isSelected = role == value
        return Button {
            role = value
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.primary)
                .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppTheme.buttonRadius - 4, style: .continuous)
                            .fill(AppTheme.primary)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Tutor approval notice

private struct TutorApprovalNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hourglass")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
                .frame(width: AppTheme.minTapSize, height: AppTheme.minTapSize)
                .background(AppTheme.chipYellow, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Tutor accounts need approval")
                    .font(.subheadline.weight(.semibold))
                Text("Next, you'll verify your employment. An admin will review it before you can log in as a tutor.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(AppTheme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { SignUpView() }
}
