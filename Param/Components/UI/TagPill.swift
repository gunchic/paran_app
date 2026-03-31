import SwiftUI

// ─────────────────────────────────────────
// TagPill — 파람 태그 컴포넌트
//
// variant:
//   .default  — redTint 배경 + signalRed 텍스트
//   .outlined — 투명 + redBorder 테두리
//   .active   — signalRed 배경 + 흰 텍스트
// ─────────────────────────────────────────
struct TagPill: View {
    enum Variant { case `default`, outlined, active }

    let text: String
    var variant: Variant = .default
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text("#\(text)")
                .font(.paramLabel)
                .foregroundColor(textColor)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(textColor)
                }
            }
        }
        .padding(.horizontal, Spacing.sm + Spacing.xs)
        .padding(.vertical, Spacing.xs + 1)
        .background(bgColor)
        .cornerRadius(Radius.full)
        .overlay(
            Capsule().stroke(borderColor, lineWidth: borderWidth)
        )
    }

    private var bgColor: Color {
        switch variant {
        case .default:  return .redTint
        case .outlined: return .clear
        case .active:   return .signalRed
        }
    }

    private var textColor: Color {
        switch variant {
        case .default:  return .signalRed
        case .outlined: return .signalRed
        case .active:   return .white
        }
    }

    private var borderColor: Color {
        switch variant {
        case .outlined: return .redBorder
        default:        return .clear
        }
    }

    private var borderWidth: CGFloat {
        variant == .outlined ? 1 : 0
    }
}
