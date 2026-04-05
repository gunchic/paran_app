import SwiftUI

struct WaveCardView: View {
    let wave: Wave

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(wave.text)
                .bodyStyle()
                .foregroundColor(.mist)
                .lineLimit(3)

            HStack {
                Text(wave.createdAt, style: .relative)
                    .captionStyle()
                    .foregroundColor(.ash)

                Spacer()
            }
        }
        .paramCard()
    }
}
