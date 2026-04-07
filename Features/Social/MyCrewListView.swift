import SwiftUI

struct MyCrewListView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = MyCrewListViewModel()

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            if viewModel.isLoading {
                ParamLoadingView()
            } else if viewModel.memberships.isEmpty {
                ParamEmptyView(
                    icon: "person.3",
                    title: "아직 소속된 크루가 없어요",
                    subtitle: "크루를 탐색하고 가입해보세요"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(viewModel.memberships) { membership in
                            NavigationLink(destination: CrewProfileView(crew: membership.crew)) {
                                crewRow(membership)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
        }
        .navigationTitle("내 크루")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(userId: authManager.currentUser!.id)
        }
    }

    private func crewRow(_ membership: MyCrewMembership) -> some View {
        HStack(spacing: Spacing.md) {
            CrewBadgeView(crew: membership.crew, size: 44)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Text(membership.crew.displayName)
                        .font(.paramBody.weight(.semibold))
                        .foregroundColor(.void)

                    if membership.isFounder {
                        Text("대장")
                            .captionStyle()
                            .foregroundColor(.wave400)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.wave400.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Text("\(membership.crew.memberCount)명")
                    .captionStyle()
                    .foregroundColor(.ash)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(.slate)
        }
        .padding(Spacing.md)
        .background(Color.surfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

// MARK: - MyCrewListViewModel

@MainActor
final class MyCrewListViewModel: ObservableObject {
    @Published var memberships: [MyCrewMembership] = []
    @Published var isLoading: Bool = false

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            memberships = try await UserService.shared.fetchMyCrews(userId: userId)
        } catch {}
    }
}
