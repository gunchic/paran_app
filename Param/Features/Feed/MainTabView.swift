import SwiftUI

// 메인 탭바 — 4개 탭
// No-Line Rule: 탭바 구분선 없음, 배경색 변화로 구분
struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var selectedTab: Int = 0

    init() {
        // 탭바 스타일 커스터마이징
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // paper 배경 (hex #F5F4F2)
        appearance.backgroundColor = UIColor(red: 0.961, green: 0.957, blue: 0.949, alpha: 1.0)
        // 상단 구분선 제거 (No-Line Rule)
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        // 선택 색상: wave400
        UITabBar.appearance().tintColor = UIColor(red: 0.494, green: 0.722, blue: 0.788, alpha: 1.0)
        // 미선택 색상: ash
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.604, green: 0.600, blue: 0.580, alpha: 1.0)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈 피드
            NavigationStack {
                HomeFeedView()
            }
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }
            .tag(0)

            // 크루 탐색
            NavigationStack {
                CrewExploreView()
            }
            .tabItem {
                Label("탐색", systemImage: "magnifyingglass")
            }
            .tag(1)

            // 파동 올리기
            NavigationStack {
                CreateWaveView()
            }
            .tabItem {
                Label("파동", systemImage: "plus.circle.fill")
            }
            .tag(2)

            // 마이페이지
            NavigationStack {
                MyPageView()
            }
            .tabItem {
                Label("프로필", systemImage: "person.fill")
            }
            .tag(3)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
