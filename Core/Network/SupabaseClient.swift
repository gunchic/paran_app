import Foundation
import Supabase

// MARK: - App Configuration
private enum AppConfig {
    enum Supabase {
        static let url     = "https://ptnltusonbczrquzurti.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0bmx0dXNvbmJjenJxdXp1cnRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1MDExNzQsImV4cCI6MjA5MDA3NzE3NH0.rOfc4rAfcMGu4udTo2ELfCTEDKjB_oTIhfnlEBN1PXk"
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
