import SwiftUI
import Supabase

// MARK: - AuthManager
// Supabase Auth 상태 관리 + 유저 테이블 연동
// 파람은 로그인 베이스 앱 — hasSession true 이후 currentUser는 항상 non-nil
@MainActor
final class AuthManager: ObservableObject {
    @Published var currentUser: User? = nil
    /// 앱 시작 시 Supabase 세션 복원 중 여부
    @Published var isLoading: Bool = true

    /// 세션 유무 (= currentUser != nil)
    var hasSession: Bool { currentUser != nil }

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private let userSelect = "id, email, nickname, avatar_id, current_crew_id, is_profile_set, created_at"

    init() {
        Task {
            await clearKeychainIfFreshInstall()
            await startAuthListener()
        }
    }

    // MARK: - 앱 재설치 감지
    // Keychain은 앱 삭제 후에도 남아있으므로 첫 실행 플래그로 재설치 감지
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
                }
                isLoading = false
            case .signedIn:
                if let session {
                    await fetchOrCreateUser(session: session)
                }
            case .signedOut, .userDeleted:
                currentUser = nil
                isLoading = false
            default:
                break
            }
        }
    }

    // MARK: - Google OAuth 로그인
    func loginWithGoogle() async throws {
        try await supabase.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "param://auth/callback")!
        )
    }

    // MARK: - 로그아웃
    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
    }

    // MARK: - 현재 유저 정보 새로고침
    func refreshCurrentUser() async {
        guard let userId = currentUser?.id else { return }
        do {
            let rows: [User] = try await supabase
                .from("users")
                .select(userSelect)
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            if let user = rows.first { currentUser = user }
        } catch {}
    }

    // MARK: - 유저 조회 / 신규 생성
    private func fetchOrCreateUser(session: Session) async {
        let userId = session.user.id
        do {
            let rows: [User] = try await supabase
                .from("users")
                .select(userSelect)
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let user = rows.first {
                currentUser = user
            } else {
                let insert = UserInsert(id: userId, email: session.user.email)
                let inserted: [User] = try await supabase
                    .from("users")
                    .insert(insert)
                    .select(userSelect)
                    .execute()
                    .value
                currentUser = inserted.first
            }
        } catch {
            currentUser = nil
        }
    }

    // MARK: - 프로필 업데이트 (A-03, M-01 프로필 편집)
    func updateProfile(nickname: String, avatarId: UUID?) async throws {
        let userId = currentUser!.id
        let update = UserProfileUpdate(nickname: nickname, avatarId: avatarId)
        let updated: [User] = try await supabase
            .from("users")
            .update(update)
            .eq("id", value: userId.uuidString)
            .select(userSelect)
            .execute()
            .value
        currentUser = updated.first
    }
}
