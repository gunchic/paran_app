import SwiftUI
import UIKit

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("피드", systemImage: "water.waves")
                }

            GraphView()
                .tabItem {
                    Label("파동", systemImage: "point.3.connected.trianglepath.dotted")
                }

            MyProfileView()
                .tabItem {
                    Label("나", systemImage: "person.crop.circle")
                }
        }
        .tint(.signalRed)
        .onAppear {
            applyNavBarAppearance()
            applyTabBarAppearance()
        }
    }

    private func applyNavBarAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Color.warmPaper)
        nav.shadowColor = UIColor(Color.sand)
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }

    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.warmPaper)

        // 선택된 아이템 색상
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.signalRed)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.signalRed)
        ]
        // 미선택 아이템 색상
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.driftwood)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.driftwood)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
