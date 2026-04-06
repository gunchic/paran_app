import SwiftUI
import PhotosUI

@MainActor
final class CreateWaveViewModel: ObservableObject {
    @Published var body: String = ""
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var isUploading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isSubmitted: Bool = false

    var canSubmit: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isUploading
    }

    private let service = WaveService.shared

    func loadImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            errorMessage = "이미지를 불러올 수 없어요"
        }
    }

    func submit(userId: UUID) async {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isUploading = true
        errorMessage = nil
        defer { isUploading = false }

        do {
            var imageUrl: String? = nil
            var thumbnailUrl: String? = nil

            if let image = selectedImage {
                let urls = try await service.uploadImage(image, userId: userId)
                imageUrl = urls.imageUrl
                thumbnailUrl = urls.thumbnailUrl
            }

            try await service.createMoment(
                userId: userId,
                body: trimmed,
                imageUrl: imageUrl,
                thumbnailUrl: thumbnailUrl
            )
            isSubmitted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
