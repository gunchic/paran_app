import SwiftUI
import Combine

@MainActor
final class CrewCreateViewModel: ObservableObject {
    @Published var crewName: String = ""
    @Published var crewType: String = "keyword"
    @Published var description: String = ""
    @Published var isNameTaken: Bool = false
    @Published var isCheckingName: Bool = false
    @Published var isCreating: Bool = false
    @Published var createdCrew: Crew? = nil
    @Published var errorMessage: String? = nil

    private var checkCancellable: AnyCancellable?
    private let service = CrewService.shared

    var canCreate: Bool {
        let trimmed = crewName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !isNameTaken && !isCheckingName
    }

    init() {
        checkCancellable = $crewName
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] name in
                Task { await self?.checkNameAvailability(name) }
            }
    }

    private func checkNameAvailability(_ name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            isNameTaken = false
            isCheckingName = false
            return
        }
        isCheckingName = true
        defer { isCheckingName = false }
        do {
            isNameTaken = try await service.isNameTaken(trimmed)
        } catch {
            isNameTaken = false
        }
    }

    func createCrew() async {
        let trimmed = crewName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }
        do {
            createdCrew = try await service.createCrew(
                name: trimmed,
                type: crewType,
                description: description.isEmpty ? nil : description
            )
        } catch {
            errorMessage = "크루 생성에 실패했어요. 다시 시도해주세요."
        }
    }
}
