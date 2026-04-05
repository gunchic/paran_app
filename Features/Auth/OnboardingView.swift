import SwiftUI

// A-01 온보딩 — 다크 모드 전용
struct OnboardingView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 배경: 다크
            Color.void.ignoresSafeArea()

            // 건너뛰기 (우상단)
            Button("건너뛰기") {
                onFinish()
            }
            .font(.paramBody)
            .foregroundColor(.slate)
            .padding(.top, Spacing.lg)
            .padding(.trailing, Spacing.lg)

            // 메인 콘텐츠
            VStack(alignment: .leading, spacing: 0) {
                // 워드마크
                Text("PARAM")
                    .font(.heading2)
                    .tracking(6)
                    .foregroundColor(.mist)
                    .padding(.top, Spacing.xl)

                Spacer()

                // 메인 카피
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("파동이\n닿는 곳")
                        .font(.display)
                        .fontWeight(.black)
                        .tracking(-2)
                        .foregroundColor(.wave400)
                        .lineSpacing(4)

                    Text("단어 하나로 크루가 시작됩니다")
                        .font(.caption)
                        .tracking(1)
                        .foregroundColor(.ash)
                }

                Spacer()

                // 시작하기 CTA
                Button("시작하기") {
                    onFinish()
                }
                .buttonStyle(.paramPrimary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
