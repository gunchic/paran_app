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
                            guard let userId = authManager.currentUser?.id else { return }
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
    private var imageSection: some View {
        PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
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
            } else {
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
        }
        .buttonStyle(.plain)
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
