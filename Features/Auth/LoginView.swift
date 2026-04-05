import SwiftUI

struct LoginView: View {
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                Text("PARAM")
                    .displayStyle()
                    .foregroundColor(.mist)

                Spacer()

                VStack(spacing: Spacing.sm) {
                    Button("Google로 계속하기") {
                        // TODO: Google OAuth
                        onLogin()
                    }
                    .buttonStyle(.paramPrimary)

                    Button("나중에 하기") {
                        onLogin()
                    }
                    .buttonStyle(.paramGhost)
                }
            }
            .padding(Spacing.lg)
        }
    }
}
