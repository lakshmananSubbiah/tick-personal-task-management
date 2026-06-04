import SwiftUI
import SwiftData

/// Create/edit sheet for a task. Glassy card with priority, due date+time, and
/// a reminder toggle.
struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notifications

    @State private var model: TaskEditorViewModel

    init(mode: TaskEditorMode) {
        _model = State(initialValue: TaskEditorViewModel(mode: mode))
    }

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Task title", text: $model.title)
                        .textFieldStyle(.plain)
                        .font(.title3)
                    TextField("Notes", text: $model.notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(2...5)
                }

                Section {
                    Picker("Priority", selection: $model.priority) {
                        ForEach(Priority.allCases) { priority in
                            Label(priority.shortLabel, systemImage: priority.symbolName)
                                .tag(priority)
                        }
                    }

                    Toggle("Due date", isOn: $model.hasDueDate.animation())
                    if model.hasDueDate {
                        DatePicker("When", selection: $model.dueDate,
                                   displayedComponents: [.date, .hourAndMinute])
                        Toggle("Remind me at due time", isOn: $model.hasReminder)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(model.isEditing ? "Save" : "Add Task") {
                    Task {
                        await model.save(context: context, notifications: notifications)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!model.canSave)
                .buttonStyle(.borderedProminent)
            }
            .padding(Theme.Spacing.lg)
        }
        .frame(width: 420, height: model.hasDueDate ? 440 : 340)
        .background(.ultraThinMaterial)
    }
}

#Preview("Create") {
    TaskEditorView(mode: .create(defaultProject: nil))
        .environment(NotificationManager.shared)
        .modelContainer(AppModelContainer.preview)
}
