import SwiftUI
import PhotosUI

// MARK: - ContentType

enum MomentContentType: CaseIterable {
    case photo, youtube, text

    var label: String {
        switch self {
        case .photo:   return "📷 사진"
        case .youtube: return "▶ YouTube"
        case .text:    return "📝 텍스트만"
        }
    }

    var apiValue: String {
        switch self {
        case .photo:   return "photo"
        case .youtube: return "youtube"
        case .text:    return "text"
        }
    }
}

// MARK: - View

struct CreateMomentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // 공통
    @State private var bodyText = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var isPosting = false
    @State private var errorMessage: String?
    @State private var showError = false

    // 콘텐츠 타입
    @State private var contentType: MomentContentType = .photo

    // 사진
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?        // 원본 (PhotosPicker에서 받은 것)
    @State private var compressed: ImageCompressor.Result? = nil
    @State private var isCompressing = false

    // YouTube
    @State private var youtubeURL = ""
    @State private var youtubeVideoId: String? = nil
    @State private var youtubeThumbnail: String? = nil
    @State private var youtubeTitle: String? = nil
    @State private var youtubeURLError: String? = nil
    @State private var isFetchingTitle = false

    // MARK: - 발신 버튼 활성화 조건

    private var canPost: Bool {
        switch contentType {
        case .photo:   return !bodyText.isEmpty || selectedImage != nil
        case .youtube: return !bodyText.isEmpty && youtubeVideoId != nil
        case .text:    return !bodyText.isEmpty
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── 콘텐츠 타입 선택 ──────────────────────
                Picker("콘텐츠 유형", selection: $contentType) {
                    ForEach(MomentContentType.allCases, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: contentType) { _, _ in
                    // 탭 전환 시 각 타입의 상태 초기화
                    youtubeURLError = nil
                }

                // ── 본문 텍스트 ───────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("지금 뭐 하고 있어?")
                        .font(.headline)
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                // ── 타입별 콘텐츠 입력 ────────────────────
                switch contentType {
                case .photo:
                    photoSection
                case .youtube:
                    youtubeSection
                case .text:
                    EmptyView()
                }

                // ── 태그 ─────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("태그")
                        .font(.headline)
                    HStack {
                        TextField("#태그 추가", text: $tagInput)
                            .onSubmit { addTag() }
                        Button("추가", action: addTag)
                            .disabled(tagInput.isEmpty)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    if !tags.isEmpty {
                        HStack(spacing: Spacing.sm) {
                            ForEach(tags, id: \.self) { tag in
                                TagPill(text: tag, variant: .default) {
                                    tags.removeAll { $0 == tag }
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .alert("업로드 실패", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류")
        }
        .background(Color.driftwood.ignoresSafeArea())
        .navigationTitle("파동 일으키기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: post) {
                    if isPosting { ProgressView() } else { Text("올리기").bold() }
                }
                .disabled(!canPost || isPosting)
            }
        }
    }

    // MARK: - 사진 섹션

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("사진")
                .font(.headline)
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                if let image = selectedImage {
                    ZStack {
                        // 썸네일 미리보기 (압축 완료 시) 또는 원본
                        let preview: UIImage = {
                            if let d = compressed?.thumbnail, let img = UIImage(data: d) { return img }
                            return image
                        }()
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                            .cornerRadius(12)

                        // 압축 중 로딩 오버레이
                        if isCompressing {
                            Color.black.opacity(0.4)
                                .cornerRadius(12)
                            VStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("이미지 처리 중...")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Image(systemName: "photo.badge.plus")
                        Text("사진 추가")
                        Spacer()
                    }
                    .frame(height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .foregroundColor(.secondary)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    guard let data = try? await item?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    selectedImage = image
                    compressed = nil
                    isCompressing = true
                    compressed = await ImageCompressor.compress(image)
                    isCompressing = false
                }
            }
        }
    }

    // MARK: - YouTube 섹션

    private var youtubeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YouTube 링크")
                .font(.headline)

            // URL 입력
            HStack {
                TextField("YouTube 링크를 붙여넣어 주세요", text: $youtubeURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .onChange(of: youtubeURL) { _, url in
                        handleYouTubeURLChange(url)
                    }
                if !youtubeURL.isEmpty {
                    Button(action: {
                        youtubeURL = ""
                        youtubeVideoId = nil
                        youtubeThumbnail = nil
                        youtubeTitle = nil
                        youtubeURLError = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // 에러
            if let error = youtubeURLError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.signalRed)
            }

            // 제목 로딩 중
            if isFetchingTitle {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("영상 정보 가져오는 중...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // YoutubeCard 미리보기
            if let videoId = youtubeVideoId {
                VStack(alignment: .leading, spacing: 6) {
                    Text("미리보기")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    YouTubeCard(
                        videoId: videoId,
                        title: youtubeTitle,
                        thumbnail: youtubeThumbnail,
                        autoPlay: false
                    )
                }
            }
        }
    }

    // MARK: - Actions

    func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespaces)
        if !tag.isEmpty && !tags.contains(tag) { tags.append(tag) }
        tagInput = ""
    }

    private func handleYouTubeURLChange(_ url: String) {
        // 상태 초기화
        youtubeVideoId = nil
        youtubeThumbnail = nil
        youtubeTitle = nil
        youtubeURLError = nil

        guard !url.isEmpty else { return }

        guard YouTubeUtils.isYouTubeURL(url) else {
            youtubeURLError = "올바른 YouTube 링크가 아닙니다"
            return
        }
        guard let videoId = YouTubeUtils.extractVideoId(from: url) else {
            youtubeURLError = "영상 ID를 추출할 수 없습니다"
            return
        }

        youtubeVideoId  = videoId
        youtubeThumbnail = YouTubeUtils.thumbnailURL(videoId: videoId)

        // 제목 비동기 fetch
        isFetchingTitle = true
        Task {
            youtubeTitle    = await YouTubeUtils.fetchTitle(videoId: videoId)
            isFetchingTitle = false
        }
    }

    func post() {
        guard let userID = appState.currentUserID else {
            errorMessage = "로그인 정보가 없습니다"
            return
        }
        isPosting = true
        errorMessage = nil
        Task {
            do {
                // 이미지 업로드 (사진 탭일 때만)
                // 압축본이 있으면 thumbnail + image 두 버전 업로드, 없으면 원본 단일 업로드
                var imageUrl: String?     = nil
                var thumbnailUrl: String? = nil
                if contentType == .photo {
                    let momentPath = "waves/\(userID)/\(UUID().uuidString)"
                    if let c = compressed {
                        async let thumbUpload = APIClient.shared.uploadImageData(
                            c.thumbnail,
                            path: "\(momentPath)/thumbnail.jpg",
                            userID: userID
                        )
                        async let imageUpload = APIClient.shared.uploadImageData(
                            c.image,
                            path: "\(momentPath)/image.jpg",
                            userID: userID
                        )
                        thumbnailUrl = try await thumbUpload
                        imageUrl     = try await imageUpload
                    } else if let image = selectedImage {
                        imageUrl = try await APIClient.shared.uploadImage(image, userID: userID)
                    }
                }

                // 위치 비동기 취득 (최대 3초, 선택)
                let loc = await LocationManager.shared.locationAsync(timeout: 3.0)

                // 입력 중인 태그 자동 커밋 (Enter/추가 누르지 않은 경우 대비)
                let pendingTag = tagInput.trimmingCharacters(in: .whitespaces)
                if !pendingTag.isEmpty && !tags.contains(pendingTag) {
                    tags.append(pendingTag)
                    tagInput = ""
                }

                // 본문에서 #태그 자동 파싱 → 수동 추가된 태그와 병합
                let bodyParsedTags = parseHashtags(from: bodyText)
                let allTags = tags + bodyParsedTags.filter { !tags.contains($0) }

                let req = CreateMomentRequest(
                    body: bodyText.isEmpty ? nil : bodyText,
                    imageUrl: imageUrl,
                    thumbnailUrl: thumbnailUrl,
                    location: nil,
                    latitude: loc?.coordinate.latitude,
                    longitude: loc?.coordinate.longitude,
                    tags: allTags,
                    contentType: contentType.apiValue,
                    youtubeVideoId: youtubeVideoId,
                    youtubeThumbnail: youtubeThumbnail,
                    youtubeTitle: youtubeTitle
                )
                let _: Moment = try await APIClient.shared.post("/moments", body: req, userID: userID)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPosting = false
        }
    }

    /// 텍스트에서 #태그 파싱 (# 뒤 공백/# 전까지)
    private func parseHashtags(from text: String) -> [String] {
        let pattern = try? NSRegularExpression(pattern: "#([^\\s#]+)")
        let nsText  = text as NSString
        let matches = pattern?.matches(in: text, range: NSRange(location: 0, length: nsText.length)) ?? []
        return matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            guard range.location != NSNotFound else { return nil }
            return nsText.substring(with: range)
        }
    }
}
