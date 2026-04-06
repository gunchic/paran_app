import SwiftUI

/// 메인 탭바 — 커스텀 중앙 파동 버튼 포함
struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var selectedTab: Int = 0
    @State private var showCreateWave = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // 탭 콘텐츠
            tabContent
                .padding(.bottom, 60) // 커스텀 탭바 높이 확보

            // 커스텀 탭바
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showCreateWave) {
            CreateWaveView(onSuccess: nil)
        }
    }

    // MARK: - 탭 콘텐츠
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            NavigationStack { HomeFeedView() }
        case 1:
            NavigationStack { CrewExploreView() }
        case 3:
            NavigationStack { MyPageView() }
        default:
            NavigationStack { HomeFeedView() }
        }
    }

    // MARK: - 커스텀 탭바
    private var customTabBar: some View {
        ZStack {
            // 탭바 배경 (No-Line Rule: 그림자로만 구분)
            Color.paper
                .frame(height: 60)
                .shadow(color: Color.void.opacity(0.06), radius: 8, x: 0, y: -2)

            HStack(spacing: 0) {
                tabButton(icon: "house.fill", label: "홈", tag: 0)
                tabButton(icon: "magnifyingglass", label: "탐색", tag: 1)

                // 중앙 파동 버튼
                Button {
                    showCreateWave = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.wave400)
                            .frame(width: 52, height: 52)
                            .shadow(color: Color.wave400.opacity(0.4), radius: 8, x: 0, y: 4)

                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.void)
                    }
                }
                .offset(y: -14)
                .frame(maxWidth: .infinity)

                tabButton(icon: "bell", label: "알림", tag: 2)
                tabButton(icon: "person.fill", label: "나", tag: 3)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 60)
        }
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == tag ? .wave400 : .ash)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(selectedTab == tag ? .wave400 : .ash)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
