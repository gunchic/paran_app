import SwiftUI

/// M-01 프로필 편집 시트
struct ProfileEditView: View {
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager

    @State private var nickname: String = ""
    @State private var nickStatus: NickStatus = .empty
    @State private var avatars: [Avatar] = []
    @State private var selectedAvatar: Avatar? = nil
    @State private var isLoadingAvatars: Bool = true
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var nickCheckTask: Task<Void, Never>? = nil
    @FocusState private var isNickFocused: Bool

    // ProfileSetupView와 동일한 폴백 아바타
    private static let fallbackAvatars: [Avatar] = [
        Avatar(id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!, name: "파랑이", imageUrl: "", sortOrder: 0, isActive: true),
        Avatar(id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!, name: "초록이", imageUrl: "", sortOrder: 1, isActive: true),
        Avatar(id: UUID(uuidString: "00000001-0000-0000-0000-000000000003")!, name: "노랑이", imageUrl: "", sortOrder: 2, isActive: true),
        Avatar(id: UUID(uuidString: "00000001-0000-0000-0000-000000000004")!, name: "빨강이", imageUrl: "", sortOrder: 3, isActive: true),
        Avatar(id: UUID(uuidString: "00000001-0000-0000-0000-000000000005")!, name: "보라이", imageUrl: "", sortOrder: 4, isActive: true),
        Avatar(id: UUID(uuidString: "00000001-0000-0000-0000-000000000006")!, name: "주황이", imageUrl: "", sortOrder: 5, isActive: true),
        Avatar(id: UUID(uuidString: "00000001-0000-0000-0000-000000000007")!, name: "하늘이", imageUrl: "", sortOrder: 6, isActive: true),
        Avatar(id: UUID(uuidString: "00000001-0000-0000-0000-000000000008")!, name: "분홍이", imageUrl: "", sortOrder: 7, isActive: true),
    ]

    private static let fallbackColors: [Color] = [
        Color(red: 0.49, green: 0.72, blue: 0.79),
        Color(red: 0.47, green: 0.72, blue: 0.54),
        Color(red: 0.95, green: 0.80, blue: 0.40),
        Color(red: 0.90, green: 0.45, blue: 0.45),
        Color(red: 0.75, green: 0.63, blue: 0.84),
        Color(red: 0.95, green: 0.64, blue: 0.38),
        Color(red: 0.53, green: 0.81, blue: 0.92),
        Color(red: 0.96, green: 0.71, blue: 0.80),
    ]

    private var canSave: Bool {
        nickStatus == .available && selectedAvatar != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // 현재 아바타 미리보기
                        avatarPreviewSection

                        // 닉네임 수정
                        nickInputSection

                        // 아바타 선택
                        avatarGridSection

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("프로필 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .buttonStyle(.paramGhost)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSubmitting {
                        ProgressView().tint(.wave400)
                    } else {
                        Button("완료") { handleSave() }
                            .buttonStyle(.paramPrimary)
                            .disabled(!canSave)
                            .opacity(canSave ? 1.0 : 0.4)
                    }
                }
            }
        }
        .onAppear { setupInitialValues() }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 아바타 미리보기

    private var avatarPreviewSection: some View {
        HStack {
            Spacer()
            VStack(spacing: Spacing.xs) {
                if let selected = selectedAvatar {
                    let colorIndex = selected.sortOrder % Self.fallbackColors.count
                    Group {
                        if !selected.imageUrl.isEmpty {
                            ParamImageView(url: selected.imageUrl, contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Self.fallbackColors[colorIndex])
                                .frame(width: 80, height: 80)
                        }
                    }
                } else {
                    ParamImageView.avatar(url: nil, size: 80)
                }
                Text("아래에서 선택해주세요")
                    .captionStyle()
                    .foregroundColor(.ash)
            }
            Spacer()
        }
    }

    // MARK: - 닉네임 입력

    private var nickInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("닉네임")
                .captionStyle()
                .foregroundColor(.ash)

            HStack(alignment: .center) {
                TextField("닉네임을 입력해주세요", text: $nickname)
                    .focused($isNickFocused)
                    .font(.paramBody)
                    .foregroundColor(.void)
                    .onChange(of: nickname) { newValue in
                        if newValue.count > 10 {
                            nickname = String(newValue.prefix(10))
                            return
                        }
                        scheduleNickCheck(newValue)
                    }
                Text("\(nickname.count)/10")
                    .captionStyle()
                    .foregroundColor(.ash)
                    .monospacedDigit()
            }
            .padding(Spacing.md)
            .background(Color.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))

            nickStatusView
        }
    }

    @ViewBuilder
    private var nickStatusView: some View {
        switch nickStatus {
        case .empty:
            EmptyView()
        case .tooShort:
            statusText("2자 이상 입력해주세요", color: .ash)
        case .checking:
            HStack(spacing: 4) {
                ProgressView().scaleEffect(0.6).tint(.ash)
                statusText("확인 중...", color: .ash)
            }
        case .available:
            statusText("사용할 수 있어요", color: .wave400)
        case .taken:
            statusText("이미 사용 중이에요", color: Color(.systemRed))
        }
    }

    private func statusText(_ text: String, color: Color) -> some View {
        Text(text)
            .captionStyle()
            .foregroundColor(color)
            .padding(.leading, Spacing.xs)
    }

    // MARK: - 아바타 그리드

    private var avatarGridSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("아바타 선택")
                .font(.paramBody.weight(.semibold))
                .foregroundColor(.void)

            if isLoadingAvatars {
                HStack {
                    Spacer()
                    ProgressView().tint(.wave400)
                    Spacer()
                }
                .frame(height: 100)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4),
                    spacing: Spacing.sm
                ) {
                    ForEach(avatars) { avatar in
                        avatarCell(avatar)
                    }
                }
            }
        }
    }

    private func avatarCell(_ avatar: Avatar) -> some View {
        let isSelected = selectedAvatar?.id == avatar.id
        let colorIndex = avatar.sortOrder % Self.fallbackColors.count
        return VStack(spacing: Spacing.xs) {
            Group {
                if !avatar.imageUrl.isEmpty {
                    ParamImageView(url: avatar.imageUrl, contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Self.fallbackColors[colorIndex])
                        .frame(width: 64, height: 64)
                }
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.wave400 : Color.clear, lineWidth: 2)
            )
            Text(avatar.name)
                .captionStyle()
                .foregroundColor(.ash)
                .lineLimit(1)
        }
        .onTapGesture { selectedAvatar = avatar }
    }

    // MARK: - 초기값 설정

    private func setupInitialValues() {
        nickname = authManager.currentUser!.nickname ?? ""
        // 현재 닉네임은 사용 가능으로 처리
        if !nickname.isEmpty { nickStatus = .available }
        fetchAvatars()
    }

    // MARK: - 닉네임 중복 확인 (debounce)

    private func scheduleNickCheck(_ value: String) {
        nickCheckTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // 현재 닉네임과 동일하면 사용 가능으로 처리
        if trimmed == (authManager.currentUser!.nickname ?? "") {
            nickStatus = .available
            return
        }

        guard trimmed.count >= 2 else {
            nickStatus = trimmed.isEmpty ? .empty : .tooShort
            return
        }

        nickStatus = .checking
        nickCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await checkNickAvailability(trimmed)
        }
    }

    private func checkNickAvailability(_ nick: String) async {
        do {
            let currentId = authManager.currentUser!.id.uuidString
            let response = try await SupabaseManager.shared.client
                .from("users")
                .select("id", count: .exact)
                .eq("nickname", value: nick)
                .neq("id", value: currentId)
                .execute()
            nickStatus = (response.count ?? 0) == 0 ? .available : .taken
        } catch {
            nickStatus = .available
        }
    }

    // MARK: - 아바타 목록 fetch

    private func fetchAvatars() {
        Task {
            do {
                let result: [Avatar] = try await SupabaseManager.shared.client
                    .from("avatars")
                    .select()
                    .eq("is_active", value: true)
                    .order("sort_order")
                    .execute()
                    .value
                avatars = result.isEmpty ? Self.fallbackAvatars : result

                // 현재 아바타 선택 상태 반영
                if let currentAvatarId = authManager.currentUser!.avatarId {
                    selectedAvatar = avatars.first { $0.id == currentAvatarId }
                }
                if selectedAvatar == nil { selectedAvatar = avatars.first }
            } catch {
                avatars = Self.fallbackAvatars
                selectedAvatar = avatars.first
            }
            isLoadingAvatars = false
        }
    }

    // MARK: - 저장

    private func handleSave() {
        guard let avatar = selectedAvatar, canSave else { return }
        isSubmitting = true
        let isFallback = Self.fallbackAvatars.contains { $0.id == avatar.id }
        let avatarId: UUID? = isFallback ? nil : avatar.id
        Task {
            defer { isSubmitting = false }
            do {
                try await authManager.updateProfile(
                    nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                    avatarId: avatarId
                )
                onComplete?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
