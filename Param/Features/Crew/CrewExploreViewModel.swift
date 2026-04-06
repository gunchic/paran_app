import SwiftUI
import Combine

@MainActor
final class CrewExploreViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [Crew] = []
    @Published var popularCrews: [Crew] = []
    @Published var recentCrews: [Crew] = []
    @Published var isSearching: Bool = false
    @Published var isLoadingInitial: Bool = false

    private var searchCancellable: AnyCancellable?
    private let service = CrewService.shared

    init() {
        searchCancellable = $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { await self?.handleSearch(query) }
            }
    }

    func loadInitial() async {
        guard popularCrews.isEmpty else { return }
        isLoadingInitial = true
        defer { isLoadingInitial = false }
        do {
            async let popular = service.fetchPopularCrews()
            async let recent = service.fetchRecentCrews()
            (popularCrews, recentCrews) = try await (popular, recent)
        } catch { /* fail silently */ }
    }

    private func handleSearch(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        defer { isSearching = false }
        do {
            searchResults = try await service.searchCrews(query: trimmed)
        } catch {
            searchResults = []
        }
    }
}
