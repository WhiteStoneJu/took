import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TodoStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checklist")
                }

            DatesView()
                .tabItem {
                    Label("Dates", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .sheet(isPresented: $store.isQuickAddPresented) {
            QuickAddSheet(
                draftTitle: $store.draftTitle,
                submit: store.addDraft
            )
            .presentationDetents([.medium])
        }
        .onOpenURL { url in
            store.handle(url: url)
        }
        .task {
            store.presentQuickAddIfRequested()
            await LiveActivityController.refreshNow()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                store.reload()
                store.presentQuickAddIfRequested()
                LiveActivityController.refresh()
            }
        }
    }
}

private struct TodayView: View {
    @EnvironmentObject private var store: TodoStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    CurrentTodoPanel(todo: store.currentTodo) {
                        if let todo = store.currentTodo {
                            store.complete(todo)
                        }
                    } quickAdd: {
                        store.presentQuickAdd()
                    } isCompleting: {
                        store.currentTodo.map(store.isCompleting) ?? false
                    }

                    TodoSection(
                        title: "Remaining Today",
                        todos: store.openTodos(on: Date()),
                        emptyTitle: "No remaining todos",
                        emptySystemImage: "sun.max",
                        complete: store.complete,
                        delete: store.delete,
                        isCompleting: store.isCompleting
                    )

                    TodoSection(
                        title: "Done Today",
                        todos: store.completedTodos(on: Date()),
                        emptyTitle: "Nothing done yet",
                        emptySystemImage: "checkmark.seal",
                        complete: store.complete,
                        delete: store.delete,
                        isCompleting: store.isCompleting
                    )
                }
                .padding(20)
            }
            .navigationTitle("Took")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.presentQuickAdd()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
    }
}

private struct DatesView: View {
    @EnvironmentObject private var store: TodoStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DatePicker("Date", selection: $store.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 4)

                    if !store.availableDates.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.availableDates, id: \.self) { date in
                                    Button {
                                        store.selectedDate = date
                                    } label: {
                                        Text(date, format: .dateTime.month(.abbreviated).day())
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(Calendar.current.isDate(date, inSameDayAs: store.selectedDate) ? .blue : .secondary)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }

                    TodoSection(
                        title: "Remaining",
                        todos: store.openTodos(on: store.selectedDate),
                        emptyTitle: "No remaining todos",
                        emptySystemImage: "tray",
                        complete: store.complete,
                        delete: store.delete,
                        isCompleting: store.isCompleting
                    )

                    TodoSection(
                        title: "Done",
                        todos: store.completedTodos(on: store.selectedDate),
                        emptyTitle: "Nothing completed",
                        emptySystemImage: "checkmark.circle",
                        complete: store.complete,
                        delete: store.delete,
                        isCompleting: store.isCompleting
                    )
                }
                .padding(20)
            }
            .navigationTitle("Dates")
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var store: TodoStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Lock Screen Live Activity") {
                    Toggle(
                        "Transparent background",
                        isOn: Binding(
                            get: { store.liveActivityTheme.isTransparent },
                            set: { store.updateLiveActivityTransparency($0) }
                        )
                    )

                    Picker(
                        "Text color",
                        selection: Binding(
                            get: { store.liveActivityTheme.textColor },
                            set: { store.updateLiveActivityTextColor($0) }
                        )
                    ) {
                        ForEach(LiveActivityTextColor.allCases) { color in
                            Text(color.displayName).tag(color)
                        }
                    }
                }

                Section("Preview") {
                    LiveActivityThemePreview(theme: store.liveActivityTheme)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct LiveActivityThemePreview: View {
    let theme: LiveActivityTheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Buy coffee")
                    .font(.headline.weight(.bold))
                Text(theme.isTransparent ? "Transparent" : "Dark background")
                    .font(.caption)
                    .opacity(0.75)
            }

            Spacer()
        }
        .foregroundStyle(theme.previewTextColor)
        .padding(16)
        .background(theme.previewBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CurrentTodoPanel: View {
    let todo: TodoItem?
    let complete: () -> Void
    let quickAdd: () -> Void
    let isCompleting: () -> Bool

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
                HStack(alignment: .top, spacing: 12) {
                    Button(action: complete) {
                        Image(systemName: "circle")
                            .font(.title.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Complete")

                    Text(todo.title)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .strikethrough(isCompleting(), color: .secondary)
                        .foregroundStyle(isCompleting() ? .secondary : .primary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.45)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(isCompleting() ? 0.4 : 1)
                }
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

private struct TodoSection: View {
    let title: String
    let todos: [TodoItem]
    let emptyTitle: String
    let emptySystemImage: String
    let complete: (TodoItem) -> Void
    let delete: (TodoItem) -> Void
    let isCompleting: (TodoItem) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            if todos.isEmpty {
                EmptyStateView(title: emptyTitle, systemImage: emptySystemImage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(todos) { todo in
                        TodoRow(
                            todo: todo,
                            isCompleting: isCompleting(todo),
                            complete: {
                                complete(todo)
                            }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(todo)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if todo.id != todos.last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(18)
    }
}

private struct TodoRow: View {
    let todo: TodoItem
    let isCompleting: Bool
    let complete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: complete) {
                Image(systemName: todo.isCompleted || isCompleting ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted || isCompleting ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(todo.isCompleted || isCompleting)
            .accessibilityLabel(todo.isCompleted || isCompleting ? "Completed" : "Complete")

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(todo.isCompleted || isCompleting, color: .secondary)
                    .foregroundStyle(todo.isCompleted || isCompleting ? .secondary : .primary)

                Text(todo.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .opacity(isCompleting ? 0.35 : 1)
        .offset(x: isCompleting ? 18 : 0)
        .animation(.easeInOut(duration: 0.35), value: isCompleting)
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

private extension LiveActivityTheme {
    var previewTextColor: Color {
        switch textColor {
        case .white:
            .white
        case .black:
            .black
        case .mint:
            .mint
        case .yellow:
            .yellow
        case .blue:
            .blue
        }
    }

    var previewBackground: Color {
        isTransparent ? .clear : .black.opacity(0.82)
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
