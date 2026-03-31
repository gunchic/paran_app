import SwiftUI

// ─────────────────────────────────────────
// ParamButton — 파람 공통 버튼 컴포넌트
//
// variant:
//   .primary  — signalRed 채움 + 흰 텍스트
//   .secondary — sand 채움 + void 텍스트
//   .outlined — 투명 + signalRed 테두리
//   .ghost    — 배경 없음 + signalRed 텍스트
// ─────────────────────────────────────────
struct ParamButton: View {
    enum Variant { case primary, secondary, outlined, ghost }

    let title: String
    var variant: Variant = .primary
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(tintColor)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tintColor)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, isFullWidth ? 0 : Spacing.xl)
            .background(bgColor)
            .cornerRadius(Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonShadow()
        .disabled(isLoading)
    }

    private var bgColor: Color {
        switch variant {
        case .primary:   return .signalRed
        case .secondary: return .sand
        case .outlined:  return .clear
        case .ghost:     return .clear
        }
    }

    private var tintColor: Color {
        switch variant {
        case .primary:   return .white
        case .secondary: return .void
        case .outlined:  return .signalRed
        case .ghost:     return .signalRed
        }
    }

    private var borderColor: Color {
        switch variant {
        case .outlined: return .signalRed
        default:        return .clear
        }
    }

    private var borderWidth: CGFloat {
        variant == .outlined ? 1.5 : 0
    }
}
