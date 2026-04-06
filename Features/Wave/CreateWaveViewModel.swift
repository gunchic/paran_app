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

    // 해시태그
    @Published var hashtagInput: String = ""
    @Published var hashtags: [String] = []  // 확정된 태그 목록

    var canSubmit: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isUploading
    }

    private let service = WaveService.shared
    private let maxHashtags = 5

    // 스페이스/엔터 입력 시 태그 확정
    func processHashtagInput() {
        let raw = hashtagInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .lowercased()

        guard !raw.isEmpty else {
            hashtagInput = ""
            return
        }

        // 최대 5개 제한
        if hashtags.count < maxHashtags && !hashtags.contains(raw) {
            hashtags.append(raw)
        }
        hashtagInput = ""
    }

    func removeHashtag(_ tag: String) {
        hashtags.removeAll { $0 == tag }
    }

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

        // 입력 중인 태그가 있으면 확정
        if !hashtagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            processHashtagInput()
        }

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

            let momentId = try await service.createMoment(
                userId: userId,
                body: trimmed,
                imageUrl: imageUrl,
                thumbnailUrl: thumbnailUrl
            )

            // 해시태그 INSERT (실패해도 파동은 등록된 것으로 처리)
            if !hashtags.isEmpty {
                try? await service.insertHashtags(hashtags, momentId: momentId)
            }

            isSubmitted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
