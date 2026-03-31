import Foundation

/// 앱 환경 설정 — API URL, OAuth 클라이언트 ID 등 환경별 분기
enum AppConfig {

    // MARK: - 환경 분기

    #if DEBUG
    static let apiBaseURL   = "http://172.20.10.2:8080/v1"
    static let imageBaseURL = "http://172.20.10.2:8080"
    #else
    static let apiBaseURL   = "https://api.param.app/v1"   // 프로덕션 엔드포인트
    static let imageBaseURL = "https://api.param.app"
    #endif

    // MARK: - 네트워크

    /// 일반 API 요청 타임아웃 (초)
    static let requestTimeout: TimeInterval = 15

    /// 이미지 업로드 타임아웃 (초)
    static let uploadTimeout: TimeInterval = 60

    // MARK: - OAuth
    // ⚠️ 프로덕션 배포 전 각 플랫폼 개발자 콘솔에서 실제 값으로 교체하세요

    enum OAuth {
        /// kakao developers → 내 애플리케이션 → REST API 키
        static let kakaoClientId = "YOUR_KAKAO_REST_API_KEY"

        /// naver developers → 애플리케이션 → Client ID
        static let naverClientId = "YOUR_NAVER_CLIENT_ID"

        /// Google Cloud Console → 사용자 인증 정보 → iOS OAuth 2.0 클라이언트 ID
        static let googleClientId = "648460956237-kc9sp6m28upnq7tu3tt7j1lcfibk57ua.apps.googleusercontent.com"

        /// Google OAuth 콜백 scheme (리버스 클라이언트 ID)
        static let googleCallbackScheme = "com.googleusercontent.apps.648460956237-kc9sp6m28upnq7tu3tt7j1lcfibk57ua"

        /// 카카오/네이버 콜백 scheme (Info.plist CFBundleURLSchemes 와 동일)
        static let callbackScheme = "param"
    }
}
