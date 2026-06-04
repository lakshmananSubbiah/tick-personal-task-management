import SwiftUI
import SwiftData

/// Create a new project ("tab") with a name, color, and SF Symbol icon.
/// Emoji icons are supported by the model (`emoji:` token) — a richer picker is
/// a V1.1 polish item.
struct ProjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Project.sortOrder) private var existing: [Project]

    @State private var name: String = ""
    @State private var colorHex: String = Theme.projectColors[0]
    @State private var symbolName: String = "folder"

    private let symbolOptions = [
        "folder", "briefcase.fill", "house.fill", "cart.fill",
        "book.fill", "heart.fill", "star.fill", "flag.fill",
        "bolt.fill", "leaf.fill", "airplane", "gamecontroller.fill"
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("New Project").font(.headline)

            TextField("Project name", text: $name)
                .textFieldStyle(.roundedBorder)

            colorSwatches
            symbolGrid

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(width: 380)
        .background(.ultraThinMaterial)
    }

    private var colorSwatches: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(Theme.projectColors, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if hex == colorHex {
                            Circle().stroke(.primary, lineWidth: 2).padding(-3)
                        }
                    }
                    .onTapGesture { colorHex = hex }
            }
        }
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Theme.Spacing.md) {
            ForEach(symbolOptions, id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .foregroundStyle(symbol == symbolName ? Color(hex: colorHex) : .secondary)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.pill)
                            .fill(symbol == symbolName ? Color(hex: colorHex).opacity(0.15) : .clear)
                    )
                    .onTapGesture { symbolName = symbol }
            }
        }
    }

    private func create() {
        let project = Project(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            iconToken: "sf:\(symbolName)",
            sortOrder: existing.count
        )
        context.insert(project)
        try? context.save()
        dismiss()
    }
}

#Preview {
    ProjectEditorView()
        .modelContainer(AppModelContainer.preview)
}
