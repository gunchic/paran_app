import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var waves: [Wave] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.void.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(waves) { wave in
                            NavigationLink(destination: WaveDetailView(wave: wave)) {
                                WaveCardView(wave: wave)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("파람")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateWaveView()) {
                        Image(systemName: "plus")
                            .foregroundColor(.wave400)
                    }
                }
            }
        }
    }
}
