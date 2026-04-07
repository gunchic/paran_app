import SwiftUI

/// CR-02 크루 생성 화면
struct CrewCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = CrewCreateViewModel()
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // 크루 이름
                        nameSection

                        // 크루 타입
                        typeSection

                        // 설명 (선택)
                        descriptionSection
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("크루 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .buttonStyle(.paramGhost)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isCreating {
                        ProgressView().tint(.wave400)
                    } else {
                        Button("만들기") {
                            let userId = authManager.currentUser!.id
                            Task { await viewModel.createCrew(userId: userId) }
                        }
                        .buttonStyle(.paramPrimary)
                        .disabled(!viewModel.canCreate)
                    }
                }
            }
        }
        .onAppear { isNameFocused = true }
        .onChange(of: viewModel.createdCrew) { crew in
            if crew != nil { dismiss() }
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

    // MARK: - 크루 이름 섹션
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("크루 이름")
                .captionStyle()
                .foregroundColor(.ash)

            TextField("선점할 단어 또는 문장", text: $viewModel.crewName)
                .focused($isNameFocused)
                .foregroundColor(.void)
                .autocorrectionDisabled()
                .paramInput(isFocused: isNameFocused)

            // 이름 상태 피드백
            HStack(spacing: Spacing.xs) {
                if viewModel.isCheckingName {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.ash)
                    Text("확인 중...")
                        .captionStyle()
                        .foregroundColor(.ash)
                } else if viewModel.isNameTaken {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text("이미 사용 중인 이름이에요")
                        .captionStyle()
                        .foregroundColor(.red)
                } else if !viewModel.crewName.trimmingCharacters(in: .whitespaces).isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.wave600)
                    Text("사용 가능한 이름이에요")
                        .captionStyle()
                        .foregroundColor(.wave600)
                }
            }
            .frame(height: 20)
        }
    }

    // MARK: - 크루 타입 섹션
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("크루 타입")
                .captionStyle()
                .foregroundColor(.ash)

            HStack(spacing: Spacing.sm) {
                typeButton(label: "키워드", value: "keyword")
                typeButton(label: "감정", value: "emotion")
            }

            Text(viewModel.crewType == "keyword"
                 ? "특정 키워드로 묶이는 크루예요"
                 : "특정 감정이나 상태로 묶이는 크루예요")
                .captionStyle()
                .foregroundColor(.ash)
        }
    }

    private func typeButton(label: String, value: String) -> some View {
        let isSelected = viewModel.crewType == value
        return Button {
            viewModel.crewType = value
        } label: {
            Text(label)
                .captionStyle()
                .foregroundColor(isSelected ? .surfaceLowest : .void)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.wave800 : Color.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 설명 섹션
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("설명 (선택)")
                .captionStyle()
                .foregroundColor(.ash)

            TextEditor(text: $viewModel.description)
                .foregroundColor(.void)
                .scrollContentBackground(.hidden)
                .background(Color.surfaceHighest)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .frame(minHeight: 100)
        }
    }
}
