import Foundation
import Supabase

// MARK: - SupabaseManager

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let dbEncoder: JSONEncoder = {
            let e = JSONEncoder()
            e.keyEncodingStrategy = .convertToSnakeCase
            return e
        }()
        client = SupabaseClient(
            supabaseURL: URL(string: AppConfig.Supabase.url)!,
            supabaseKey: AppConfig.Supabase.anonKey,
            options: SupabaseClientOptions(
                db: .init(encoder: dbEncoder, decoder: .param)
            )
        )
    }
}

// MARK: - APIError (Supabase 호환)

extension APIError {
    static func from(_ error: Error) -> APIError {
        if let api = error as? APIError { return api }
        return .httpError(0, error.localizedDescription)
    }
}
