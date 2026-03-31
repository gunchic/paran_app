import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppState
    let onComplete: () -> Void

    @State private var nickname = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var canProceed: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    var body: some View {
        ZStack {
            Color.warmPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // 타이틀
                VStack(spacing: 8) {
                    Text("파람을 시작해볼게요")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.void)
                    Text("언제든지 My Page에서 수정할 수 있어요")
                        .font(.system(size: 13))
                        .foregroundColor(.driftwood)
                }

                Spacer().frame(height: 48)

                // 프로필 이미지
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    VStack(spacing: 10) {
                        ZStack {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Circle().fill(Color.sand)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(.driftwood)
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                        Text("변경하기")
                            .font(.system(size: 13))
                            .foregroundColor(.driftwood)
                    }
                }
                .onChange(of: selectedPhoto) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self) {
                            profileImage = UIImage(data: data)
                        }
                    }
                }

                Spacer().frame(height: 40)

                // 닉네임 입력
                VStack(alignment: .trailing, spacing: 6) {
                    TextField("닉네임을 입력하세요", text: $nickname)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: nickname) { _, val in
                            if val.count > 20 { nickname = String(val.prefix(20)) }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.sand, lineWidth: 1)
                        )
                    Text("\(nickname.count)/20")
                        .font(.system(size: 12))
                        .foregroundColor(.driftwood)
                }
                .padding(.horizontal, 24)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.signalRed)
                        .padding(.top, 10)
                }

                Spacer()

                // CTA
                Button(action: createUser) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("파동 시작하기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canProceed ? Color.signalRed : Color.sand)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .disabled(!canProceed)
                .animation(.easeInOut(duration: 0.2), value: canProceed)

                Spacer().frame(height: 52)
            }
        }
    }

    // MARK: - Types

    private struct UserRequest: Encodable {
        let nickname: String
        let profileImageUrl: String?
    }

    private struct UserResponse: Decodable {
        let id: String
        let nickname: String
        let profileImageUrl: String?
    }

    // MARK: - Action

    private func createUser() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                var profileImageUrl: String? = nil
                if let image = profileImage {
                    // 이미지 업로드 시 현재 유저 ID (소셜 로그인 유저는 pendingUserID 사용)
                    let uploaderID = appState.pendingUserID
                    profileImageUrl = try await APIClient.shared.uploadImage(image, userID: uploaderID)
                }

                let body = UserRequest(
                    nickname: nickname.trimmingCharacters(in: .whitespaces),
                    profileImageUrl: profileImageUrl
                )

                let res: UserResponse
                if let existingID = appState.pendingUserID {
                    // 소셜 로그인으로 이미 생성된 유저 → 프로필 업데이트
                    res = try await APIClient.shared.put(
                        "/users/\(existingID)",
                        body: body,
                        userID: existingID
                    )
                } else {
                    // 일반 신규 유저 → 새로 생성
                    res = try await APIClient.shared.post("/users", body: body)
                }

                appState.currentUserID          = res.id
                appState.currentNickname        = res.nickname
                appState.currentProfileImageURL = res.profileImageUrl
                appState.pendingUserID          = nil
                onComplete()
            } catch {
                errorMessage = "연결 실패: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
