import SwiftUI

struct ProfileSetupView: View {
    let onComplete: () -> Void

    @State private var nickname: String = ""
    @FocusState private var isNicknameFocused: Bool

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("프로필 설정")
                    .heading1Style()
                    .foregroundColor(.mist)

                Text("닉네임을 입력해주세요")
                    .bodyStyle()
                    .foregroundColor(.ash)

                TextField("닉네임", text: $nickname)
                    .focused($isNicknameFocused)
                    .foregroundColor(.mist)
                    .paramInput(isFocused: isNicknameFocused)

                Spacer()

                Button("완료") {
                    // TODO: 프로필 저장
                    onComplete()
                }
                .buttonStyle(.primary)
                .disabled(nickname.isEmpty)
            }
            .padding(Spacing.lg)
        }
        .onAppear { isNicknameFocused = true }
    }
}
