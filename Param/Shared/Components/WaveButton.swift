import SwiftUI

struct WaveButton: View {
    let waveId: UUID
    var isWaved: Bool = false
    var count: Int = 0
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: isWaved ? "waveform.circle.fill" : "waveform.circle")
                    .foregroundColor(isWaved ? .wave400 : .ash)

                if count > 0 {
                    Text("\(count)")
                        .captionStyle()
                        .foregroundColor(isWaved ? .wave400 : .ash)
                }
            }
        }
        .buttonStyle(.ghost)
    }
}
