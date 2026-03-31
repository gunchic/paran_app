import SwiftUI

// ─────────────────────────────────────────
// ZONE 3 — 증명 갤러리 (파람 핵심 영역)
// Option C: 상단 가로 슬라이드 미리보기 + 하단 전체 카드 피드
// ─────────────────────────────────────────
struct ProofGalleryZone: View {
    let waves: [Wave]

    // 사진이 있는 Wave만 미리보기 슬라이드에 표시
    var photosWaves: [Wave] { waves.filter { $0.imageUrl != nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            if waves.isEmpty {
                emptyView
            } else {
                // 상단: 사진 미리보기 슬라이드 (사진 있는 응답만)
                if !photosWaves.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("파동 스냅")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(photosWaves) { wave in
                                    ProofThumbnail(wave: wave)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 14)
                    .background(Color(.systemBackground))

                    Divider()
                }

                // 하단: 전체 증명 카드 피드
                VStack(alignment: .leading, spacing: 0) {
                    Text("모든 파동 \(waves.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 8)

                    ForEach(waves) { wave in
                        ProofCard(wave: wave)
                        if wave.id != waves.last?.id {
                            Divider().padding(.leading, 70)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "water.waves")
                .font(.system(size: 36))
                .foregroundColor(Color(.systemGray4))
            Text("아직 아무도 파동을 일으키지 않았어요")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text("가장 먼저 \"나도 그래\"를 눌러보세요")
                .font(.system(size: 13))
                .foregroundColor(Color(.systemGray3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color(.systemBackground))
    }
}

// ─────────────────────────────────────────
// 가로 슬라이드용 썸네일
// ─────────────────────────────────────────
struct ProofThumbnail: View {
    let wave: Wave

    var body: some View {
        VStack(spacing: 4) {
            if let imageUrl = wave.imageUrl, let url = URL(string: imageUrl) {
                CachedImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(12)
            }

            Text(wave.nickname ?? "익명")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
}

// ─────────────────────────────────────────
// 전체 피드용 증명 카드
// ─────────────────────────────────────────
struct ProofCard: View {
    let wave: Wave

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // 왼쪽: 증명 사진 or 아바타
            Group {
                if let imageUrl = wave.imageUrl, let url = URL(string: imageUrl) {
                    TappableImage(url: url, cornerRadius: 10)
                } else {
                    avatarPlaceholder
                }
            }
            .frame(width: 52, height: 52)
            .clipped()
            .cornerRadius(10)

            // 오른쪽: 한마디 + 시간 · 닉네임
            VStack(alignment: .leading, spacing: 6) {
                if let body = wave.body, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }

                // "8시간 전 · 건식이" 형태
                HStack(spacing: 4) {
                    Text(wave.createdAt.relativeString)
                    Text("·")
                    Text(wave.nickname ?? "익명")
                }
                .font(.system(size: 12))
                .foregroundColor(Color(.systemGray3))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color.redTint
            Text(String((wave.nickname ?? "?").prefix(1)))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.signalRed)
        }
    }
}
