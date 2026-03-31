import SwiftUI
import MapKit
import Combine

// ─────────────────────────────────────────────────────────────
// WaveMapZone — 파동 지도 (파람 핵심 UX)
// 수시로 UI/기능 변경 가능 → 독립 컴포넌트로 분리
// ─────────────────────────────────────────────────────────────

struct WaveMapZone: View {
    let momentID: String
    @StateObject private var vm = WaveMapViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── 헤더 ──────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .foregroundColor(.signalRed)
                Text("파동 지도")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if !vm.points.isEmpty {
                    Text("\(vm.totalCount)명의 파동")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // ── 지도 본체 ─────────────────────────────────
            ZStack {
                if vm.isLoading {
                    mapPlaceholder
                } else if vm.points.isEmpty {
                    emptyView
                } else {
                    mapView
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .task { await vm.load(momentID: momentID) }
    }

    // ── 지도 ──────────────────────────────────────────────
    private var mapView: some View {
        Map(coordinateRegion: $vm.region, annotationItems: vm.points) { point in
            MapAnnotation(coordinate: point.coordinate) {
                WavePulsePin(count: point.count)
            }
        }
        .disabled(false)
        .overlay(alignment: .bottomLeading) {
            // 지역 요약 배지
            if !vm.summary.isEmpty {
                Text(vm.summary)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(10)
            }
        }
    }

    private var mapPlaceholder: some View {
        ZStack {
            Color(.systemGray6)
            ProgressView()
        }
    }

    private var emptyView: some View {
        ZStack {
            Color(.systemGray6)
            VStack(spacing: 8) {
                Image(systemName: "map")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)
                Text("아직 위치 정보가 없어요")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// WavePulsePin — 파동 애니메이션 핀
// ─────────────────────────────────────────────────────────────

struct WavePulsePin: View {
    let count: Int
    @State private var pulse = false

    var body: some View {
        ZStack {
            // 파동 애니메이션 링
            Circle()
                .stroke(Color.signalRed.opacity(0.3), lineWidth: 2)
                .frame(width: pulse ? 44 : 24, height: pulse ? 44 : 24)
                .opacity(pulse ? 0 : 0.8)
                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)

            Circle()
                .stroke(Color.signalRed.opacity(0.2), lineWidth: 1.5)
                .frame(width: pulse ? 60 : 24, height: pulse ? 60 : 24)
                .opacity(pulse ? 0 : 0.5)
                .animation(.easeOut(duration: 1.4).delay(0.3).repeatForever(autoreverses: false), value: pulse)

            // 핀 본체
            ZStack {
                Circle()
                    .fill(Color.signalRed)
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.signalRed.opacity(0.4), radius: 4)

                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .onAppear { pulse = true }
    }
}

// ─────────────────────────────────────────────────────────────
// WaveMapViewModel — 데이터 로직 (UI와 분리)
// ─────────────────────────────────────────────────────────────

struct WaveMapPoint: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let count: Int
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
class WaveMapViewModel: ObservableObject {
    @Published var points: [WaveMapPoint] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울 기본값
        span: MKCoordinateSpan(latitudeDelta: 3.0, longitudeDelta: 3.0)
    )
    @Published var isLoading = false

    var totalCount: Int { points.reduce(0) { $0 + $1.count } }

    // 상위 3개 지역 요약
    var summary: String {
        guard !points.isEmpty else { return "" }
        return points.prefix(3).map { p in
            let name = regionName(lat: p.latitude, lng: p.longitude)
            return "\(name) \(p.count)명"
        }.joined(separator: "  ·  ")
    }

    func load(momentID: String) async {
        isLoading = true
        defer { isLoading = false }

        struct APIPoint: Decodable {
            let latitude: Double
            let longitude: Double
            let count: Int
        }

        guard let pts: [APIPoint] = try? await APIClient.shared.get("/moments/\(momentID)/wave-map") else { return }

        points = pts.map { WaveMapPoint(latitude: $0.latitude, longitude: $0.longitude, count: $0.count) }

        // 지도 영역을 포인트들에 맞게 조정
        if !points.isEmpty {
            fitRegion()
        }
    }

    private func fitRegion() {
        guard !points.isEmpty else { return }

        let lats = points.map(\.latitude)
        let lngs = points.map(\.longitude)

        let minLat = lats.min()!, maxLat = lats.max()!
        let minLng = lngs.min()!, maxLng = lngs.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.5),
            longitudeDelta: max((maxLng - minLng) * 1.5, 0.5)
        )
        region = MKCoordinateRegion(center: center, span: span)
    }

    // 간단한 지역명 추정 (위경도 → 대략적 도시)
    private func regionName(lat: Double, lng: Double) -> String {
        switch (lat, lng) {
        case (37.4...37.7, 126.8...127.2): return "서울"
        case (35.0...35.3, 128.9...129.2): return "부산"
        case (35.8...36.0, 128.5...128.7): return "대구"
        case (37.3...37.5, 126.5...126.8): return "인천"
        case (35.1...35.2, 126.8...126.9): return "광주"
        case (36.3...36.4, 127.3...127.5): return "대전"
        case (35.4...35.6, 129.2...129.4): return "울산"
        case (33.4...33.6, 126.4...126.7): return "제주"
        case (37.7...38.0, 126.9...127.3): return "경기북부"
        case (37.0...37.4, 127.0...127.5): return "경기남부"
        default: return "(\(String(format: "%.1f", lat)), \(String(format: "%.1f", lng)))"
        }
    }
}
