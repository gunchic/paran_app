import SwiftUI

struct CrewCreateView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var crewName: String = ""
    @State private var crewType: String = "keyword"
    @State private var description: String = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("크루 이름")
                            .captionStyle()
                            .foregroundColor(.ash)

                        TextField("선점할 단어 또는 문장", text: $crewName)
                            .focused($isNameFocused)
                            .foregroundColor(.void)
                            .paramInput(isFocused: isNameFocused)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("크루 타입")
                            .captionStyle()
                            .foregroundColor(.ash)

                        Picker("크루 타입", selection: $crewType) {
                            Text("키워드").tag("keyword")
                            Text("감정").tag("emotion")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("설명 (선택)")
                            .captionStyle()
                            .foregroundColor(.ash)

                        TextEditor(text: $description)
                            .foregroundColor(.void)
                            .scrollContentBackground(.hidden)
                            .background(Color.surfaceHighest)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                            .frame(minHeight: 100)
                    }

                    Spacer()
                }
                .padding(Spacing.md)
            }
            .navigationTitle("크루 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .buttonStyle(.paramGhost)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("만들기") {
                        // TODO: 크루 생성
                        dismiss()
                    }
                    .buttonStyle(.paramPrimary)
                    .disabled(crewName.isEmpty)
                }
            }
        }
        .onAppear { isNameFocused = true }
    }
}
