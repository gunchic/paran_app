import SwiftUI
import MapKit

// ─────────────────────────────────────────
// WaveUsersView — 나도 그래를 누른 유저 목록
// ─────────────────────────────────────────
struct WaveUsersView: View {
    let momentID: String
    let waves: [Wave]

    @EnvironmentObject var appState: AppState
    @State private var showMap = false                   // 전체 지도 시트
    @State private var selectedProfileWave: Wave? = nil  // 프로필 이동

    private var hasAnyLocation: Bool {
        waves.contains { $0.latitude != nil && $0.longitude != nil }
    }

    /// 본인 파동을 최상단으로, 나머지는 원래 순서 유지
    private var sortedWaves: [Wave] {
        guard let myID = appState.currentUserID else { return waves }
        let mine   = waves.filter { $0.userId == myID }
        let others = waves.filter { $0.userId != myID }
        return mine + others
    }

    var body: some View {
        List {
            ForEach(sortedWaves) { wave in
                let isSelf = wave.userId == appState.currentUserID
                WaveUserRow(wave: wave, isSelf: isSelf)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isSelf else { return }
                        selectedProfileWave = wave
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle("나도 그래 \(waves.count)명")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if hasAnyLocation {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showMap = true } label: {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16))
                    }
                }
            }
        }
        .navigationDestination(item: $selectedProfileWave) { wave in
            UserProfileView(
                userID: wave.userId,
                nickname: wave.nickname ?? "",
                profileImageURL: wave.profileImageUrl
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showMap) {
            NavigationStack {
                WaveAllMapView(waves: waves)
                    .navigationTitle("파동 위치")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("닫기") { showMap = false }
                        }
                    }
            }
        }
    }
}

// ─────────────────────────────────────────
// WaveAllMapView — 전체 참여자 위치 지도
// ─────────────────────────────────────────
struct WaveAllMapView: View {
    let waves: [Wave]

    private var locatedWaves: [Wave] {
        waves.filter { $0.latitude != nil && $0.longitude != nil }
    }

    @State private var region: MKCoordinateRegion

    init(waves: [Wave]) {
        self.waves = waves
        let located = waves.filter { $0.latitude != nil && $0.longitude != nil }
        if let first = located.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: first.latitude!,
                    longitude: first.longitude!
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locatedWaves) { wave in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: wave.latitude!,
                longitude: wave.longitude!
            )) {
                WaveUserMapPin(wave: wave)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// ─────────────────────────────────────────
// WaveUserRow — 유저 1행
// ─────────────────────────────────────────
struct WaveUserRow: View {
    let wave: Wave
    let isSelf: Bool

    var body: some View {
        HStack(spacing: 12) {

            // 프로필 이미지
            Group {
                if let urlStr = wave.profileImageUrl, let url = URL(string: urlStr) {
                    CachedImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        avatarPlaceholder
                    }
                } else {
                    avatarPlaceholder
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))

            // 닉네임 + 한마디
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(wave.nickname ?? "알 수 없음")
                        .font(.system(size: 15, weight: .semibold))
                    if isSelf {
                        Text("나")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.signalRed)
                            .clipShape(Capsule())
                    }
                }
                if let body = wave.body, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !isSelf {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "person.fill")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
        }
    }
}

// ─────────────────────────────────────────
// WaveUserMapView — 개별 유저 파동 위치 지도
// ─────────────────────────────────────────
struct WaveUserMapView: View {
    let wave: Wave

    @State private var region: MKCoordinateRegion

    init(wave: Wave) {
        self.wave = wave
        let lat = wave.latitude ?? 37.5665
        let lng = wave.longitude ?? 126.9780
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: wave.latitude ?? 37.5665,
            longitude: wave.longitude ?? 126.9780
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region, annotationItems: [wave]) { w in
                    MapAnnotation(coordinate: coordinate) {
                        WaveUserMapPin(wave: w)
                    }
                }
                .ignoresSafeArea(edges: .top)

                userCard
                    .padding()
            }
            .navigationTitle("\(wave.nickname ?? "파동") 의 위치")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var userCard: some View {
        HStack(spacing: 12) {
            Group {
                if let urlStr = wave.profileImageUrl, let url = URL(string: urlStr) {
                    CachedImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: { placeholderAvatar }
                } else {
                    placeholderAvatar
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(wave.nickname ?? "알 수 없음")
                    .font(.system(size: 16, weight: .semibold))
                if let body = wave.body, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "water.waves")
                .foregroundColor(.signalRed)
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private var placeholderAvatar: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "person.fill")
                .foregroundColor(.secondary)
        }
    }
}

// ─────────────────────────────────────────
// WaveUserMapPin — 지도 핀
// ─────────────────────────────────────────
struct WaveUserMapPin: View {
    let wave: Wave
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.signalRed.opacity(0.3), lineWidth: 2)
                .frame(width: pulse ? 50 : 28, height: pulse ? 50 : 28)
                .opacity(pulse ? 0 : 0.8)
                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)

            if let urlStr = wave.profileImageUrl, let url = URL(string: urlStr) {
                CachedImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: { pinBackground }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 3)
            } else {
                pinBackground
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 3)
            }
        }
        .onAppear { pulse = true }
    }

    private var pinBackground: some View {
        ZStack {
            Color.signalRed
            Image(systemName: "water.waves")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }
}
