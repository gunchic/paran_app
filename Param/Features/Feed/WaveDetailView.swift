import SwiftUI
import PhotosUI

/// 파동 상세 화면 — 댓글 + 나도그래
struct WaveDetailView: View {
    let item: WaveFeedItem

    @StateObject private var viewModel: WaveDetailViewModel
    @EnvironmentObject private var authManager: AuthManager

    init(item: WaveFeedItem) {
        self.item = item
        _viewModel = StateObject(wrappedValue: WaveDetailViewModel(item: item))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 파동 카드 (댓글 영역 숨김)
                    WaveCardView(
                        item: viewModel.item,
                        onHashtagTap: { _ in },
                        onResonateTap: { Task { await viewModel.toggleResonate() } },
                        hideTopComment: true
                    )

                    // 구분 영역
                    Color.surfaceLow
                        .frame(height: 8)

                    // 댓글 섹션
                    commentSection
                }
                .padding(.bottom, 80) // 입력바 공간
            }

            // 하단 댓글 입력바
            commentInputBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadComments()
            await viewModel.loadResonateState()
        }
    }

    // MARK: - 댓글 섹션
    private var commentSection: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            // 섹션 헤더
            Text("댓글 \(viewModel.comments.count)개")
                .font(.paramBody.weight(.semibold))
                .foregroundColor(.void)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

            if viewModel.isLoadingComments {
                ProgressView().tint(.ash).frame(maxWidth: .infinity).padding(Spacing.lg)
            } else if viewModel.comments.isEmpty {
                Text("첫 번째 댓글을 남겨보세요")
                    .captionStyle()
                    .foregroundColor(.ash)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.lg)
            } else {
                ForEach(viewModel.comments) { comment in
                    commentRow(comment)
                    Color.surfaceLow.frame(height: 1).opacity(0.5)
                }
            }
        }
    }

    // MARK: - 댓글 행
    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ParamImageView.avatar(url: comment.userAvatarUrl, size: 32)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(comment.userNickname ?? "알 수 없음")
                    .captionStyle()
                    .foregroundColor(.ash)

                Text(comment.body)
                    .bodyStyle()
                    .foregroundColor(.void)

                if let imgUrl = comment.imageUrl {
                    ParamImageView.comment(url: imgUrl)
                }

                // 시간 + 나도그래
                HStack(spacing: Spacing.md) {
                    Text(comment.createdAt.paramRelative)
                        .captionStyle()
                        .foregroundColor(.ash)

                    Button {
                        Task { await viewModel.toggleCommentResonate(comment: comment) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.resonatedCommentIds.contains(comment.id) ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundColor(viewModel.resonatedCommentIds.contains(comment.id) ? .wave400 : .ash)
                            let count = viewModel.commentResonateCounts[comment.id] ?? comment.resonateCount
                            if count > 0 {
                                Text("\(count)")
                                    .captionStyle()
                                    .foregroundColor(.ash)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - 댓글 입력바
    private var commentInputBar: some View {
        VStack(spacing: 0) {
            // 이미지 미리보기
            if let image = viewModel.selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xs, style: .continuous))

                    Spacer()

                    Button {
                        viewModel.selectedImage = nil
                        viewModel.selectedItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.ash)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
            }

            HStack(spacing: Spacing.sm) {
                // 이미지 첨부
                PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.ash)
                }
                .onChange(of: viewModel.selectedItem) { item in
                    Task { await viewModel.loadCommentImage(item) }
                }

                // 텍스트 입력
                TextField("댓글을 입력해주세요", text: $viewModel.commentText, axis: .vertical)
                    .font(.paramBody)
                    .foregroundColor(.void)
                    .lineLimit(1...4)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    .onChange(of: viewModel.commentText) { val in
                        if val.count > 200 { viewModel.commentText = String(val.prefix(200)) }
                    }

                // 등록 버튼
                Button {
                    guard let userId = authManager.currentUser?.id else { return }
                    Task { await viewModel.submitComment(userId: userId) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.canSubmitComment ? .wave400 : .ash)
                }
                .disabled(!viewModel.canSubmitComment || viewModel.isSubmittingComment)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color.surfaceLowest)
    }
}

// MARK: - ViewModel

@MainActor
final class WaveDetailViewModel: ObservableObject {
    @Published var item: WaveFeedItem
    @Published var comments: [Comment] = []
    @Published var isLoadingComments = false
    @Published var commentText: String = ""
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var isSubmittingComment = false
    @Published var resonatedCommentIds: Set<UUID> = []
    @Published var commentResonateCounts: [UUID: Int] = [:]

    var canSubmitComment: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
    }

    private let commentService = CommentService.shared

    init(item: WaveFeedItem) {
        self.item = item
    }

    func loadComments() async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        do {
            comments = try await commentService.fetchComments(momentId: item.id)
        } catch { /* 조용히 처리 */ }
    }

    func loadResonateState() async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
        do {
            let resonated = try await waveService.isResonated(momentId: item.id, userId: userId)
            item.isResonated = resonated
        } catch { }
    }

    func toggleResonate() async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
        // 낙관적 업데이트
        item.isResonated.toggle()
        item = item  // trigger update
        do {
            _ = try await waveService.toggleResonate(momentId: item.id, userId: userId)
        } catch {
            item.isResonated.toggle() // 롤백
            item = item
        }
    }

    func toggleCommentResonate(comment: Comment) async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
        let isCurrently = resonatedCommentIds.contains(comment.id)
        // 낙관적 업데이트
        if isCurrently {
            resonatedCommentIds.remove(comment.id)
            commentResonateCounts[comment.id] = (commentResonateCounts[comment.id] ?? comment.resonateCount) - 1
        } else {
            resonatedCommentIds.insert(comment.id)
            commentResonateCounts[comment.id] = (commentResonateCounts[comment.id] ?? comment.resonateCount) + 1
        }
        do {
            _ = try await commentService.toggleCommentResonate(commentId: comment.id, userId: userId)
        } catch {
            // 롤백
            if isCurrently {
                resonatedCommentIds.insert(comment.id)
            } else {
                resonatedCommentIds.remove(comment.id)
            }
            commentResonateCounts[comment.id] = comment.resonateCount
        }
    }

    func loadCommentImage(_ pickerItem: PhotosPickerItem?) async {
        guard let pickerItem else { return }
        if let data = try? await pickerItem.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
        }
    }

    func submitComment(userId: UUID) async {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        isSubmittingComment = true
        defer { isSubmittingComment = false }

        do {
            var imageUrl: String? = nil
            if let image = selectedImage {
                let commentId = UUID()
                imageUrl = try await ImageUploadService.shared.uploadCommentImage(
                    originalImage: image,
                    commentId: commentId
                )
            }
            let comment = try await commentService.createComment(
                momentId: item.id,
                userId: userId,
                text: text.isEmpty ? nil : text,
                imageUrl: imageUrl
            )
            comments.append(comment)
            commentText = ""
            selectedImage = nil
            selectedItem = nil
        } catch { /* 실패 처리 */ }
    }
}
