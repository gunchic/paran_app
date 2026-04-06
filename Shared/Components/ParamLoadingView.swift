import SwiftUI

/// 로딩 상태 공통 컴포넌트
struct ParamLoadingView: View {
    var isFullScreen: Bool = false

    var body: some View {
        Group {
            if isFullScreen {
                ZStack {
                    Color.paper.ignoresSafeArea()
                    ProgressView().tint(.wave400)
                }
            } else {
                ProgressView().tint(.wave400)
            }
        }
    }
}
