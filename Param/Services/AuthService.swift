import Foundation
import AuthenticationServices
import UIKit
import Supabase

// MARK: - AuthService (Supabase Auth 기반)

@MainActor
final class AuthService: NSObject {
    static let shared = AuthService()
    private override init() {}

    private var sb: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - 구글 로그인 (Supabase 네이티브 OAuth)

    func loginWithGoogle() async throws -> SupabaseSession {
        // Supabase SDK가 내부적으로 ASWebAuthenticationSession을 사용하여 OAuth 처리
        try await sb.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "\(AppConfig.OAuth.callbackScheme)://auth/callback")!,
            queryParams: [("access_type", "offline")]
        )
        // 로그인 후 현재 세션 반환
        return try await sb.auth.session
    }

    // MARK: - 카카오 로그인

    func loginWithKakao() async throws -> SupabaseSession {
        var components = URLComponents(string: "https://kauth.kakao.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id",     value: AppConfig.OAuth.kakaoClientId),
            URLQueryItem(name: "redirect_uri",  value: "\(AppConfig.OAuth.callbackScheme)://auth/kakao"),
            URLQueryItem(name: "response_type", value: "code"),
        ]
        guard let url = components.url else { throw APIError.invalidResponse }
        let code = try await fetchOAuthCode(url: url)

        // Supabase에 카카오 코드 전달 (Edge Function 필요 — 현재 미지원)
        // TODO: Supabase Edge Function /auth/kakao 구현 후 연동
        throw APIError.httpError(501, "카카오 로그인은 준비 중입니다. 구글 로그인을 이용해 주세요.")
    }

    // MARK: - 네이버 로그인

    func loginWithNaver() async throws -> SupabaseSession {
        throw APIError.httpError(501, "네이버 로그인은 준비 중입니다. 구글 로그인을 이용해 주세요.")
    }

    // MARK: - 로그아웃

    func logout() async throws {
        try await sb.auth.signOut()
    }

    // MARK: - 현재 세션 조회

    func currentSession() async -> SupabaseSession? {
        try? await sb.auth.session
    }

    // MARK: - 프로필 조회 (Public Users 테이블)

    /// 로그인 후 public.users 테이블에서 닉네임 유무 확인
    /// - nil nickname → 신규 유저 → ProfileSetupView
    /// - 닉네임 있음 → 기존 유저 → 메인 앱
    func fetchOrCreateProfile(session: SupabaseSession) async throws -> (userID: String, nickname: String?, profileImageURL: String?) {
        let userID = session.user.id.uuidString

        struct UserProfile: Decodable {
            let id: String
            let nickname: String?
            let profileImageUrl: String?
        }
        let results: [UserProfile] = try await SupabaseManager.shared.client
            .from("users")
            .select("id, nickname, profile_image_url")
            .eq("id", value: userID)
            .execute()
            .value

        if let profile = results.first {
            return (userID, profile.nickname, profile.profileImageUrl)
        }

        // 레코드 없음 → 트리거가 아직 실행 안 됐거나 신규 유저 → 수동 생성
        struct UserInsert: Encodable {
            let id: String
            let email: String?
            let socialProvider: String?
        }
        try await SupabaseManager.shared.client
            .from("users")
            .insert(UserInsert(
                id: userID,
                email: session.user.email,
                socialProvider: session.user.appMetadata["provider"]?.stringValue
            ))
            .execute()

        return (userID, nil, nil)
    }
}

// MARK: - Private OAuth 헬퍼

private extension AuthService {
    var activeSession: ASWebAuthenticationSession? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.session) as? ASWebAuthenticationSession }
        set { objc_setAssociatedObject(self, &AssociatedKeys.session, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func fetchOAuthCode(url: URL, callbackScheme: String = AppConfig.OAuth.callbackScheme) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                self?.activeSession = nil
                if let error { continuation.resume(throwing: error); return }
                guard let callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                          .queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            activeSession = session
            session.start()
        }
    }
}

// MARK: - ASWebAuthenticationSession Context

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - 연관 객체 키

private enum AssociatedKeys {
    static var session = "authSession"
}

// MARK: - Supabase Session 타입 별칭

typealias SupabaseSession = Session
