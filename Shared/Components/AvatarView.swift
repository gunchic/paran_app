import SwiftUI

struct AvatarView: View {
    var imageUrl: String? = nil
    var size: CGFloat = 40

    var body: some View {
        ParamImageView(url: imageUrl, contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .background(
                Circle().fill(Color.surfaceContainer)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.ash)
                            .font(.system(size: size * 0.45))
                            .opacity(imageUrl == nil || imageUrl?.isEmpty == true ? 1 : 0)
                    )
            )
    }
}
