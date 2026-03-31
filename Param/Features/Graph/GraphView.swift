import SwiftUI
import Combine

struct GraphView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = GraphViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    if !vm.myNode.topTags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("나의 파동")
                                .font(.headline)
                                .padding(.horizontal, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(vm.myNode.topTags, id: \.tag) { tw in
                                        VStack(spacing: Spacing.xs) {
                                            Text("#\(tw.tag)").font(.subheadline).bold().foregroundColor(.void)
                                            Text("\(tw.count)회").font(.paramCaption).foregroundColor(.driftwood)
                                        }
                                        .padding(.horizontal, Spacing.sm + Spacing.xs)
                                        .padding(.vertical, Spacing.sm + 2)
                                        .background(Color.redTint)
                                        .cornerRadius(Radius.xl)
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                            }
                        }
                    }

                    if !vm.myNode.connections.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("연결된 사람들")
                                .font(.headline)
                                .padding(.horizontal, 16)
                            ForEach(vm.myNode.connections, id: \.userId) { conn in
                                HStack {
                                    Circle()
                                        .fill(Color.redTint)
                                        .frame(width: 40, height: 40)
                                        .overlay(Text(String(conn.nickname.prefix(1))).font(.headline).foregroundColor(.signalRed))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(conn.nickname).font(.subheadline).bold().foregroundColor(.void)
                                        Text("함께 공명 \(conn.strength)회").font(.paramCaption).foregroundColor(.driftwood)
                                    }
                                    Spacer()
                                    ForEach(0..<min(conn.strength, 5), id: \.self) { _ in
                                        Circle().fill(Color.signalRed).frame(width: 6, height: 6)
                                    }
                                }
                                .padding(Spacing.lg)
                                .background(Color(.systemBackground))
                                .cornerRadius(Radius.xl)
                                .cardShadow()
                                .padding(.horizontal, Spacing.lg)
                            }
                        }
                    }

                    if !vm.similarUsers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("같은 파동 위의 사람들")
                                .font(.headline)
                                .padding(.horizontal, 16)
                            ForEach(vm.similarUsers, id: \.userId) { user in
                                HStack {
                                    Circle()
                                        .fill(Color.whiteWarm)
                                        .frame(width: 40, height: 40)
                                        .overlay(Text(String(user.nickname.prefix(1))).font(.headline).foregroundColor(.driftwood))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.nickname).font(.subheadline).bold().foregroundColor(.void)
                                        if !user.commonTags.isEmpty {
                                            Text(user.commonTags.map { "#\($0)" }.joined(separator: " "))
                                                .font(.paramCaption).foregroundColor(.driftwood)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(Spacing.lg)
                                .background(Color(.systemBackground))
                                .cornerRadius(Radius.xl)
                                .cardShadow()
                                .padding(.horizontal, Spacing.lg)
                            }
                        }
                    }

                    if vm.myNode.connections.isEmpty && vm.similarUsers.isEmpty && !vm.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "water.waves").font(.system(size: 48)).foregroundColor(.secondary)
                            Text("아직 연결된 파동이 없어요\nMoment를 올리고 Wave해보세요")
                                .multilineTextAlignment(.center).foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("파동 그물망")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.load(userID: appState.currentUserID) }
        }
    }
}

@MainActor
class GraphViewModel: ObservableObject {
    @Published var myNode = GraphNode(userId: "", nickname: "", connections: [], topTags: [])
    @Published var similarUsers: [SimilarUser] = []
    @Published var isLoading = true

    func load(userID: String?) async {
        guard let userID else { return }
        isLoading = true
        async let node: GraphNode? = try? APIClient.shared.get("/graph/me", userID: userID)
        async let similar: [SimilarUser]? = try? APIClient.shared.get("/graph/similar", userID: userID)
        myNode = (await node) ?? GraphNode(userId: "", nickname: "", connections: [], topTags: [])
        similarUsers = (await similar) ?? []
        isLoading = false
    }
}
