import Foundation
import Combine

/// 피드 목록과 상세화면 간 파동 카운트/상태를 동기화하는 공유 저장소
final class WaveStore: ObservableObject {
    static let shared = WaveStore()

    // momentID → wave count
    @Published private(set) var counts: [String: Int] = [:]
    // 현재 유저가 파동한 momentID 집합
    @Published private(set) var wavedIDs: Set<String> = []

    private let persistKey = "waved_moment_ids"

    private init() {
        // UserDefaults에서 이전 세션 공감 목록 복원
        if let stored = UserDefaults.standard.array(forKey: persistKey) as? [String] {
            wavedIDs = Set(stored)
        }
    }

    func count(for momentID: String) -> Int {
        counts[momentID] ?? 0
    }

    func hasWaved(_ momentID: String) -> Bool {
        wavedIDs.contains(momentID)
    }

    /// 서버에서 받아온 실제 카운트로 덮어쓰기
    func setCount(_ count: Int, for momentID: String) {
        counts[momentID] = count
    }

    /// 피드 목록 일괄 초기화 (서버 응답 기준)
    func seed(moments: [Moment]) {
        for m in moments {
            counts[m.id] = max(counts[m.id] ?? 0, m.waveCount)
        }
    }

    /// 파동 발생 — 낙관적 업데이트
    func recordWave(momentID: String) {
        wavedIDs.insert(momentID)
        counts[momentID] = (counts[momentID] ?? 0) + 1
        persist()
    }

    /// 파동 취소 — 낙관적 롤백 (서버 실패 시 recordWave로 복구)
    func rollback(momentID: String) {
        wavedIDs.remove(momentID)
        counts[momentID] = max(0, (counts[momentID] ?? 0) - 1)
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(wavedIDs), forKey: persistKey)
    }
}
