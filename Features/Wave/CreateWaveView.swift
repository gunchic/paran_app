import SwiftUI
import PhotosUI

/// C-02 파람 올리기 화면
struct CreateWaveView: View {
    var onSuccess: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateWaveViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @FocusState private var isTextFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        imageSection
                        textSection
                        hashtagSection
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("파람 올리기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .buttonStyle(.paramGhost)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isUploading {
                        ProgressView().tint(.wave400)
                    } else {
                        Button("올리기") {
                            let userId = authManager.currentUser!.id
                            Task { await viewModel.submit(userId: userId) }
                        }
                        .buttonStyle(.paramPrimary)
                        .disabled(!viewModel.canSubmit)
                    }
                }
            }
        }
        .onAppear { isTextFocused = true }
        .onChange(of: viewModel.isSubmitted) { submitted in
            if submitted {
                onSuccess?()
                dismiss()
            }
        }
        .onChange(of: viewModel.selectedItem) { item in
            Task { await viewModel.loadImage(item) }
        }
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 이미지 영역
    private let previewHeight: CGFloat = 240

    private var imageSection: some View {
        Group {
            if let image = viewModel.selectedImage {
                // 이미지 선택 상태: 드래그로 포커싱 조정
                selectedImagePreview(image: image)
            } else {
                // 미선택 상태: PhotosPicker 트리거
                PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "camera")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(.ash)
                        Text("사진 추가")
                            .captionStyle()
                            .foregroundColor(.ash)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(Color.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selectedImagePreview(image: UIImage) -> some View {
        let offsetY = CGFloat(0.5 - viewModel.imageOffsetY) * 80
        return ZStack(alignment: .bottom) {
            // 이미지 + 오프셋 프리뷰
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: previewHeight + 80)
                .offset(y: offsetY)
                .frame(height: previewHeight)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

            // 드래그 힌트
            Text("위아래로 드래그해서 위치 조정")
                .captionStyle()
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
                .padding(.bottom, Spacing.sm)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                viewModel.selectedImage = nil
                viewModel.selectedItem = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .buttonStyle(.plain)
            .padding(Spacing.sm)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let delta = value.translation.height / previewHeight
                    let newOffset = viewModel.dragBaseOffset + delta
                    viewModel.imageOffsetY = min(1.0, max(0.0, newOffset))
                }
                .onEnded { _ in
                    viewModel.dragBaseOffset = viewModel.imageOffsetY
                }
        )
    }

    // MARK: - 해시태그 섹션
    private var hashtagSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // 확정된 태그 배지
            if !viewModel.hashtags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(viewModel.hashtags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                    .captionStyle()
                                    .foregroundColor(.slate)
                                Button {
                                    viewModel.removeHashtag(tag)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.ash)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.surfaceContainer)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // 태그 입력창 (최대 5개 미만일 때만)
            if viewModel.hashtags.count < 5 {
                TextField("#태그 입력 후 스페이스", text: $viewModel.hashtagInput)
                    .font(.paramBody)
                    .foregroundColor(.void)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: viewModel.hashtagInput) { val in
                        // 스페이스 또는 개행 입력 시 태그 확정
                        if val.last == " " || val.last == "\n" {
                            viewModel.processHashtagInput()
                        }
                        // # 외 특수문자 제거
                        let filtered = val.unicodeScalars.filter {
                            CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "#_")).contains($0)
                        }
                        let clean = String(String.UnicodeScalarView(filtered))
                        if clean != val { viewModel.hashtagInput = clean }
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
        }
    }

    // MARK: - 텍스트 입력
    private var textSection: some View {
        VStack(alignment: .trailing, spacing: Spacing.xs) {
            TextEditor(text: $viewModel.body)
                .focused($isTextFocused)
                .foregroundColor(.void)
                .scrollContentBackground(.hidden)
                .background(Color.surfaceLowest)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .frame(minHeight: 140)
                .onChange(of: viewModel.body) { val in
                    if val.count > 100 {
                        viewModel.body = String(val.prefix(100))
                    }
                }
                .overlay(alignment: .topLeading) {
                    if viewModel.body.isEmpty {
                        Text("지금 어떤 파동을 느끼고 있나요?")
                            .bodyStyle()
                            .foregroundColor(.ash)
                            .padding(Spacing.sm)
                            .allowsHitTesting(false)
                    }
                }

            Text("\(viewModel.body.count)/100")
                .captionStyle()
                .foregroundColor(.ash)
        }
    }
}
