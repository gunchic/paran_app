import SwiftUI

// MARK: - Design Rules
// - No-Line Rule: 1px 경계선 금지. 배경색 변화로 영역 구분
// - 그라디언트 CTA 금지 → wave400 단색 사용
// - 글래스모피즘 → 헤더에만 제한 적용
// - 다크 모드 우선

// MARK: - ParamPrimaryButtonStyle
struct ParamPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color.void)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.wave400)
            .cornerRadius(100)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - ParamOutlineButtonStyle
// 버튼은 경계선 예외 허용
struct ParamOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color.mist)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .overlay(
                Capsule()
                    .stroke(Color.stone, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - ParamGhostButtonStyle
struct ParamGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(Color.ash)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - ParamCardModifier
// No-Line Rule: 경계선 없이 배경색으로 구분
struct ParamCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(Color.depth)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

// MARK: - ParamInputModifier
// No-Line Rule: border 없음. focus line은 wave400 하단선
struct ParamInputModifier: ViewModifier {
    var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(Spacing.sm)
            .background(Color.surfaceHighest)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isFocused ? .wave400 : .clear)
                    .padding(.horizontal, Radius.sm),
                alignment: .bottom
            )
    }
}

// MARK: - GlassHeaderModifier (헤더 전용)
struct GlassHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color.void.opacity(0.8)
                    .background(.ultraThinMaterial)
            )
    }
}

// MARK: - View Extensions for Style Helpers
extension View {
    func paramCard() -> some View {
        self.modifier(ParamCardModifier())
    }

    func paramInput(isFocused: Bool = false) -> some View {
        self.modifier(ParamInputModifier(isFocused: isFocused))
    }

    func glassHeader() -> some View {
        self.modifier(GlassHeaderModifier())
    }
}

extension ButtonStyle where Self == ParamPrimaryButtonStyle {
    static var paramPrimary: ParamPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == ParamOutlineButtonStyle {
    static var paramOutline: ParamOutlineButtonStyle { .init() }
}

extension ButtonStyle where Self == ParamGhostButtonStyle {
    static var paramGhost: ParamGhostButtonStyle { .init() }
}
