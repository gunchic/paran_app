import SwiftUI

// MARK: - Design Rules
// - No-Line Rule: 1px 경계선 금지. 배경색 변화로 영역 구분
// - 그라디언트 CTA 금지 → wave400 단색 사용
// - 글래스모피즘 → 헤더에만 제한 적용
// - 다크 모드 우선

// MARK: - PrimaryButtonStyle
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.paramBody.weight(.bold))
            .foregroundColor(.void)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(configuration.isPressed ? Color.wave600 : Color.wave400)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - OutlineButtonStyle
// 버튼은 경계선 예외 허용
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.paramBody)
            .foregroundColor(.mist)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(Color.clear)
            .overlay(
                Capsule()
                    .stroke(Color.stone, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - GhostButtonStyle
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.paramBody)
            .foregroundColor(.ash)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(Color.clear)
            .opacity(configuration.isPressed ? 0.5 : 1)
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

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == OutlineButtonStyle {
    static var outline: OutlineButtonStyle { OutlineButtonStyle() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}
