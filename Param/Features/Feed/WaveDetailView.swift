import SwiftUI

struct WaveDetailView: View {
    let wave: Wave

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(wave.text)
                        .bodyStyle()
                        .foregroundColor(.mist)

                    if let imageUrl = wave.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.surface
                        }
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }

                    Text(wave.createdAt, style: .date)
                        .captionStyle()
                        .foregroundColor(.ash)
                }
                .padding(Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
