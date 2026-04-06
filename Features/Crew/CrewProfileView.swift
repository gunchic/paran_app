import SwiftUI

struct CrewProfileView: View {
    let crew: Crew

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // 헤더
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(crew.displayName)
                            .heading1Style()
                            .foregroundColor(.void)

                        HStack(spacing: Spacing.sm) {
                            Text(crew.crewType == "keyword" ? "키워드" : "감정")
                                .captionStyle()
                                .foregroundColor(.wave400)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.wave800.opacity(0.3))
                                .clipShape(Capsule())

                            Text("\(crew.memberCount)명")
                                .captionStyle()
                                .foregroundColor(.ash)
                        }

                        if let desc = crew.description {
                            Text(desc)
                                .bodyStyle()
                                .foregroundColor(.ash)
                        }
                    }
                    .padding(Spacing.md)

                    Divider().background(Color.stone)

                    // 피드
                    CrewFeedView(crew: crew)
                }
            }
        }
        .navigationTitle(crew.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("가입") {
                    // TODO: 크루 가입
                }
                .buttonStyle(.paramPrimary)
            }
        }
    }
}
