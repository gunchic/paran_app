import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    let onComplete: (AppRoute) -> Void

    @State private var animating = false

    var body: some View {
        ZStack {
            Color.warmPaper.ignoresSafeArea()

            // 동심원 파문 (PARAM 텍스트 뒤)
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.signalRed.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 120, height: 120)
                        .scaleEffect(animating ? 4.5 : 0.3)
                        .opacity(animating ? 0 : 0.9)
                        .animation(
                            .easeOut(duration: 2.2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.7),
                            value: animating
                        )
                }
            }

            // 텍스트
            VStack(spacing: 14) {
                Text("PARAM")
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(.void)

                Text("보이지 않는 파동으로 연결되는 소셜 미디어")
                    .font(.system(size: 14))
                    .foregroundColor(.driftwood)
            }
        }
        .task {
            animating = true
            try? await Task.sleep(for: .seconds(2.0))
            onComplete(appState.currentUserID != nil ? .main : .onboarding)
        }
    }
}
