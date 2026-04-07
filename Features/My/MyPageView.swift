import SwiftUI

// MARK: - MyPageView (M-01)
struct MyPageView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = MyPageViewModel()
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var showClearCacheAlert = false
    @State private var showClearedAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileSection
                Color.surfaceLow.frame(height: 8)
                statsSection
                Color.surfaceLow.frame(height: 8)
                myWavesSection
                Color.surfaceLow.frame(height: 8)
                menuSection
                    .padding(.bottom, Spacing.xl)
            }
        }
        .background(Color.paper.ignoresSafeArea())
        .sheet(isPresented: $showEditProfile) {
            ProfileEditView {
                Task { await authManager.refreshCurrentUser() }
            }
        }
        .alert("로그아웃 할까요?", isPresented: $showSignOutAlert) {
            Button("취소", role: .cancel) {}
            Button("로그아웃", role: .destructive) {
                Task {
                    do { try await authManager.signOut() }
                    catch {}
                }
            }
        }
        .alert("정말 탈퇴할까요?", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("탈퇴", role: .destructive) {
                Task {
                    do {
                        try await UserService.shared.deleteAccount(userId: authManager.currentUser!.id)
                        try? await authManager.signOut()
                    } catch {}
                }
            }
        } message: {
            Text("모든 파동과 데이터가 삭제돼요")
        }
        .alert("캐시를 삭제할까요?", isPresented: $showClearCacheAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task {
                    await ImageCache.shared.clearAll()
                    await viewModel.loadCacheSize()
                    showClearedAlert = true
                }
            }
        } message: {
            Text("저장된 이미지 캐시 \(viewModel.cacheSize)가 삭제돼요")
        }
        .alert("완료", isPresented: $showClearedAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("캐시가 삭제됐어요")
        }
        .task {
            let userId = authManager.currentUser!.id
            await viewModel.loadAll(userId: userId, avatarId: authManager.currentUser!.avatarId)
        }
    }

    // MARK: - 섹션 1: 프로필

    private var profileSection: some View {
        VStack(spacing: Spacing.sm) {
            // 아바타 (탭 → 편집)
            Button { showEditProfile = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    ParamImageView.avatar(url: viewModel.avatarUrl, size: 80)
                    Circle()
                        .fill(Color.surfaceLowest)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.void)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)

            // 닉네임
            Text(authManager.currentUser!.nickname ?? "")
                .heading2Style()
                .foregroundColor(.void)

            // 소속 크루 배지 or 안내
            if let crew = viewModel.currentCrew {
                Button {
                    // TODO: CrewProfileView 연결
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.wave400)
                            .frame(width: 6, height: 6)
                        Text(crew.displayName)
                            .captionStyle()
                            .foregroundColor(.void)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 5)
                    .background(Color.wave400.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Text("크루가 없어요")
                    .captionStyle()
                    .foregroundColor(.ash)
            }

            // 프로필 편집 버튼
            Button { showEditProfile = true } label: {
                Text("프로필 편집")
                    .captionStyle()
                    .foregroundColor(.void)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.surfaceContainer)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    // MARK: - 섹션 2: 활동 통계

    private var statsSection: some View {
        HStack(spacing: 0) {
            statCell(value: viewModel.stats.waveCount, label: "파동")
            Rectangle().fill(Color.surfaceContainer).frame(width: 1, height: 32)
            statCell(value: viewModel.stats.resonateReceivedCount, label: "나도그래")
            Rectangle().fill(Color.surfaceContainer).frame(width: 1, height: 32)
            statCell(value: viewModel.stats.crewCount, label: "크루")
        }
        .padding(.vertical, Spacing.md)
        .background(Color.surfaceLowest)
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text("\(value)")
                .heading2Style()
                .foregroundColor(.void)
            Text(label)
                .captionStyle()
                .foregroundColor(.ash)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 섹션 3: 내 파동 그리드

    private var myWavesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("내 파동")
                .font(.paramBody.weight(.semibold))
                .foregroundColor(.void)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

            if viewModel.isLoadingWaves {
                ProgressView().tint(.wave400)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else if viewModel.myWaves.isEmpty {
                Text("아직 파동이 없어요")
                    .captionStyle()
                    .foregroundColor(.ash)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 3),
                    spacing: 1
                ) {
                    ForEach(viewModel.myWaves) { wave in
                        waveGridCell(wave)
                    }
                }
            }
        }
        .background(Color.surfaceLowest)
    }

    private func waveGridCell(_ wave: MyWave) -> some View {
        GeometryReader { geo in
            let size = geo.size.width
            if let url = wave.thumbnailUrl ?? wave.imageUrl {
                ParamImageView(url: url, contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Color.surfaceContainer
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 18))
                            .foregroundColor(.ash)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - 섹션 4: 메뉴

    private var menuSection: some View {
        VStack(spacing: Spacing.lg) {
            menuGroup(title: "계정") {
                NavigationLink(destination: MyCrewListView()) {
                    menuRow(icon: "person.3.fill", title: "내 크루 목록")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: FollowListView(userId: authManager.currentUser!.id)) {
                    menuRow(icon: "person.2.fill", title: "팔로우 / 팔로잉")
                }
                .buttonStyle(.plain)
            }

            menuGroup(title: "설정") {
                NavigationLink(destination: NotificationView()) {
                    menuRow(icon: "bell.fill", title: "알림 설정")
                }
                .buttonStyle(.plain)

                Button { showClearCacheAlert = true } label: {
                    menuRow(icon: "trash.fill", title: "캐시 삭제", trailing: viewModel.cacheSize)
                }
                .buttonStyle(.plain)
            }

            menuGroup(title: "정보") {
                Link(destination: URL(string: "https://param.app/terms")!) {
                    menuRow(icon: "doc.text", title: "서비스 이용약관")
                }

                Link(destination: URL(string: "https://param.app/privacy")!) {
                    menuRow(icon: "lock.fill", title: "개인정보처리방침")
                }

                menuRow(icon: "info.circle", title: "앱 버전", trailing: appVersion, hasChevron: false)
            }

            menuGroup(title: "계정 관리") {
                Button { showSignOutAlert = true } label: {
                    menuRow(icon: "rectangle.portrait.and.arrow.right", title: "로그아웃",
                            textColor: .red, hasChevron: false)
                }
                .buttonStyle(.plain)

                Button { showDeleteAlert = true } label: {
                    menuRow(icon: "xmark.circle", title: "회원 탈퇴",
                            textColor: .red, hasChevron: false)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - 메뉴 그룹

    private func menuGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .captionStyle()
                .foregroundColor(.ash)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.xs) {
                content()
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - 메뉴 행

    private func menuRow(
        icon: String,
        title: String,
        trailing: String = "",
        textColor: Color = .void,
        hasChevron: Bool = true
    ) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(textColor == .void ? .wave400 : textColor)
                .frame(width: 20)

            Text(title)
                .bodyStyle()
                .foregroundColor(textColor)

            Spacer()

            if !trailing.isEmpty {
                Text(trailing)
                    .captionStyle()
                    .foregroundColor(.ash)
            }

            if hasChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.slate)
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    // MARK: - 앱 버전

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - MyPageViewModel

@MainActor
final class MyPageViewModel: ObservableObject {
    @Published var stats: UserStats = UserStats()
    @Published var myWaves: [MyWave] = []
    @Published var currentCrew: Crew? = nil
    @Published var avatarUrl: String? = nil
    @Published var cacheSize: String = ""
    @Published var isLoadingWaves: Bool = false

    private let userService = UserService.shared
    private let crewService = CrewService.shared

    func loadAll(userId: UUID, avatarId: UUID?) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadStats(userId: userId) }
            group.addTask { await self.loadWaves(userId: userId) }
            group.addTask { await self.loadAvatarUrl(avatarId: avatarId) }
            group.addTask { await self.loadCacheSize() }
        }
    }

    func loadStats(userId: UUID) async {
        do {
            stats = try await userService.fetchMyStats(userId: userId)
        } catch {}
    }

    func loadWaves(userId: UUID) async {
        isLoadingWaves = true
        defer { isLoadingWaves = false }
        do {
            myWaves = try await userService.fetchMyWaves(userId: userId)
        } catch {}
    }

    func loadCurrentCrew(crewId: UUID?) async {
        guard let crewId else {
            currentCrew = nil
            return
        }
        do {
            currentCrew = try await crewService.fetchCrew(crewId: crewId)
        } catch {
            currentCrew = nil
        }
    }

    func loadAvatarUrl(avatarId: UUID?) async {
        avatarUrl = await userService.fetchAvatarUrl(avatarId: avatarId)
    }

    func loadCacheSize() async {
        let bytes = await ImageCache.shared.diskCacheSize()
        cacheSize = ImageCompressor.formatBytes(bytes)
    }
}
