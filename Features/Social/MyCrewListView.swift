import SwiftUI

struct MyCrewListView: View {
    @State private var crews: [Crew] = []

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(crews) { crew in
                        NavigationLink(destination: CrewProfileView(crew: crew)) {
                            HStack(spacing: Spacing.md) {
                                CrewBadgeView(crew: crew)

                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(crew.crewName)
                                        .bodyStyle()
                                        .foregroundColor(.mist)

                                    Text("\(crew.memberCount)명")
                                        .captionStyle()
                                        .foregroundColor(.ash)
                                }

                                Spacer()
                            }
                            .paramCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.md)
            }
        }
        .navigationTitle("내 크루")
        .navigationBarTitleDisplayMode(.inline)
    }
}
