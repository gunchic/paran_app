import SwiftUI

struct CreateWaveView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @FocusState private var isTextFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.void.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    TextEditor(text: $text)
                        .focused($isTextFocused)
                        .foregroundColor(.mist)
                        .scrollContentBackground(.hidden)
                        .background(Color.surfaceHighest)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                        .frame(minHeight: 160)

                    Spacer()
                }
                .padding(Spacing.md)
            }
            .navigationTitle("파람 올리기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .buttonStyle(.paramGhost)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("올리기") {
                        // TODO: Wave 저장
                        dismiss()
                    }
                    .buttonStyle(.paramPrimary)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { isTextFocused = true }
    }
}
