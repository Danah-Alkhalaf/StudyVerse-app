//
//  ReportIssueView.swift
//  StudyVerse
//
//  Branch: Report-Issue-View
//  Owner: Maira Zaman
//
//  "What's the problem?" radio list (with Other + text), description,
//  optional screenshot, "Send Report", then a "Report sent" popup.
//

import SwiftUI
import PhotosUI

struct ReportIssueView: View {
    @State private var viewModel = ReportIssueViewModel()
    @State private var photoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    private enum Field { case other, description }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Report an Issue", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    Text("Tell us what went wrong and we'll look into it.")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)

                    categorySection
                    descriptionSection
                    screenshotSection

                    PrimaryButton(title: "Send Report", isLoading: viewModel.isSubmitting) {
                        focus = nil
                        Task { await viewModel.submit() }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.vertical, AppTheme.spacing)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .disabled(viewModel.isSubmitting || viewModel.showsSentPopup)
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                await viewModel.loadScreenshot(item)
                photoItem = nil
            }
        }
        .overlay {
            if viewModel.showsSentPopup {
                ReportSentPopup { dismiss() }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showsSentPopup)
    }

    // MARK: Category (radio list)

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's the problem?")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 0) {
                ForEach(ReportCategory.allCases) { option in
                    RadioRow(title: option.title, isSelected: viewModel.category == option) {
                        withAnimation(.easeInOut(duration: 0.2)) { viewModel.category = option }
                        if option == .other { focus = .other }
                    }
                }
            }
            .padding(.vertical, 4)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                if viewModel.categoryError != nil {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .strokeBorder(AppTheme.error, lineWidth: 1.2)
                }
            }

            if let error = viewModel.categoryError { ErrorLine(error) }

            if viewModel.category == .other {
                InputField(label: "Other", placeholder: "What is it about?",
                           text: $viewModel.otherText, error: viewModel.otherError,
                           capitalization: .sentences)
                    .focused($focus, equals: .other)
                    .submitLabel(.next)
                    .onSubmit { focus = .description }
                    .padding(.top, 4)
            }
        }
    }

    // MARK: Description (multi-line, styled like InputField)

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description")
                .font(.footnote.bold())
                .foregroundStyle(AppTheme.textPrimary)

            ZStack(alignment: .topLeading) {
                if viewModel.description.isEmpty {
                    Text("What happened? What were you doing when it happened?")
                        .font(.body)
                        .foregroundStyle(Color(uiColor: .placeholderText))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $viewModel.description)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .focused($focus, equals: .description)
                    .accessibilityLabel("Description")
            }
            .frame(minHeight: 130)
            .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.inputRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.inputRadius, style: .continuous)
                    .strokeBorder(viewModel.descriptionError == nil ? AppTheme.inputBorder : AppTheme.error,
                                  lineWidth: 1.2)
            }

            if let error = viewModel.descriptionError {
                ErrorLine(error)
            } else {
                Text("At least \(ReportIssueViewModel.minDescriptionLength) characters.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: Screenshot (optional)

    private var screenshotSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screenshot (optional)")
                .font(.footnote.bold())
                .foregroundStyle(AppTheme.textPrimary)

            Group {
                if let shot = viewModel.screenshot, let image = UIImage(data: shot.data) {
                    HStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screenshot added")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(shot.sizeText)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                        Button(action: viewModel.removeScreenshot) {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                                .frame(width: AppTheme.minTapSize, height: AppTheme.minTapSize)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove screenshot")
                    }
                } else if viewModel.isProcessingImage {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Preparing screenshot…")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                } else {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Add a screenshot", systemImage: "photo.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Color.white.opacity(0.7),
                                        in: RoundedRectangle(cornerRadius: AppTheme.inputRadius, style: .continuous))
                    }
                }
            }
            .padding(12)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))

            if let error = viewModel.screenshotError { ErrorLine(error) }
        }
    }
}

// MARK: - Pieces

private struct RadioRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.primary)
                Text(title)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.spacing)
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct ErrorLine: View {
    let message: String
    init(_ message: String) { self.message = message }

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(AppTheme.error)
    }
}

/// Centered "Report sent" card over a dimmed screen.
private struct ReportSentPopup: View {
    let onDone: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 72

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(width: iconSize, height: iconSize)
                    .background(AppTheme.success, in: Circle())
                    .accessibilityHidden(true)

                Text("Report sent")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("Thanks for letting us know. Our team will look into it.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: "Done", action: onDone)
                    .padding(.top, 8)
            }
            .padding(24)
            .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .shadow(color: AppTheme.primary.opacity(0.2), radius: 24, y: 12)
            .padding(.horizontal, AppTheme.screenPadding + 8)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }
}

#Preview {
    NavigationStack { ReportIssueView() }
}
