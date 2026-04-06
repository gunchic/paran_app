import Foundation

// MARK: - ParamError
// 앱 전역 에러 타입 — 모든 Service에서 이 타입으로 throw
enum ParamError: LocalizedError {
    case networkError(String)
    case authError
    case notFound
    case duplicated
    case uploadFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .authError:             return "로그인이 필요해요"
        case .notFound:              return "찾을 수 없어요"
        case .duplicated:            return "이미 존재해요"
        case .uploadFailed:          return "업로드에 실패했어요"
        case .unknown(let msg):      return msg.isEmpty ? "알 수 없는 오류가 발생했어요" : msg
        }
    }
}
