import SwiftUI

struct CrewExploreView: View {
    @State private var crews: [Crew] = []
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.void.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(crews) { crew in
                            NavigationLink(destination: CrewProfileView(crew: crew)) {
                                crewRow(crew)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("크루 탐색")
            .searchable(text: $searchText, prompt: "크루 이름 검색")
        }
    }

    private func crewRow(_ crew: Crew) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(crew.crewName)
                    .bodyStyle()
                    .foregroundColor(.mist)

                Text("\(crew.memberCount)명")
                    .captionStyle()
                    .foregroundColor(.ash)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.slate)
                .captionStyle()
        }
        .paramCard()
    }
}
