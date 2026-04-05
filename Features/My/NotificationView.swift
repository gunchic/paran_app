import SwiftUI

struct NotificationView: View {
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack {
                Spacer()
                Text("알림이 없습니다")
                    .bodyStyle()
                    .foregroundColor(.ash)
                Spacer()
            }
        }
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
    }
}
