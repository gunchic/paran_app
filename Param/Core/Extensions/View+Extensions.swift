import SwiftUI

extension View {
    /// 조건부 modifier 적용
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// 숨김 처리 (레이아웃 유지)
    func hidden(_ isHidden: Bool) -> some View {
        self.opacity(isHidden ? 0 : 1)
    }
}
