import SwiftUI
import PhotosUI

// ─────────────────────────────────────────
// CommentInputSheet — 댓글 입력 시트
// ─────────────────────────────────────────
struct CommentInputSheet: View {
    let momentID: String
    var onSuccess: (() -> Void)?

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var text   = ""
    @State private var image: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil) && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 이미지 미리보기
                if let image {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(Radius.md)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)

                        Button(action: { self.image = nil; selectedItem = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .padding(.top, Spacing.md + 8)
                        .padding(.trailing, Spacing.lg + 8)
                    }
                }

                // 텍스트 입력
                TextField("댓글을 입력하세요…", text: $text, axis: .vertical)
                    .lineLimit(4...8)
                    .padding(Spacing.lg)
                    .font(.system(size: 16))

                Divider()

                // 하단 툴바 (사진 첨부)
                HStack {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20))
                            .foregroundColor(.driftwood)
                    }
                    .onChange(of: selectedItem) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                self.image = uiImage
                            }
                        }
                    }

                    Spacer()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("댓글")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.driftwood)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("등록") { submit() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(canSubmit ? .signalRed : .driftwood)
                        .disabled(!canSubmit)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func submit() {
        guard canSubmit, let userID = appState.currentUserID else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                var imageUrl: String?
                if let img = image {
                    imageUrl = try await APIClient.shared.uploadImage(img, userID: userID)
                }

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let req = CreateCommentRequest(
                    body: trimmed.isEmpty ? nil : trimmed,
                    imageUrl: imageUrl
                )
                let _: Comment = try await APIClient.shared.post(
                    "/moments/\(momentID)/comments",
                    body: req,
                    userID: userID
                )
                onSuccess?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
