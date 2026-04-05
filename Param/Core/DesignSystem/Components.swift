import SwiftUI

// MARK: - Design Rules (Light Mode)
// - Background: paper (#F5F4F2)
// - Card: surfaceLowest (#FFFFFF)
// - Primary Button: wave800 background, white text
// - Inverted Button: void background, white text
// - Outline Button: stone border, void text
// - No gradient CTA — solid color only
// - Glass header: paper + ultraThinMaterial

// MARK: - ParamPrimaryButtonStyle
// 이미지 기준: 어두운 틸 배경(wave800), 흰 텍스트
struct ParamPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color.surfaceLowest)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.wave800)
            .cornerRadius(100)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - ParamOutlineButtonStyle
struct ParamOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color.void)
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

// MARK: - ParamInvertedButtonStyle
// 이미지 기준: 검정(void) 배경, 흰 텍스트
struct ParamInvertedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color.surfaceLowest)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.void)
            .cornerRadius(100)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - ParamCardModifier
// Light mode: 흰 카드, 그림자로 깊이 표현
struct ParamCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(Color.surfaceLowest)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .shadow(color: Color.void.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - ParamInputModifier
// Light mode: stone 배경, wave400 focus line
struct ParamInputModifier: ViewModifier {
    var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(Spacing.sm)
            .background(Color.surfaceLowest)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .stroke(isFocused ? Color.wave400 : Color.stone, lineWidth: 1)
            )
    }
}

// MARK: - GlassHeaderModifier (헤더 전용)
struct GlassHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color.paper.opacity(0.9)
                    .background(.ultraThinMaterial)
            )
    }
}

// MARK: - View Extensions
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

extension ButtonStyle where Self == ParamInvertedButtonStyle {
    static var paramInverted: ParamInvertedButtonStyle { .init() }
}
