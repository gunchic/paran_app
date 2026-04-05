import SwiftUI
import Combine

// A-03 프로필 설정 — 라이트 모드
struct ProfileSetupView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var nickname: String = ""
    @State private var nickStatus: NickStatus = .empty
    @State private var avatars: [Avatar] = []
    @State private var selectedAvatar: Avatar? = nil
    @State private var isLoadingAvatars: Bool = true
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isNickFocused: Bool

    // debounce용
    @State private var nickCheckTask: Task<Void, Never>? = nil

    // 폴백 아바타 (avatars 테이블 없을 때)
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

    private var isFormValid: Bool {
        nickStatus == .available && selectedAvatar != nil
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // 타이틀
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("파람 시작하기")
                            .heading1Style()
                            .foregroundColor(.void)

                        Text("닉네임과 아바타를 설정해주세요")
                            .bodyStyle()
                            .foregroundColor(.ash)
                    }
                    .padding(.top, Spacing.lg)

                    // 닉네임 입력
                    nickInputSection

                    // 아바타 선택
                    avatarSection

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.lg)
            }

            // 하단 완료 버튼 (고정)
            VStack {
                Spacer()
                Button(action: handleSubmit) {
                    if isSubmitting {
                        ProgressView().tint(.surfaceLowest)
                    } else {
                        Text("파람 시작하기")
                    }
                }
                .buttonStyle(.paramPrimary)
                .frame(maxWidth: .infinity)
                .disabled(!isFormValid || isSubmitting)
                .opacity(isFormValid ? 1.0 : 0.4)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
                .background(
                    Color.paper
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onAppear { fetchAvatars() }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 닉네임 입력 섹션
    private var nickInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // 입력 필드 + 카운터
            HStack(alignment: .center) {
                TextField("닉네임을 입력해주세요", text: $nickname)
                    .focused($isNickFocused)
                    .font(.paramBody)
                    .foregroundColor(.void)
                    .onChange(of: nickname) { newValue in
                        // 최대 10자 제한
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

            // 상태 메시지
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

    // MARK: - 아바타 선택 섹션
    private var avatarSection: some View {
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
                if let url = URL(string: avatar.imageUrl), !avatar.imageUrl.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Self.fallbackColors[colorIndex])
                    }
                } else {
                    Circle().fill(Self.fallbackColors[colorIndex])
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())
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

    // MARK: - 닉네임 중복 검사 (debounce 0.5초)
    private func scheduleNickCheck(_ value: String) {
        nickCheckTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            nickStatus = trimmed.isEmpty ? .empty : .tooShort
            return
        }

        nickStatus = .checking
        nickCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
            guard !Task.isCancelled else { return }
            await checkNickAvailability(trimmed)
        }
    }

    private func checkNickAvailability(_ nick: String) async {
        do {
            let currentId = authManager.currentUser?.id.uuidString ?? ""
            let response = try await SupabaseManager.shared.client
                .from("users")
                .select("id", count: .exact)
                .eq("nickname", value: nick)
                .neq("id", value: currentId)
                .execute()
            nickStatus = (response.count ?? 0) == 0 ? .available : .taken
        } catch {
            nickStatus = .available // 에러 시 낙관적 허용
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
            } catch {
                avatars = Self.fallbackAvatars
            }
            isLoadingAvatars = false
        }
    }

    // MARK: - 완료 제출
    private func handleSubmit() {
        guard let avatar = selectedAvatar, isFormValid else { return }
        isSubmitting = true
        // 폴백 아바타(DB에 없는 UUID)면 nil로 전달해 FK 위반 방지
        let isFallback = Self.fallbackAvatars.contains { $0.id == avatar.id }
        let avatarId: UUID? = isFallback ? nil : avatar.id
        Task {
            defer { isSubmitting = false }
            do {
                try await authManager.updateProfile(
                    nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                    avatarId: avatarId
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - NickStatus
enum NickStatus: Equatable {
    case empty, tooShort, checking, available, taken
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthManager())
}
