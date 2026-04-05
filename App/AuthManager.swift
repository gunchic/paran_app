import SwiftUI
import Supabase

// MARK: - AuthManager
// Supabase Auth 상태 관리 + 유저 테이블 연동
@MainActor
final class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    @Published var isLoading: Bool = false

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    init() {
        Task {
            await clearKeychainIfFreshInstall()
            await startAuthListener()
        }
    }

    /// 앱 재설치 감지: UserDefaults는 삭제 시 초기화되지만 Keychain은 남아있음
    /// 첫 실행 플래그가 없으면 재설치로 판단하고 Supabase 세션 초기화
    private func clearKeychainIfFreshInstall() async {
        let key = "param_has_launched"
        if !UserDefaults.standard.bool(forKey: key) {
            try? await supabase.auth.signOut()
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    // MARK: - Supabase Auth 상태 리스너
    private func startAuthListener() async {
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .initialSession:
                if let session {
                    await fetchOrCreateUser(session: session)
                } else {
                    isLoggedIn = false
                }
            case .signedIn:
                if let session {
                    await fetchOrCreateUser(session: session)
                }
            case .signedOut, .userDeleted:
                currentUser = nil
                isLoggedIn = false
            default:
                break
            }
        }
    }

    // MARK: - Google OAuth 로그인
    // Info.plist에 URL Scheme "param" 등록 필요
    func loginWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }
        try await supabase.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "param://auth/callback")!
        )
    }

    // MARK: - 로그아웃
    func logout() async throws {
        try await supabase.auth.signOut()
    }

    // MARK: - 유저 조회 / 신규 생성
    private func fetchOrCreateUser(session: Session) async {
        let userId = session.user.id
        do {
            let rows: [User] = try await supabase
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let user = rows.first {
                currentUser = user
                isLoggedIn = true
            } else {
                // 신규 유저 INSERT
                let insert = UserInsert(
                    id: userId,
                    email: session.user.email
                )
                let inserted: [User] = try await supabase
                    .from("users")
                    .insert(insert)
                    .select()
                    .execute()
                    .value
                currentUser = inserted.first
                isLoggedIn = currentUser != nil
            }
        } catch {
            isLoggedIn = false
            currentUser = nil
        }
    }

    // MARK: - 프로필 업데이트 (A-03 완료 시 호출)
    // avatarId: nil이면 DB FK 위반 없이 null로 저장
    func updateProfile(nickname: String, avatarId: UUID?) async throws {
        guard let userId = currentUser?.id else { return }
        let update = UserProfileUpdate(nickname: nickname, avatarId: avatarId)
        let updated: [User] = try await supabase
            .from("users")
            .update(update)
            .eq("id", value: userId.uuidString)
            .select()
            .execute()
            .value
        currentUser = updated.first
    }
}
