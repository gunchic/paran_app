import SwiftUI

struct CrewFeedView: View {
    let crew: Crew

    @State private var waves: [Wave] = []

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(waves) { wave in
                        WaveCardView(wave: wave)
                    }
                }
                .padding(Spacing.md)
            }
        }
        .navigationTitle(crew.crewName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
