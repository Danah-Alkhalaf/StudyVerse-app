//
//  WaitingApprovalView.swift
//  StudyVerse
//
//  Branch: Tutor-Verification
//  Owner: Maira Zaman
//
//  Shown after a tutor submits verification. Three steps:
//  1. Account created  (done)
//  2. Details sent     (done)
//  3. Admin review     (in progress)
//  "Back to Log In" logs the tutor out; "Edit Details" goes back to the form.
//

import SwiftUI

struct WaitingApprovalView: View {
    var onBackToLogIn: () -> Void = {}
    var onEditDetails: () -> Void = {}

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 96

    private struct Step: Identifiable {
        let id: Int
        let title: String
        let detail: String
        let isDone: Bool
    }

    private let steps = [
        Step(id: 1, title: "Account created", detail: "Your tutor account is set up.", isDone: true),
        Step(id: 2, title: "Details submitted", detail: "We received your details and proof of employment.", isDone: true),
        Step(id: 3, title: "Admin review", detail: "An admin is checking your details. You can log in once you're approved.", isDone: false),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Tutor Verification")

            ScrollView {
                VStack(spacing: AppTheme.spacing) {
                    Image(systemName: "hourglass")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(AppTheme.primary)
                        .padding(iconSize * 0.25)
                        .frame(width: iconSize, height: iconSize)
                        .background(AppTheme.chipYellow, in: Circle())
                        .accessibilityHidden(true)
                        .padding(.top, 24)

                    Text("Waiting for approval")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Your tutor account is waiting for admin approval.")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(steps) { step in
                            StepRow(number: step.id, title: step.title, detail: step.detail,
                                    isDone: step.isDone, isLast: step.id == steps.count)
                        }
                    }
                    .padding(AppTheme.spacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))

                    VStack(spacing: 12) {
                        PrimaryButton(title: "Back to Log In", action: onBackToLogIn)
                        SecondaryButton(title: "Edit Details", action: onEditDetails)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.vertical, AppTheme.spacing)
            }
        }
        .studyverseBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct StepRow: View {
    let number: Int
    let title: String
    let detail: String
    let isDone: Bool
    let isLast: Bool

    @ScaledMetric(relativeTo: .headline) private var circle: CGFloat = 32

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(isDone ? AppTheme.primary : Color.white)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(number)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }
                .frame(width: circle, height: circle)
                .overlay { Circle().strokeBorder(AppTheme.primary, lineWidth: isDone ? 0 : 1.5) }

                if !isLast {
                    Rectangle()
                        .fill(AppTheme.primary.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 20, maxHeight: .infinity)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                if !isDone {
                    Text("In progress")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.chipYellow, in: Capsule())
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number), \(title), \(isDone ? "done" : "in progress"). \(detail)")
    }
}

#Preview {
    NavigationStack { WaitingApprovalView() }
}
