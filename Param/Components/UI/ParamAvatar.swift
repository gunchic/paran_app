import SwiftUI

// ─────────────────────────────────────────
// ParamAvatar — 파람 아바타 컴포넌트
//
// size:
//   .sm — 32pt (피드 카드 작성자)
//   .md — 48pt (리스트 행)
//   .lg — 80pt (프로필 헤더)
// ─────────────────────────────────────────
struct ParamAvatar: View {
    enum Size { case sm, md, lg }

    let url: String?
    let fallbackLetter: String
    var size: Size = .md

    var body: some View {
        Group {
            if let urlStr = url, let imageURL = URL(string: urlStr) {
                CachedImage(url: imageURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    fallbackView
                }
            } else {
                fallbackView
            }
        }
        .frame(width: dimension, height: dimension)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.sand, lineWidth: 1))
    }

    private var dimension: CGFloat {
        switch size {
        case .sm: return 32
        case .md: return 48
        case .lg: return 80
        }
    }

    private var fontSize: CGFloat {
        switch size {
        case .sm: return 13
        case .md: return 18
        case .lg: return 30
        }
    }

    private var fallbackView: some View {
        ZStack {
            Color.redTint
            Text(String(fallbackLetter.prefix(1)))
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(.signalRed)
        }
    }
}
