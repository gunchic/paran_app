import SwiftUI
import Combine

// ─────────────────────────────────────────
// CommentsZone — 댓글 목록
// ─────────────────────────────────────────
struct CommentsZone: View {
    let momentID: String
    @ObservedObject var vm: CommentsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            if vm.isLoading && vm.comments.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
            } else if vm.comments.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(vm.comments) { comment in
                        CommentRow(comment: comment, userID: vm.userID)
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text("댓글")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.void)
            Spacer()
            let count = CommentStore.shared.count(for: momentID)
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 13))
                    .foregroundColor(.driftwood)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    private var emptyState: some View {
        Text("첫 댓글을 남겨보세요")
            .font(.system(size: 14))
            .foregroundColor(.driftwood)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
    }
}

// ─────────────────────────────────────────
// CommentRow
// ─────────────────────────────────────────
struct CommentRow: View {
    let comment: Comment
    let userID: String?

    @ObservedObject private var likeStore = CommentLikeStore.shared

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            avatarView
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Spacing.sm) {
                    Text(comment.authorNickname ?? "파람")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.void)
                    Text(comment.createdAt.relativeString)
                        .font(.system(size: 11))
                        .foregroundColor(.driftwood)
                }

                if let body = comment.body, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 14))
                        .foregroundColor(.void)
                        .lineSpacing(2)
                }

                if let imageUrl = comment.imageUrl, let url = URL(string: imageUrl) {
                    TappableImage(url: url, cornerRadius: Radius.md)
                        .frame(maxWidth: 220)
                        .frame(height: 140)
                        .clipped()
                        .cornerRadius(Radius.md)
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)

            // 좋아요 버튼
            likeButton
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // ── 좋아요 버튼 ──────────────────────────────
    private var likeButton: some View {
        let liked = likeStore.hasLiked(comment.id)
        let count = likeStore.count(for: comment.id)

        return VStack(spacing: 3) {
            Button(action: toggleLike) {
                Image(systemName: liked ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundColor(liked ? .signalRed : .driftwood)
                    .animation(.spring(response: 0.25), value: liked)
            }
            .buttonStyle(.plain)

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundColor(.driftwood)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: count)
            }
        }
        .frame(minWidth: 28)
    }

    private func toggleLike() {
        guard let userID else { return }
        let commentID = comment.id

        if likeStore.hasLiked(commentID) {
            likeStore.rollback(commentID: commentID)
            Task {
                do {
                    try await APIClient.shared.delete("/comments/\(commentID)/like", userID: userID)
                } catch {
                    likeStore.recordLike(commentID: commentID)
                }
            }
        } else {
            likeStore.recordLike(commentID: commentID)
            Task {
                do {
                    _ = try await APIClient.shared.post(
                        "/comments/\(commentID)/like",
                        body: EmptyBody(),
                        userID: userID
                    ) as EmptyResponse
                } catch {
                    likeStore.rollback(commentID: commentID)
                }
            }
        }
    }

    // ── 아바타 ───────────────────────────────────
    @ViewBuilder
    private var avatarView: some View {
        if let urlStr = comment.authorProfileImageUrl, let url = URL(string: urlStr) {
            CachedImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                avatarFallback
            }
        } else {
            avatarFallback
        }
    }

    private var avatarFallback: some View {
        ZStack {
            Color.redTint
            Text(String((comment.authorNickname ?? "P").prefix(1)))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.signalRed)
        }
    }
}

// ─────────────────────────────────────────
// CommentsViewModel
// ─────────────────────────────────────────
@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false

    var userID: String?

    func load(momentID: String, userID: String? = nil) async {
        self.userID = userID
        isLoading = true
        defer { isLoading = false }
        guard let result: [Comment] = try? await APIClient.shared.get(
            "/moments/\(momentID)/comments",
            userID: userID
        ) else { return }
        self.comments = result
        CommentStore.shared.setCount(result.count, for: momentID)
        CommentLikeStore.shared.seed(comments: result)
    }
}

// like POST 응답 디코딩용 더미
struct EmptyResponse: Decodable {}
