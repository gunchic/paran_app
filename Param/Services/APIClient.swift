import Foundation
import UIKit
import Supabase

// MARK: - APIError

enum APIError: LocalizedError {
    case httpError(Int, String)
    case invalidResponse
    case notFound

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let msg): return "[\(code)] \(msg)"
        case .invalidResponse:             return "잘못된 응답"
        case .notFound:                    return "찾을 수 없음"
        }
    }
}

// MARK: - APIPoint

struct APIPoint: Decodable {
    let latitude:  Double
    let longitude: Double
}

// MARK: - APIClient

class APIClient {
    static let shared = APIClient()
    let imageBaseURL = AppConfig.imageBaseURL

    private var sb: SupabaseClient { SupabaseManager.shared.client }

    // ─────────────────────────────────────────────────────
    // MARK: Generic REST-style 인터페이스 (경로 기반 라우팅)
    // ─────────────────────────────────────────────────────

    func get<T: Decodable>(_ path: String, userID: String? = nil) async throws -> T {
        let (cleanPath, params) = splitPath(path)
        return try await routeGet(cleanPath, params: params, viewerID: userID)
    }

    func post<Body: Encodable, T: Decodable>(
        _ path: String, body: Body, userID: String? = nil
    ) async throws -> T {
        try await routePost(path, body: body, actorID: userID)
    }

    func put<Body: Encodable, T: Decodable>(
        _ path: String, body: Body, userID: String? = nil
    ) async throws -> T {
        try await routePut(path, body: body, actorID: userID)
    }

    func delete(_ path: String, userID: String? = nil) async throws {
        try await routeDelete(path, actorID: userID)
    }

    // ─────────────────────────────────────────────────────
    // MARK: 이미지 업로드 (Supabase Storage)
    // ─────────────────────────────────────────────────────

    func uploadImage(_ image: UIImage, userID: String? = nil) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotCreateFile)
        }
        return try await uploadImageData(data, path: nil, userID: userID)
    }

    func uploadImageData(_ data: Data, path: String? = nil, userID: String? = nil) async throws -> String {
        let storagePath = path ?? "\(userID ?? "misc")/\(UUID().uuidString).jpg"
        try await sb.storage
            .from("moments")
            .upload(path: storagePath, file: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: true))
        let url = try sb.storage.from("moments").getPublicURL(path: storagePath)
        return url.absoluteString
    }

    // ─────────────────────────────────────────────────────
    // MARK: Follow (FollowButton에서 직접 호출)
    // ─────────────────────────────────────────────────────

    func routeFollow(followerID: String, followingID: String) async throws {
        try await followUser(followerID: followerID, followingID: followingID)
    }

    func routeUnfollow(followerID: String, followingID: String) async throws {
        try await unfollowUser(followerID: followerID, followingID: followingID)
    }

    // ─────────────────────────────────────────────────────
    // MARK: 하위 호환
    // ─────────────────────────────────────────────────────

    func socialLogin(provider: String, code: String) async throws -> SocialAuthResponse {
        throw APIError.httpError(501, "Use AuthService.shared instead")
    }
}

// MARK: - 경로 라우터

private extension APIClient {

    // ── GET ──────────────────────────────────────────────

    func routeGet<T: Decodable>(_ path: String, params: [String: String], viewerID: String?) async throws -> T {
        let limit  = Int(params["limit"]  ?? "20") ?? 20
        let offset = Int(params["offset"] ?? "0")  ?? 0

        switch true {

        case path == "/moments":
            return try forceCast(try await fetchMomentFeed(limit: limit, offset: offset))

        case path == "/moments/matched":
            guard let uid = viewerID else { throw APIError.invalidResponse }
            let lat = params["lat"].flatMap(Double.init)
            let lng = params["lng"].flatMap(Double.init)
            return try forceCast(try await fetchMatchedFeed(userID: uid, lat: lat, lng: lng))

        case path.hasPrefix("/moments/tag/"):
            let tag  = String(path.dropFirst("/moments/tag/".count))
            let sort = params["sort"] ?? "latest"
            return try forceCast(try await fetchMomentsByTag(tag, sort: sort, limit: limit, offset: offset))

        case path.hasSuffix("/waves") && path.hasPrefix("/moments/"):
            let mid = segment(path, prefix: "/moments/", suffix: "/waves")
            return try forceCast(try await fetchWaves(momentID: mid))

        case path.hasSuffix("/wave-map"):
            let mid = segment(path, prefix: "/moments/", suffix: "/wave-map")
            return try forceCast(try await fetchWaveMap(momentID: mid))

        case path.hasSuffix("/comments") && path.hasPrefix("/moments/"):
            let mid = segment(path, prefix: "/moments/", suffix: "/comments")
            return try forceCast(try await fetchComments(momentID: mid))

        case path.hasSuffix("/top-comment"):
            let mid = segment(path, prefix: "/moments/", suffix: "/top-comment")
            let top = try await fetchTopComment(momentID: mid)
            return try forceCast(top)

        case path.hasPrefix("/moments/") && !path.dropFirst("/moments/".count).contains("/"):
            let mid = String(path.dropFirst("/moments/".count))
            return try forceCast(try await fetchMoment(id: mid))

        case path.hasSuffix("/moments") && path.hasPrefix("/users/"):
            let uid = segment(path, prefix: "/users/", suffix: "/moments")
            return try forceCast(try await fetchMomentsByUser(uid))

        case path.hasSuffix("/followers"):
            let uid = segment(path, prefix: "/users/", suffix: "/followers")
            return try forceCast(try await fetchFollowers(profileUserID: uid, viewerID: viewerID))

        case path.hasSuffix("/following"):
            let uid = segment(path, prefix: "/users/", suffix: "/following")
            return try forceCast(try await fetchFollowing(profileUserID: uid, viewerID: viewerID))

        case path.hasSuffix("/follow-stats"):
            let uid = segment(path, prefix: "/users/", suffix: "/follow-stats")
            return try forceCast(try await fetchFollowStats(userID: uid))

        case path.hasSuffix("/mutual-follows"):
            let uid = segment(path, prefix: "/users/", suffix: "/mutual-follows")
            return try forceCast(try await fetchMutualFollows(userID: uid, viewerID: viewerID))

        case path.hasPrefix("/users/") && !path.dropFirst("/users/".count).contains("/"):
            let uid = String(path.dropFirst("/users/".count))
            return try forceCast(try await fetchUser(id: uid))

        case path == "/graph/me":
            guard let uid = viewerID else { throw APIError.invalidResponse }
            return try forceCast(try await fetchGraphNode(userID: uid))

        case path == "/graph/similar":
            guard let uid = viewerID else { throw APIError.invalidResponse }
            return try forceCast(try await fetchSimilarUsers(userID: uid))

        default:
            throw APIError.httpError(404, "Unknown path: \(path)")
        }
    }

    // ── POST ─────────────────────────────────────────────

    func routePost<Body: Encodable, T: Decodable>(
        _ path: String, body: Body, actorID: String?
    ) async throws -> T {
        switch true {

        case path == "/moments":
            guard let uid = actorID,
                  let req = body as? CreateMomentRequest else { throw APIError.invalidResponse }
            return try forceCast(try await createMoment(req, userID: uid))

        case path.hasSuffix("/wave") && path.hasPrefix("/moments/"):
            let mid = segment(path, prefix: "/moments/", suffix: "/wave")
            guard let uid = actorID else { throw APIError.invalidResponse }
            let req = decodeBody(body, as: WaveBody.self)
            return try forceCast(try await createWave(
                momentID: mid, userID: uid,
                body: req?.body, imageUrl: req?.imageUrl,
                lat: req?.latitude, lng: req?.longitude))

        case path.hasSuffix("/comments") && path.hasPrefix("/moments/"):
            let mid = segment(path, prefix: "/moments/", suffix: "/comments")
            guard let uid = actorID else { throw APIError.invalidResponse }
            let req = decodeBody(body, as: CommentBody.self)
            return try forceCast(try await createComment(
                momentID: mid, userID: uid, body: req?.body, imageUrl: req?.imageUrl))

        case path.hasSuffix("/like") && path.hasPrefix("/comments/"):
            let cid = segment(path, prefix: "/comments/", suffix: "/like")
            guard let uid = actorID else { throw APIError.invalidResponse }
            try await likeComment(commentID: cid, userID: uid)
            return try forceCast(VoidResponse())

        case path.hasSuffix("/follow") && path.hasPrefix("/users/"):
            let tid = segment(path, prefix: "/users/", suffix: "/follow")
            guard let uid = actorID else { throw APIError.invalidResponse }
            let rel = try await followUser(followerID: uid, followingID: tid)
            return try forceCast(rel)

        case path == "/users":
            guard let uid = actorID,
                  let req = decodeBody(body, as: UserBody.self) else { throw APIError.invalidResponse }
            return try forceCast(try await updateUser(
                id: uid, nickname: req.nickname, profileImageUrl: req.profileImageUrl))

        default:
            throw APIError.httpError(404, "Unknown POST path: \(path)")
        }
    }

    // ── PUT ──────────────────────────────────────────────

    func routePut<Body: Encodable, T: Decodable>(
        _ path: String, body: Body, actorID: String?
    ) async throws -> T {
        if path.hasPrefix("/users/") {
            let uid = String(path.dropFirst("/users/".count))
            guard let req = decodeBody(body, as: UserBody.self) else { throw APIError.invalidResponse }
            return try forceCast(try await updateUser(
                id: uid, nickname: req.nickname, profileImageUrl: req.profileImageUrl))
        }
        throw APIError.httpError(404, "Unknown PUT path: \(path)")
    }

    // ── DELETE ───────────────────────────────────────────

    func routeDelete(_ path: String, actorID: String?) async throws {
        switch true {
        case path.hasSuffix("/wave") && path.hasPrefix("/moments/"):
            let mid = segment(path, prefix: "/moments/", suffix: "/wave")
            guard let uid = actorID else { throw APIError.invalidResponse }
            try await deleteWave(momentID: mid, userID: uid)

        case path.hasSuffix("/like") && path.hasPrefix("/comments/"):
            let cid = segment(path, prefix: "/comments/", suffix: "/like")
            guard let uid = actorID else { throw APIError.invalidResponse }
            try await unlikeComment(commentID: cid, userID: uid)

        case path.hasSuffix("/follow") && path.hasPrefix("/users/"):
            let tid = segment(path, prefix: "/users/", suffix: "/follow")
            guard let uid = actorID else { throw APIError.invalidResponse }
            try await unfollowUser(followerID: uid, followingID: tid)

        default:
            throw APIError.httpError(404, "Unknown DELETE path: \(path)")
        }
    }
}

// MARK: - Supabase 데이터 작업

private extension APIClient {

    // ── Moments ──────────────────────────────────────────

    func fetchMomentFeed(limit: Int = 20, offset: Int = 0) async throws -> [Moment] {
        try await sb.from("moment_feed")
            .select()
            .gt("expires_at", value: isoNow())
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute().value
    }

    func fetchMoment(id: String) async throws -> Moment {
        let results: [Moment] = try await sb.from("moment_feed")
            .select().eq("id", value: id).execute().value
        guard let m = results.first else { throw APIError.notFound }
        return m
    }

    func fetchMomentsByUser(_ userID: String) async throws -> [Moment] {
        try await sb.from("moment_feed")
            .select()
            .eq("user_id", value: userID)
            .order("created_at", ascending: false)
            .execute().value
    }

    func fetchMomentsByTag(_ tag: String, sort: String, limit: Int, offset: Int) async throws -> [Moment] {
        struct TagRow: Decodable { let momentId: String }
        let rows: [TagRow] = try await sb.from("moment_tags")
            .select("moment_id").eq("tag", value: tag).execute().value
        let ids = rows.map { $0.momentId }
        guard !ids.isEmpty else { return [] }

        if sort == "waves" {
            return try await sb.from("moment_feed")
                .select()
                .in("id", values: ids)
                .gt("expires_at", value: isoNow())
                .order("wave_count", ascending: false)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute().value
        } else {
            return try await sb.from("moment_feed")
                .select()
                .in("id", values: ids)
                .gt("expires_at", value: isoNow())
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute().value
        }
    }

    func fetchMatchedFeed(userID: String, lat: Double?, lng: Double?, limit: Int = 20) async throws -> [Moment] {
        let candidates: [Moment] = try await sb
            .rpc("get_matching_candidates", params: [
                "p_exclude_user_id": AnyJSON.string(userID),
                "p_limit": AnyJSON.integer(500)
            ])
            .execute().value

        struct TagRow: Decodable { let tag: String }
        let tagRows: [TagRow] = try await sb
            .rpc("get_user_top_tags", params: [
                "p_user_id": AnyJSON.string(userID),
                "p_limit": AnyJSON.integer(10)
            ])
            .execute().value
        let userTags = tagRows.map { $0.tag }

        let now = Date()
        let refHour = Calendar.current.component(.hour, from: now)
        let refTime = Calendar.current.date(bySettingHour: refHour, minute: 0, second: 0, of: now) ?? now

        struct Scored { let moment: Moment; let score: Double }
        var scored: [Scored] = []
        for var m in candidates {
            let total = tagScore(userTags, m.tags ?? []) * 0.50
                      + timeScore(refTime, m.createdAt) * 0.30
                      + distanceScore(lat, lng, m.latitude, m.longitude) * 0.20
            if total >= 0.40 {
                m.matchScore = total
                scored.append(Scored(moment: m, score: total))
            }
        }
        return scored.sorted { $0.score > $1.score }.prefix(limit).map { $0.moment }
    }

    func createMoment(_ req: CreateMomentRequest, userID: String) async throws -> Moment {
        struct Insert: Encodable {
            let userId, contentType: String
            let body, imageUrl, thumbnailUrl, location: String?
            let latitude, longitude: Double?
            let youtubeVideoId, youtubeThumbnail, youtubeTitle: String?
        }
        struct MID: Decodable { let id: String }
        let rows: [MID] = try await sb.from("moments")
            .insert(Insert(userId: userID,
                           contentType: req.contentType ?? "photo",
                           body: req.body, imageUrl: req.imageUrl,
                           thumbnailUrl: req.thumbnailUrl, location: req.location,
                           latitude: req.latitude, longitude: req.longitude,
                           youtubeVideoId: req.youtubeVideoId,
                           youtubeThumbnail: req.youtubeThumbnail,
                           youtubeTitle: req.youtubeTitle))
            .select("id").execute().value
        guard let mid = rows.first?.id else { throw APIError.invalidResponse }

        struct TagInsert: Encodable { let momentId, tag: String }
        if !req.tags.isEmpty {
            try await sb.from("moment_tags")
                .insert(req.tags.map { TagInsert(momentId: mid, tag: $0) })
                .execute()
        }
        return try await fetchMoment(id: mid)
    }

    // ── Waves ────────────────────────────────────────────

    func fetchWaves(momentID: String) async throws -> [Wave] {
        try await sb.from("waves_with_author")
            .select().eq("moment_id", value: momentID)
            .order("created_at", ascending: false).execute().value
    }

    func fetchWaveMap(momentID: String) async throws -> [APIPoint] {
        struct Pt: Decodable { let latitude: Double?; let longitude: Double? }
        let pts: [Pt] = try await sb.from("waves")
            .select("latitude, longitude").eq("moment_id", value: momentID)
            .not("latitude", operator: .is, value: "null").execute().value
        return pts.compactMap {
            guard let la = $0.latitude, let lo = $0.longitude else { return nil }
            return APIPoint(latitude: la, longitude: lo)
        }
    }

    func createWave(momentID: String, userID: String, body: String?, imageUrl: String?,
                    lat: Double?, lng: Double?) async throws -> Wave {
        struct Ins: Encodable {
            let momentId, userId: String
            let body, imageUrl: String?
            let latitude, longitude: Double?
        }
        struct WID: Decodable { let id: String }
        let rows: [WID] = try await sb.from("waves")
            .insert(Ins(momentId: momentID, userId: userID,
                        body: body, imageUrl: imageUrl, latitude: lat, longitude: lng))
            .select("id").execute().value
        guard let wid = rows.first?.id else { throw APIError.invalidResponse }
        let waves: [Wave] = try await sb.from("waves_with_author")
            .select().eq("id", value: wid).execute().value
        guard let w = waves.first else { throw APIError.invalidResponse }
        return w
    }

    func deleteWave(momentID: String, userID: String) async throws {
        try await sb.from("waves")
            .delete().eq("moment_id", value: momentID).eq("user_id", value: userID)
            .execute()
    }

    // ── Comments ─────────────────────────────────────────

    func fetchComments(momentID: String) async throws -> [Comment] {
        try await sb.from("comments_with_author")
            .select().eq("moment_id", value: momentID)
            .order("created_at", ascending: true).execute().value
    }

    func fetchTopComment(momentID: String) async throws -> Comment? {
        let rows: [Comment] = try await sb.from("comments_with_author")
            .select().eq("moment_id", value: momentID)
            .order("like_count", ascending: false)
            .order("created_at", ascending: true)
            .limit(1).execute().value
        return rows.first
    }

    func createComment(momentID: String, userID: String, body: String?, imageUrl: String?) async throws -> Comment {
        struct Ins: Encodable { let momentId, userId: String; let body, imageUrl: String? }
        struct CID: Decodable { let id: String }
        let rows: [CID] = try await sb.from("comments")
            .insert(Ins(momentId: momentID, userId: userID, body: body, imageUrl: imageUrl))
            .select("id").execute().value
        guard let cid = rows.first?.id else { throw APIError.invalidResponse }
        let comments: [Comment] = try await sb.from("comments_with_author")
            .select().eq("id", value: cid).execute().value
        guard let c = comments.first else { throw APIError.invalidResponse }
        return c
    }

    func likeComment(commentID: String, userID: String) async throws {
        struct Ins: Encodable { let commentId, userId: String }
        try await sb.from("comment_likes")
            .insert(Ins(commentId: commentID, userId: userID)).execute()
    }

    func unlikeComment(commentID: String, userID: String) async throws {
        try await sb.from("comment_likes")
            .delete().eq("comment_id", value: commentID).eq("user_id", value: userID)
            .execute()
    }

    // ── Users ────────────────────────────────────────────

    func fetchUser(id: String) async throws -> User {
        let rows: [User] = try await sb.from("users")
            .select().eq("id", value: id).execute().value
        guard let u = rows.first else { throw APIError.notFound }
        return u
    }

    func updateUser(id: String, nickname: String, profileImageUrl: String?) async throws -> User {
        struct Upd: Encodable { let nickname: String; let profileImageUrl: String? }
        let rows: [User] = try await sb.from("users")
            .update(Upd(nickname: nickname, profileImageUrl: profileImageUrl))
            .eq("id", value: id).select().execute().value
        guard let u = rows.first else { throw APIError.notFound }
        return u
    }

    // ── Follows ──────────────────────────────────────────

    func fetchFollowers(profileUserID: String, viewerID: String?) async throws -> [FollowUser] {
        struct R: Decodable { let followerId: String }
        let rows: [R] = try await sb.from("follows")
            .select("follower_id").eq("following_id", value: profileUserID).execute().value
        return try await buildFollowUsers(ids: rows.map { $0.followerId }, viewerID: viewerID)
    }

    func fetchFollowing(profileUserID: String, viewerID: String?) async throws -> [FollowUser] {
        struct R: Decodable { let followingId: String }
        let rows: [R] = try await sb.from("follows")
            .select("following_id").eq("follower_id", value: profileUserID).execute().value
        return try await buildFollowUsers(ids: rows.map { $0.followingId }, viewerID: viewerID)
    }

    func fetchFollowStats(userID: String) async throws -> FollowStats {
        let frResp = try await sb.from("follows")
            .select("*", count: .exact).eq("following_id", value: userID).limit(0).execute()
        let fgResp = try await sb.from("follows")
            .select("*", count: .exact).eq("follower_id", value: userID).limit(0).execute()
        return FollowStats(followerCount: frResp.count ?? 0, followingCount: fgResp.count ?? 0)
    }

    func fetchMutualFollows(userID: String, viewerID: String?) async throws -> [FollowUser] {
        struct R1: Decodable { let followingId: String }
        struct R2: Decodable { let followerId:  String }
        let iFollow: [R1] = try await sb.from("follows")
            .select("following_id").eq("follower_id", value: userID).execute().value
        let iIDs = iFollow.map { $0.followingId }
        guard !iIDs.isEmpty else { return [] }
        let followMe: [R2] = try await sb.from("follows")
            .select("follower_id").eq("following_id", value: userID)
            .in("follower_id", values: iIDs).execute().value
        return try await buildFollowUsers(ids: followMe.map { $0.followerId }, viewerID: viewerID)
    }

    func buildFollowUsers(ids: [String], viewerID: String?) async throws -> [FollowUser] {
        guard !ids.isEmpty else { return [] }
        let users: [User] = try await sb.from("users")
            .select().in("id", values: ids).execute().value

        var viewerFollowing: Set<String> = []
        if let vID = viewerID {
            struct R: Decodable { let followingId: String }
            let rows: [R] = try await sb.from("follows")
                .select("following_id").eq("follower_id", value: vID)
                .in("following_id", values: ids).execute().value
            viewerFollowing = Set(rows.map { $0.followingId })
        }
        return users.map {
            FollowUser(id: $0.id, nickname: $0.nickname, profileImageUrl: $0.profileImageUrl,
                       isFollowing: viewerFollowing.contains($0.id),
                       followerCount: 0, followingCount: 0)
        }
    }

    func followUser(followerID: String, followingID: String) async throws -> FollowRelation {
        struct Ins: Encodable { let followerId, followingId: String }
        let rows: [FollowRelation] = try await sb.from("follows")
            .insert(Ins(followerId: followerID, followingId: followingID))
            .select().execute().value
        guard let rel = rows.first else { throw APIError.invalidResponse }
        return rel
    }

    func unfollowUser(followerID: String, followingID: String) async throws {
        try await sb.from("follows")
            .delete().eq("follower_id", value: followerID).eq("following_id", value: followingID)
            .execute()
    }

    // ── Graph ────────────────────────────────────────────

    func fetchGraphNode(userID: String) async throws -> GraphNode {
        struct Raw: Decodable {
            let userId: String; let connections: [Connection]; let topTags: [TagWeight]
        }
        let raw: Raw = try await sb
            .rpc("get_graph_node", params: ["p_user_id": AnyJSON.string(userID)])
            .execute().value
        let user = try await fetchUser(id: userID)
        return GraphNode(userId: raw.userId, nickname: user.nickname,
                         connections: raw.connections, topTags: raw.topTags)
    }

    func fetchSimilarUsers(userID: String) async throws -> [SimilarUser] {
        return try await sb
            .rpc("get_similar_users", params: ["p_user_id": AnyJSON.string(userID)])
            .execute().value
    }
}

// MARK: - 매칭 알고리즘 (Go scorer 포팅)

private extension APIClient {
    func tagScore(_ a: [String], _ b: [String]) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        let setA = Set(a)
        let common = b.filter { setA.contains($0) }.count
        return Double(common) / max(Double(a.count), Double(b.count))
    }
    func timeScore(_ a: Date, _ b: Date) -> Double {
        var d = abs(Calendar.current.component(.hour, from: a) - Calendar.current.component(.hour, from: b))
        if d > 12 { d = 24 - d }
        return d <= 1 ? 1.0 : d == 2 ? 0.5 : 0.0
    }
    func distanceScore(_ lat1: Double?, _ lng1: Double?, _ lat2: Double?, _ lng2: Double?) -> Double {
        guard let la1 = lat1, let lo1 = lng1, let la2 = lat2, let lo2 = lng2 else { return 0.5 }
        let d = haversineKm(la1, lo1, la2, lo2)
        return d <= 0.5 ? 1.0 : d <= 2.0 ? 0.7 : d <= 5.0 ? 0.4 : 0.0
    }
    func haversineKm(_ la1: Double, _ lo1: Double, _ la2: Double, _ lo2: Double) -> Double {
        let R = 6371.0, p1 = la1 * .pi/180, p2 = la2 * .pi/180
        let dp = (la2-la1) * .pi/180, dl = (lo2-lo1) * .pi/180
        let a = sin(dp/2)*sin(dp/2) + cos(p1)*cos(p2)*sin(dl/2)*sin(dl/2)
        return R * 2 * atan2(sqrt(a), sqrt(1-a))
    }
}

// MARK: - 유틸

private extension APIClient {

    func isoNow() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    func splitPath(_ raw: String) -> (path: String, params: [String: String]) {
        let parts = raw.split(separator: "?", maxSplits: 1)
        let path = String(parts[0])
        var params: [String: String] = [:]
        if parts.count > 1 {
            for pair in parts[1].split(separator: "&") {
                let kv = pair.split(separator: "=", maxSplits: 1)
                if kv.count == 2 {
                    params[String(kv[0])] = String(kv[1]).removingPercentEncoding ?? String(kv[1])
                }
            }
        }
        return (path, params)
    }

    func segment(_ path: String, prefix: String, suffix: String) -> String {
        var s = path
        if s.hasPrefix(prefix) { s = String(s.dropFirst(prefix.count)) }
        if s.hasSuffix(suffix)  { s = String(s.dropLast(suffix.count)) }
        return s
    }

    /// 런타임 타입 캐스팅 (A와 T가 같은 타입일 때 성공)
    func forceCast<A, T: Decodable>(_ value: A) throws -> T {
        guard let result = value as? T else { throw APIError.invalidResponse }
        return result
    }

    func decodeBody<B: Encodable, D: Decodable>(_ body: B, as type: D.Type) -> D? {
        guard let data = try? JSONEncoder().encode(body) else { return nil }
        return try? JSONDecoder.param.decode(D.self, from: data)
    }
}

// MARK: - 내부 DTO

private struct WaveBody:    Decodable { var body: String?; var imageUrl: String?; var latitude: Double?; var longitude: Double? }
private struct CommentBody: Decodable { var body: String?; var imageUrl: String? }
private struct UserBody:    Decodable { var nickname: String; var profileImageUrl: String? }

private struct VoidResponse: Codable {}


// MARK: - JSONDecoder

extension JSONDecoder {
    static let param: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let str = try decoder.singleValueContainer().decode(String.self)
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = f.date(from: str) { return date }
            f.formatOptions = [.withInternetDateTime]
            if let date = f.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(),
                debugDescription: "Invalid date: \(str)")
        }
        return d
    }()
}
