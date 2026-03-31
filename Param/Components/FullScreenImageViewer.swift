import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────
// FullScreenImageViewer — 이미지 풀스크린 뷰어
// 기능: 탭으로 열기/닫기, 핀치 줌, 더블탭 줌, 스와이프 다운 닫기
// ─────────────────────────────────────────────────────────────

struct FullScreenImageViewer: View {
    let url: URL
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            // 배경
            Color.black
                .opacity(opacity)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    // 핀치 줌
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1.0 {
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    // 더블탭 줌
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3)) {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.5
                                lastScale = 2.5
                            }
                        }
                    }
                    // 드래그 (줌 시 이동 + 스와이프 다운 닫기)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                } else {
                                    // 스와이프 다운 → 배경 투명도 감소
                                    offset = CGSize(width: 0, height: value.translation.height)
                                    opacity = Double(max(0.3, 1.0 - abs(value.translation.height) / 300))
                                }
                            }
                            .onEnded { value in
                                if scale > 1.0 {
                                    lastOffset = offset
                                } else {
                                    // 150pt 이상 내리면 닫기
                                    if abs(value.translation.height) > 150 {
                                        dismiss()
                                    } else {
                                        withAnimation(.spring()) {
                                            offset = .zero
                                            opacity = 1.0
                                        }
                                    }
                                }
                            }
                    )
            } else {
                ProgressView()
                    .tint(.white)
                    .task { await loadImage() }
            }

            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(20)
                    }
                }
                Spacer()
            }
            .opacity(opacity)
        }
        .onAppear { Task { await loadImage() } }
    }

    // MARK: - Private

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.25)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }

    @MainActor
    private func loadImage() async {
        // 캐시에서 먼저 확인
        if let cached = ImageCache.shared.get(url) {
            image = cached
            return
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let downloaded = UIImage(data: data) else { return }
        ImageCache.shared.set(downloaded, for: url)
        image = downloaded
    }
}

// ─────────────────────────────────────────────────────────────
// TappableImage — 탭하면 FullScreenImageViewer 열리는 이미지
// 사용법: TappableImage(url: url)
// ─────────────────────────────────────────────────────────────

struct TappableImage: View {
    let url: URL
    var cornerRadius: CGFloat = 0

    @State private var showFullScreen = false

    var body: some View {
        CachedImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showFullScreen = true
                    }
                }
        } placeholder: {
            ZStack {
                Color(.systemGray6)
                ProgressView()
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenImageViewer(url: url, isPresented: $showFullScreen)
                .background(ClearBackground())
        }
    }
}

// fullScreenCover 배경 투명하게
struct ClearBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        Task { @MainActor in
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
