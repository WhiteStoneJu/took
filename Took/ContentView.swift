import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TodoStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                CurrentTodoPanel(todo: store.currentTodo) {
                    if let todo = store.currentTodo {
                        store.complete(todo)
                    }
                } quickAdd: {
                    store.presentQuickAdd()
                }

                Picker("Filter", selection: $store.selectedFilter) {
                    ForEach(TodoFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                TodoListView(
                    todos: store.visibleTodos,
                    complete: store.complete,
                    delete: store.delete
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .navigationTitle("Took")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.presentQuickAdd()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.clearCompleted()
                    } label: {
                        Label("Clear Done", systemImage: "checkmark.circle.trianglebadge.exclamationmark")
                    }
                    .disabled(!store.todos.contains(where: \.isCompleted))
                }
            }
            .sheet(isPresented: $store.isQuickAddPresented) {
                QuickAddSheet(
                    draftTitle: $store.draftTitle,
                    submit: store.addDraft
                )
                .presentationDetents([.medium])
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    store.reload()
                    store.presentQuickAddIfRequested()
                    LiveActivityController.refresh()
                }
            }
        }
    }
}

private struct CurrentTodoPanel: View {
    let todo: TodoItem?
    let complete: () -> Void
    let quickAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Live Activity", systemImage: "lock.display")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: quickAdd) {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Quick Add")
            }

            if let todo {
                Text(todo.title)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .lineLimit(3)
                    .minimumScaleFactor(0.45)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: complete) {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .font(.largeTitle)
                        .foregroundStyle(.green)

                    Text("Nothing active")
                        .font(.title.bold())

                    Text("Add the next thing when it appears.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct TodoListView: View {
    let todos: [TodoItem]
    let complete: (TodoItem) -> Void
    let delete: (TodoItem) -> Void

    var body: some View {
        List {
            if todos.isEmpty {
                ContentUnavailableView(
                    "No todos here",
                    systemImage: "tray",
                    description: Text("New items land at the top.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(todos) { todo in
                    TodoRow(todo: todo) {
                        complete(todo)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            delete(todo)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

private struct TodoRow: View {
    let todo: TodoItem
    let complete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: complete) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(todo.isCompleted)
            .accessibilityLabel(todo.isCompleted ? "Completed" : "Complete")

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                Text(todo.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draftTitle: String
    @FocusState private var isFocused: Bool

    let submit: () -> Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                TextField("New todo", text: $draftTitle, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .lineLimit(1...4)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(trySubmit)

                Button(action: trySubmit) {
                    Label("Add Todo", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private func trySubmit() {
        if submit() {
            dismiss()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
