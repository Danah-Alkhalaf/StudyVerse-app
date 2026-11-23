//
//  TutorVerificationView.swift
//  StudyVerse
//
//  Branch: Tutor-Verification
//  Owner: Maira Zaman
//
//  Shown to a new tutor right after sign up. They enter institution,
//  department, staff ID, work email, the courses they teach (chips), pick a
//  proof of employment (photo or PDF) and tick the confirm box.
//  After it is sent, WelcomeView shows WaitingApprovalView.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct TutorVerificationView: View {
    var onSubmitted: () -> Void = {}

    @State private var viewModel = TutorVerificationViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var showsPDFPicker = false
    @FocusState private var focus: Field?

    private enum Field { case institution, department, staffId, workEmail, course }

    var body: some View {
        VStack(spacing: 0) {
            // No back button: the account already exists, the tutor finishes here.
            ScreenHeader(title: "Tutor Verification")

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Verify your employment")
                            .font(.largeTitle.bold())
                        Text("An admin checks these details before your tutor account is approved.")
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .foregroundStyle(AppTheme.textPrimary)

                    detailsFields
                    coursesSection
                    proofSection
                    confirmBox

                    PrimaryButton(title: "Submit for Review",
                                  isLoading: viewModel.isSubmitting,
                                  action: submit)
                        .padding(.top, 8)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.vertical, AppTheme.spacing)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .disabled(viewModel.isSubmitting)
        .studyverseBackground()
        .feedbackBanner($viewModel.banner)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                await viewModel.loadPhoto(item)
                photoItem = nil
            }
        }
        .fileImporter(isPresented: $showsPDFPicker, allowedContentTypes: [.pdf]) { result in
            viewModel.loadPDF(result)
        }
    }

    // MARK: Details

    private var detailsFields: some View {
        VStack(spacing: AppTheme.spacing) {
            InputField(label: "Institution", placeholder: "e.g. Bahrain Polytechnic",
                       text: $viewModel.institution, error: viewModel.institutionError,
                       contentType: .organizationName, capitalization: .words)
                .focused($focus, equals: .institution)
                .submitLabel(.next)
                .onSubmit { focus = .department }

            InputField(label: "Department", placeholder: "e.g. ICT",
                       text: $viewModel.department, error: viewModel.departmentError,
                       capitalization: .words)
                .focused($focus, equals: .department)
                .submitLabel(.next)
                .onSubmit { focus = .staffId }

            InputField(label: "Staff ID", placeholder: "Your staff number",
                       text: $viewModel.staffId, error: viewModel.staffIdError,
                       capitalization: .characters)
                .focused($focus, equals: .staffId)
                .submitLabel(.next)
                .onSubmit { focus = .workEmail }

            InputField(label: "Work email", placeholder: "name@institution.edu",
                       text: $viewModel.workEmail, error: viewModel.workEmailError,
                       keyboard: .emailAddress, contentType: .emailAddress)
                .focused($focus, equals: .workEmail)
                .submitLabel(.next)
                .onSubmit { focus = .course }
        }
    }

    // MARK: Courses (chips + add)

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                InputField(label: "Courses you teach", placeholder: "e.g. IT8108",
                           text: $viewModel.newCourse,
                           error: viewModel.coursesError == nil ? nil : "",
                           capitalization: .characters)
                    .focused($focus, equals: .course)
                    .submitLabel(.done)
                    .onSubmit { viewModel.addCourse() }

                Button {
                    viewModel.addCourse()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: AppTheme.inputHeight, height: AppTheme.inputHeight)
                        .background(AppTheme.primary,
                                    in: RoundedRectangle(cornerRadius: AppTheme.inputRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add course")
            }

            if !viewModel.courses.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.courses, id: \.self) { course in
                        CourseChip(title: course) { viewModel.removeCourse(course) }
                    }
                }
            }

            if let error = viewModel.coursesError {
                ErrorText(error)
            }
        }
    }

    // MARK: Proof of employment

    private var proofSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Proof of employment")
                .font(.footnote.bold())
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                if let proof = viewModel.proof {
                    HStack(spacing: 12) {
                        Image(systemName: proof.kind == .pdf ? "doc.richtext.fill" : "photo.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: AppTheme.minTapSize, height: AppTheme.minTapSize)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(proof.fileName)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(proof.sizeText)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        Spacer(minLength: 0)
                        Button(action: viewModel.removeProof) {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                                .frame(width: AppTheme.minTapSize, height: AppTheme.minTapSize)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove file")
                    }
                } else if viewModel.isProcessingFile {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Preparing file…")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize)
                } else {
                    Text("Staff card, contract or letter from your institution. Photo or PDF, under 500 KB.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                HStack(spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        PickerLabel(title: "Photo", icon: "photo.on.rectangle")
                    }
                    Button { showsPDFPicker = true } label: {
                        PickerLabel(title: "PDF", icon: "doc.fill")
                    }
                    .buttonStyle(.plain)
                }
                .disabled(viewModel.isProcessingFile)
            }
            .padding(AppTheme.spacing)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                if viewModel.proofError != nil {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .strokeBorder(AppTheme.error, lineWidth: 1.2)
                }
            }

            if let error = viewModel.proofError {
                ErrorText(error)
            }
        }
    }

    // MARK: Confirm checkbox

    private var confirmBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                viewModel.isConfirmed.toggle()
                if viewModel.isConfirmed { viewModel.confirmError = nil }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: viewModel.isConfirmed ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(viewModel.confirmError == nil ? AppTheme.primary : AppTheme.error)
                    Text("I confirm these details are correct and that I work at this institution.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                .frame(minHeight: AppTheme.minTapSize)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(viewModel.isConfirmed ? .isSelected : [])

            if let error = viewModel.confirmError {
                ErrorText(error)
            }
        }
    }

    private func submit() {
        focus = nil
        Task {
            if await viewModel.submit() { onSubmitted() }
        }
    }
}

// MARK: - Small pieces

private struct CourseChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(title)")
        }
        .foregroundStyle(AppTheme.primary)
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(AppTheme.inputBorder, in: Capsule())
    }
}

private struct PickerLabel: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize)
            .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.inputRadius, style: .continuous))
    }
}

/// Red message with alert icon, same look as InputField's error.
private struct ErrorText: View {
    let message: String
    init(_ message: String) { self.message = message }

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(AppTheme.error)
    }
}

// MARK: - Flow layout (chips wrap onto new lines)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row { var indices: [Int] = []; var y: CGFloat = 0; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > maxWidth, !rows[rows.count - 1].indices.isEmpty {
                let last = rows[rows.count - 1]
                rows.append(Row(y: last.y + last.height + spacing))
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

#Preview {
    NavigationStack { TutorVerificationView() }
}
