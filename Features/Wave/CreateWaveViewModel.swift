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
    @Published var hashtags: [String] = []

    // 이미지 포커싱 (0.0=상단 ~ 0.5=중앙 ~ 1.0=하단)
    @Published var imageOffsetY: Double = 0.5
    var dragBaseOffset: Double = 0.5

    var canSubmit: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isUploading
    }

    private let service = WaveService.shared
    private let maxHashtags = 5

    // MARK: - 해시태그

    func processHashtagInput() {
        let raw = hashtagInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .lowercased()

        guard !raw.isEmpty else {
            hashtagInput = ""
            return
        }

        if hashtags.count < maxHashtags && !hashtags.contains(raw) {
            hashtags.append(raw)
        }
        hashtagInput = ""
    }

    func removeHashtag(_ tag: String) {
        hashtags.removeAll { $0 == tag }
    }

    // MARK: - 이미지 선택

    func loadImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                // 새 이미지 선택 시 포커싱 초기화
                imageOffsetY = 0.5
                dragBaseOffset = 0.5
            }
        } catch {
            errorMessage = "이미지를 불러올 수 없어요"
        }
    }

    // MARK: - 파동 올리기

    func submit(userId: UUID) async {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 입력 중인 태그 확정
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
                let uploadId = UUID()
                let urls = try await ImageUploadService.shared.uploadWaveImage(
                    originalImage: image,
                    waveId: uploadId
                )
                imageUrl = urls.imageUrl
                thumbnailUrl = urls.thumbnailUrl
            }

            let momentId = try await service.createMoment(
                userId: userId,
                body: trimmed,
                imageUrl: imageUrl,
                thumbnailUrl: thumbnailUrl,
                imageOffsetY: selectedImage != nil ? imageOffsetY : nil
            )

            if !hashtags.isEmpty {
                try? await service.insertHashtags(hashtags, momentId: momentId)
            }

            isSubmitted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
