import SwiftUI

struct OnboardingSlideView: View {
    let onSkip: () -> Void
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let slides: [(title: String, desc: String, slide: Int)] = [
        ("나는 파동이다",   "억지로 찾지 않는다\n내 주파수를 방출할 뿐",          0),
        ("너도 그랬구나",   "나만 이러는 줄 알았는데\n같은 순간 같은 마음",        1),
        ("지금 이 순간만",  "공통점이 사라지면 연결도 흘러간다\n부담 없이",         2),
    ]

    var body: some View {
        ZStack {
            Color.warmPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                // 건너뛰기
                HStack {
                    Spacer()
                    Button("건너뛰기", action: onSkip)
                        .font(.system(size: 14))
                        .foregroundColor(.driftwood)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }

                // 슬라이드
                TabView(selection: $currentPage) {
                    ForEach(slides, id: \.title) { slide in
                        VStack(spacing: 40) {
                            Spacer()
                            IllustrationView(index: slide.slide)
                                .frame(height: 200)
                            VStack(spacing: 14) {
                                Text(slide.title)
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(.void)
                                Text(slide.desc)
                                    .font(.system(size: 16))
                                    .foregroundColor(.driftwood)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(5)
                            }
                            Spacer()
                        }
                        .tag(slides.firstIndex(where: { $0.title == slide.title }) ?? 0)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 인디케이터 + 버튼
                VStack(spacing: 28) {
                    HStack(spacing: 8) {
                        ForEach(0..<slides.count, id: \.self) { i in
                            Circle()
                                .fill(currentPage == i ? Color.signalRed : Color.sand)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    if currentPage == slides.count - 1 {
                        Button(action: onComplete) {
                            Text("시작하기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.signalRed)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        // 높이 유지용 placeholder
                        Color.clear.frame(height: 52)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: currentPage)
                .padding(.bottom, 52)
            }
        }
    }
}

// MARK: - 일러스트
private struct IllustrationView: View {
    let index: Int
    @State private var animate = false

    var body: some View {
        ZStack {
            switch index {
            case 0: SingleRipple(animate: animate)
            case 1: DoubleRipple(animate: animate)
            default: FadingRipple(animate: animate)
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - 애니메이션 헬퍼
private func loopAnim(duration: Double, delay: Double, reverses: Bool = true) -> Animation {
    Animation.easeInOut(duration: duration).repeatForever(autoreverses: reverses).delay(delay)
}
private func fadeAnim(delay: Double) -> Animation {
    Animation.easeOut(duration: 2.5).repeatForever(autoreverses: false).delay(delay)
}

/// 슬라이드 1: 한 점에서 파문이 퍼짐
private struct SingleRipple: View {
    let animate: Bool
    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(Color.signalRed.opacity(0.55 - Double(i) * 0.1), lineWidth: 1.5)
                    .frame(width: CGFloat(36 + i * 38), height: CGFloat(36 + i * 38))
                    .scaleEffect(animate ? 1.15 : 0.85)
                    .opacity(animate ? 0.25 : 0.85)
                    .animation(loopAnim(duration: 2.0, delay: Double(i) * 0.35), value: animate)
            }
            Circle().fill(Color.signalRed).frame(width: 12, height: 12)
        }
    }
}

/// 슬라이드 2: 두 파문이 중앙에서 만남
private struct DoubleRipple: View {
    let animate: Bool
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.signalRed.opacity(0.5), lineWidth: 1.5)
                    .frame(width: CGFloat(28 + i * 28), height: CGFloat(28 + i * 28))
                    .offset(x: -65)
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .animation(loopAnim(duration: 2.0, delay: Double(i) * 0.4), value: animate)
            }
            Circle().fill(Color.signalRed).frame(width: 10, height: 10).offset(x: -65)

            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.signalRed.opacity(0.5), lineWidth: 1.5)
                    .frame(width: CGFloat(28 + i * 28), height: CGFloat(28 + i * 28))
                    .offset(x: 65)
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .animation(loopAnim(duration: 2.0, delay: Double(i) * 0.4 + 0.2), value: animate)
            }
            Circle().fill(Color.signalRed).frame(width: 10, height: 10).offset(x: 65)
        }
    }
}

/// 슬라이드 3: 파문이 흘러가며 사라짐
private struct FadingRipple: View {
    let animate: Bool
    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(Color.signalRed.opacity(animate ? 0 : 0.55 - Double(i) * 0.1), lineWidth: 1.5)
                    .frame(width: CGFloat(36 + i * 38), height: CGFloat(36 + i * 38))
                    .scaleEffect(animate ? 1.6 : 1.0)
                    .animation(fadeAnim(delay: Double(i) * 0.5), value: animate)
            }
            Circle()
                .fill(Color.signalRed.opacity(animate ? 0.3 : 1.0))
                .frame(width: 12, height: 12)
                .animation(fadeAnim(delay: 0), value: animate)
        }
    }
}
