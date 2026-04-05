import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                Text("PARAM")
                    .displayStyle()
                    .foregroundColor(.mist)

                Text("당신의 파동을 세상에")
                    .bodyStyle()
                    .foregroundColor(.ash)

                Spacer()

                Button("시작하기", action: onFinish)
                    .buttonStyle(.paramPrimary)
            }
            .padding(Spacing.lg)
        }
    }
}
