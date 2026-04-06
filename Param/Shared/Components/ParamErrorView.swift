import SwiftUI

/// 에러 상태 공통 컴포넌트
struct ParamErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.ash)

            Text(message)
                .bodyStyle()
                .foregroundColor(.void)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button("다시 시도", action: retryAction)
                    .buttonStyle(.paramPrimary)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
