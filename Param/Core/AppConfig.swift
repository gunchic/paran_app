import Foundation

/// 앱 환경 설정 — Supabase URL, OAuth 클라이언트 ID 등
enum AppConfig {

    // MARK: - Supabase

    enum Supabase {
        static let url     = "https://ptnltusonbczrquzurti.supabase.co"
        static let anonKey = "sb_publishable_3X3zr8STg1EEu3sndvYKEQ_cNWGBW-h"
        /// 퍼블릭 Storage CDN 기본 URL (이미지 표시용)
        static let storagePublicURL = "\(url)/storage/v1/object/public/moments"
    }

    // MARK: - 이미지 베이스 URL (MomentCard 등에서 사용)

    static let imageBaseURL = Supabase.storagePublicURL

    // MARK: - 네트워크

    static let requestTimeout: TimeInterval = 15
    static let uploadTimeout:  TimeInterval = 60

    // MARK: - OAuth

    enum OAuth {
        /// kakao developers → 내 애플리케이션 → REST API 키
        static let kakaoClientId = "YOUR_KAKAO_REST_API_KEY"

        /// naver developers → 애플리케이션 → Client ID
        static let naverClientId = "YOUR_NAVER_CLIENT_ID"

        /// Google Cloud Console → iOS OAuth 2.0 클라이언트 ID
        static let googleClientId = "648460956237-kc9sp6m28upnq7tu3tt7j1lcfibk57ua.apps.googleusercontent.com"

        /// Google OAuth 콜백 scheme (리버스 클라이언트 ID)
        static let googleCallbackScheme = "com.googleusercontent.apps.648460956237-kc9sp6m28upnq7tu3tt7j1lcfibk57ua"

        /// Supabase OAuth 딥링크 콜백 scheme
        static let callbackScheme = "param"
    }
}
