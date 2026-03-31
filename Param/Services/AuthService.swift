import Foundation
import AuthenticationServices
import UIKit

/// 소셜 OAuth 코드 획득 서비스
/// - 카카오 / 네이버 / 구글: ASWebAuthenticationSession 으로 OAuth web flow 사용
@MainActor
final class AuthService: NSObject {
    static let shared = AuthService()
    private override init() {}

    // MARK: - 카카오

    func loginWithKakao() async throws -> String {
        var components = URLComponents(string: "https://kauth.kakao.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id",     value: AppConfig.OAuth.kakaoClientId),
            URLQueryItem(name: "redirect_uri",  value: "\(AppConfig.OAuth.callbackScheme)://auth/kakao"),
            URLQueryItem(name: "response_type", value: "code"),
        ]
        guard let url = components.url else { throw APIError.invalidResponse }
        return try await fetchAuthCode(url: url)
    }

    // MARK: - 네이버

    func loginWithNaver() async throws -> String {
        var components = URLComponents(string: "https://nid.naver.com/oauth2.0/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id",     value: AppConfig.OAuth.naverClientId),
            URLQueryItem(name: "redirect_uri",  value: "\(AppConfig.OAuth.callbackScheme)://auth/naver"),
            URLQueryItem(name: "state",         value: UUID().uuidString),
        ]
        guard let url = components.url else { throw APIError.invalidResponse }
        return try await fetchAuthCode(url: url)
    }

    // MARK: - 구글

    func loginWithGoogle() async throws -> String {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id",      value: AppConfig.OAuth.googleClientId),
            URLQueryItem(name: "redirect_uri",   value: "\(AppConfig.OAuth.googleCallbackScheme):/oauth2redirect"),
            URLQueryItem(name: "response_type",  value: "code"),
            URLQueryItem(name: "scope",          value: "email profile"),
        ]
        guard let url = components.url else { throw APIError.invalidResponse }
        return try await fetchAuthCode(url: url, callbackScheme: AppConfig.OAuth.googleCallbackScheme)
    }

    // MARK: - 공통 OAuth 코드 획득

    private var activeSession: ASWebAuthenticationSession?

    private func fetchAuthCode(url: URL, callbackScheme: String = AppConfig.OAuth.callbackScheme) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                self?.activeSession = nil
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
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

// MARK: - Presentation Context

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
