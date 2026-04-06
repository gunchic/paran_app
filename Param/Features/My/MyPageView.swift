import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var appState: AppState

    @State private var cacheSize: String = ""
    @State private var showClearAlert = false
    @State private var showClearedAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // 프로필 섹션
                        VStack(spacing: Spacing.sm) {
                            AvatarView(size: 80)

                            Text(appState.currentUser?.nickname ?? "닉네임 없음")
                                .heading2Style()
                                .foregroundColor(.void)

                            Text(appState.currentUser?.email ?? "")
                                .captionStyle()
                                .foregroundColor(.ash)
                        }
                        .padding(.top, Spacing.md)

                        // 메뉴
                        VStack(spacing: Spacing.xs) {
                            NavigationLink(destination: MyCrewListView()) {
                                menuRow(icon: "person.3", title: "내 크루")
                            }

                            NavigationLink(destination: FollowListView(userId: appState.currentUser?.id ?? UUID())) {
                                menuRow(icon: "person.2", title: "팔로우")
                            }

                            NavigationLink(destination: NotificationView()) {
                                menuRow(icon: "bell", title: "알림")
                            }
                        }
                        .padding(.horizontal, Spacing.md)

                        // 캐시 관리
                        VStack(spacing: Spacing.xs) {
                            Button {
                                showClearAlert = true
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.wave400)
                                        .frame(width: 24)

                                    Text("캐시 삭제")
                                        .bodyStyle()
                                        .foregroundColor(.void)

                                    Spacer()

                                    Text(cacheSize)
                                        .captionStyle()
                                        .foregroundColor(.ash)
                                }
                                .padding(Spacing.md)
                                .background(Color.surfaceLowest)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
            }
            .navigationTitle("나")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadCacheSize() }
            .alert("캐시를 삭제할까요?", isPresented: $showClearAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    Task {
                        await ImageCache.shared.clearAll()
                        await loadCacheSize()
                        showClearedAlert = true
                    }
                }
            } message: {
                Text("저장된 이미지 캐시 \(cacheSize)가 삭제돼요")
            }
            .alert("완료", isPresented: $showClearedAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("캐시가 삭제됐어요")
            }
        }
    }

    private func loadCacheSize() async {
        let bytes = await ImageCache.shared.diskCacheSize()
        cacheSize = ImageCompressor.formatBytes(bytes)
    }

    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(.wave400)
                .frame(width: 24)

            Text(title)
                .bodyStyle()
                .foregroundColor(.void)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.slate)
                .captionStyle()
        }
        .padding(Spacing.md)
        .background(Color.surfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}
