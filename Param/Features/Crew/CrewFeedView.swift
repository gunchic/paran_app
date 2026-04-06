import SwiftUI

struct CrewFeedView: View {
    let crew: Crew

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            Text("크루 피드 — 추후 구현")
                .bodyStyle()
                .foregroundColor(.ash)
        }
        .navigationTitle(crew.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
