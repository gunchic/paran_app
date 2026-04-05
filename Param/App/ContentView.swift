import SwiftUI

/// 앱 라우팅의 최상위 컨테이너
/// AppRouter로 위임
struct ContentView: View {
    var body: some View {
        AppRouter()
    }
}

#Preview {
    ContentView()
}
