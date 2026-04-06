import SwiftUI

struct CrewBadgeView: View {
    let crew: Crew
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(badgeColor)

            Text(String(crew.displayName.prefix(1)))
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }

    private var badgeColor: Color {
        if let hex = crew.colorCode {
            return Color(hex: hex)
        }
        return .wave400
    }
}
