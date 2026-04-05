import SwiftUI

struct AvatarView: View {
    var imageUrl: String? = nil
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let url = imageUrl.flatMap(URL.init) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderCircle
                }
            } else {
                placeholderCircle
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Color.surface)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.ash)
                    .font(.system(size: size * 0.45))
            )
    }
}
