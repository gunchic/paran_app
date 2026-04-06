import SwiftUI

/// 빈 상태 공통 컴포넌트
struct ParamEmptyView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.ash)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .bodyStyle()
                    .foregroundColor(.void)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .captionStyle()
                        .foregroundColor(.ash)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.paramPrimary)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
