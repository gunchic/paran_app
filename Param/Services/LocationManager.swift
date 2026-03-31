import CoreLocation
import Combine

// ─────────────────────────────────────────────────────────────
// LocationManager — 위치 권한 및 현재 위치 전담
// 파람 전역에서 공유 사용
// ─────────────────────────────────────────────────────────────

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // 도시 수준이면 충분
        authStatus = manager.authorizationStatus
    }

    // MARK: - Public

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestOnce() {
        guard authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        manager.requestLocation()
    }

    var isAuthorized: Bool {
        authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways
    }

    /// 비동기 위치 요청 — 이미 캐시된 위치 있으면 즉시 반환, 없으면 최대 timeout초 폴링
    func locationAsync(timeout: TimeInterval = 4.0) async -> CLLocation? {
        if let loc = currentLocation { return loc }
        guard isAuthorized else { requestPermission(); return nil }
        manager.requestLocation()
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s 간격
            if let loc = currentLocation { return loc }
        }
        return nil
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 위치 실패 시 조용히 처리 (위치는 선택 사항)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if isAuthorized { manager.requestLocation() }
    }
}
