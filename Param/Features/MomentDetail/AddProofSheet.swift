import SwiftUI
import PhotosUI

// ─────────────────────────────────────────
// AddProofSheet — "나도 그래" 응답 시트
// ─────────────────────────────────────────
struct AddProofSheet: View {
    let momentID: String
    let onCompleted: () -> Void

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var bodyText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isPosting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // 안내 문구
                    VStack(alignment: .leading, spacing: 4) {
                        Text("나도 그래")
                            .font(.system(size: 22, weight: .bold))
                        Text("지금 나의 상황을 한마디로 남겨보세요")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)

                    // 사진 (선택)
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(14)
                                .overlay(
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .shadow(radius: 4)
                                        .padding(10),
                                    alignment: .bottomTrailing
                                )
                        } else {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(.systemGray3))
                                    Text("지금 이 순간 찍기")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .frame(height: 140)
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self) {
                                selectedImage = UIImage(data: data)
                            }
                        }
                    }

                    // 한마디 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("한마디")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField("지금 상황을 한마디로...", text: $bodyText)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submit) {
                        if isPosting {
                            ProgressView()
                        } else {
                            Text("올리기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.signalRed)
                        }
                    }
                    .disabled((bodyText.isEmpty && selectedImage == nil) || isPosting)
                }
            }
        }
    }

    func submit() {
        guard let userID = appState.currentUserID else { return }
        isPosting = true
        errorMessage = nil

        Task {
            do {
                // 이미지 있으면 먼저 업로드
                var imageUrl: String? = nil
                if let image = selectedImage {
                    imageUrl = try await APIClient.shared.uploadImage(image, userID: userID)
                }

                struct WaveBody: Encodable {
                    let body: String?
                    let imageUrl: String?
                }

                let _: Wave = try await APIClient.shared.post(
                    "/moments/\(momentID)/wave",
                    body: WaveBody(
                        body: bodyText.isEmpty ? nil : bodyText,
                        imageUrl: imageUrl
                    ),
                    userID: userID
                )
                onCompleted()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPosting = false
        }
    }
}
