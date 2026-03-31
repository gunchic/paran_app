import Foundation
import UIKit

enum APIError: LocalizedError {
    case httpError(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let msg): return "[\(code)] \(msg)"
        case .invalidResponse:             return "잘못된 응답"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    let imageBaseURL = AppConfig.imageBaseURL

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = AppConfig.requestTimeout
        config.timeoutIntervalForResource = AppConfig.requestTimeout * 4
        return URLSession(configuration: config)
    }()

    private let uploadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = AppConfig.uploadTimeout
        config.timeoutIntervalForResource = AppConfig.uploadTimeout * 2
        return URLSession(configuration: config)
    }()

    // MARK: - CRUD

    func get<T: Decodable>(_ path: String, userID: String? = nil) async throws -> T {
        let request = buildRequest(path, method: "GET", userID: userID)
        let (data, response) = try await session.data(for: request)
        try checkHTTP(response, data)
        return try JSONDecoder.param.decode(T.self, from: data)
    }

    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body, userID: String? = nil) async throws -> T {
        var request = buildRequest(path, method: "POST", userID: userID)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try checkHTTP(response, data)
        return try JSONDecoder.param.decode(T.self, from: data)
    }

    func put<Body: Encodable, T: Decodable>(_ path: String, body: Body, userID: String? = nil) async throws -> T {
        var request = buildRequest(path, method: "PUT", userID: userID)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try checkHTTP(response, data)
        return try JSONDecoder.param.decode(T.self, from: data)
    }

    func delete(_ path: String, userID: String? = nil) async throws {
        let request = buildRequest(path, method: "DELETE", userID: userID)
        let (data, response) = try await session.data(for: request)
        try checkHTTP(response, data)
    }

    // MARK: - 소셜 로그인

    func socialLogin(provider: String, code: String) async throws -> SocialAuthResponse {
        try await post("/auth/\(provider)", body: SocialLoginRequest(code: code))
    }

    // MARK: - 이미지 업로드

    func uploadImage(_ image: UIImage, userID: String? = nil) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotCreateFile)
        }
        return try await uploadImageData(imageData, path: nil, userID: userID)
    }

    /// 압축된 Data를 직접 업로드. path 지정 시 서버에 해당 경로로 저장.
    /// path 예: "waves/{userID}/{momentID}/thumbnail.jpg"
    func uploadImageData(_ data: Data, path: String?, userID: String? = nil) async throws -> String {
        let query = path.map { "?path=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0)" } ?? ""
        var request = buildRequest("/upload\(query)", method: "POST", userID: userID)
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(data: data, boundary: boundary)

        let (responseData, response) = try await uploadSession.data(for: request)
        try checkHTTP(response, responseData)
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: String],
              let url = json["url"]
        else { throw URLError(.badServerResponse) }
        return url
    }

    // MARK: - Private

    private let jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private func buildRequest(_ path: String, method: String, userID: String?) -> URLRequest {
        var request = URLRequest(url: URL(string: AppConfig.apiBaseURL + path)!)
        request.httpMethod = method
        if let userID { request.setValue(userID, forHTTPHeaderField: "X-User-ID") }
        return request
    }

    private func checkHTTP(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                ?? String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
            throw APIError.httpError(http.statusCode, msg)
        }
    }

    private func makeMultipartBody(data: Data, boundary: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

// MARK: - JSONDecoder

extension JSONDecoder {
    static let param: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let str = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(),
                debugDescription: "Invalid date: \(str)")
        }
        return d
    }()
}
