import SwiftUI

// ─────────────────────────────────────────
// Typography — 파람 타이포그래피 시스템
// 사용법: .font(.paramHeadline)
// ─────────────────────────────────────────
extension Font {
    /// 앱 워드마크 (PARAM)
    static let paramWordmark = Font.system(size: 28, weight: .black)
    /// 섹션 제목
    static let paramHeadline = Font.system(size: 22, weight: .bold)
    /// 본문
    static let paramBody     = Font.system(size: 15, weight: .regular)
    /// 레이블 (태그, 뱃지)
    static let paramLabel    = Font.system(size: 12, weight: .medium)
    /// 캡션 (시간, 보조)
    static let paramCaption  = Font.system(size: 10, weight: .regular)
    /// 모노 (코드, ID)
    static let paramMono     = Font.custom("Courier New", size: 11)
}

// ─────────────────────────────────────────
// ParamTextStyle — foregroundColor 포함 조합
// 사용법: .modifier(ParamTextStyle.wordmark)
// ─────────────────────────────────────────
struct ParamTextStyle: ViewModifier {
    let font: Font
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }

    static let wordmark = ParamTextStyle(font: .paramWordmark, color: .void)
    static let headline = ParamTextStyle(font: .paramHeadline, color: .void)
    static let body     = ParamTextStyle(font: .paramBody,     color: .void)
    static let label    = ParamTextStyle(font: .paramLabel,    color: .driftwood)
    static let caption  = ParamTextStyle(font: .paramCaption,  color: .driftwood)
    static let mono     = ParamTextStyle(font: .paramMono,     color: .driftwood)
}

extension View {
    func paramTextStyle(_ style: ParamTextStyle) -> some View {
        modifier(style)
    }
}
