import SwiftUI

/// 캐시 적용 이미지 뷰 — 앱 전체 이미지 로딩에 사용
/// ImageCache를 통해 메모리 + 디스크 캐싱 자동 처리
struct ParamImageView: View {
    let url: String?
    var contentMode: ContentMode = .fill
    var placeholder: Color = Color.surfaceContainer

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
                    .overlay {
                        if isLoading {
                            ProgressView().tint(.wave400)
                        }
                    }
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        image = nil
        guard let urlString = url, !urlString.isEmpty,
              let parsed = URL(string: urlString) else { return }
        isLoading = true
        defer { isLoading = false }
        image = try? await ImageCache.shared.image(for: parsed)
    }
}

// MARK: - 편의 뷰 팩토리

extension ParamImageView {

    /// 아바타 (원형)
    @ViewBuilder
    static func avatar(url: String?, size: CGFloat = 32) -> some View {
        ParamImageView(url: url, contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .background(Circle().fill(Color.surfaceContainer))
    }

    /// 피드 카드 썸네일 (풀너비, 280pt)
    @ViewBuilder
    static func thumbnail(url: String?) -> some View {
        ParamImageView(url: url, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .clipped()
    }

    /// 상세 이미지 (풀너비, fit)
    @ViewBuilder
    static func detail(url: String?) -> some View {
        ParamImageView(url: url, contentMode: .fit)
            .frame(maxWidth: .infinity)
    }

    /// 댓글 이미지
    @ViewBuilder
    static func comment(url: String?) -> some View {
        ParamImageView(url: url, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }
}
