import Foundation
import Supabase

// MARK: - App Configuration
private enum AppConfig {
    enum Supabase {
        // TODO: 실제 프로젝트 URL과 anon key로 교체
        static let url     = "https://YOUR_PROJECT_ID.supabase.co"
        static let anonKey = "YOUR_ANON_KEY"
    }
}

// MARK: - JSONDecoder Extension
extension JSONDecoder {
    static var param: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatters: [ISO8601DateFormatter] = [
                {
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return f
                }(),
                {
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withInternetDateTime]
                    return f
                }()
            ]
            for formatter in formatters {
                if let date = formatter.date(from: string) { return date }
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(string)"
            )
        }
        return decoder
    }
}

// MARK: - SupabaseManager
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let encoder: JSONEncoder = {
            let e = JSONEncoder()
            e.keyEncodingStrategy = .convertToSnakeCase
            return e
        }()

        client = SupabaseClient(
            supabaseURL: URL(string: AppConfig.Supabase.url)!,
            supabaseKey: AppConfig.Supabase.anonKey,
            options: SupabaseClientOptions(
                db: .init(encoder: encoder, decoder: .param)
            )
        )
    }
}
