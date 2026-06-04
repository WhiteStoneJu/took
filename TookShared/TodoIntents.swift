import AppIntents
import Foundation
import WidgetKit

private enum TodoIntentSync {
    static func refreshSurfaces() async {
        await TodoActivitySynchronizer.syncFromStore()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct AddTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Todo"
    static let description = IntentDescription("Add a new todo to Took.")

    @Parameter(title: "Todo")
    var title: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title)")
    }

    init() {}

    init(title: String) {
        self.title = title
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let todo = SharedTodoStore.addTodo(title: title) else {
            return .result(dialog: "Todo was empty.")
        }

        await TodoIntentSync.refreshSurfaces()
        return .result(dialog: "Added \(todo.title).")
    }
}

struct CompleteTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Todo"
    static let description = IntentDescription("Complete a specific Took todo.")

    @Parameter(title: "Todo ID")
    var todoID: String

    init() {}

    init(todoID: String) {
        self.todoID = todoID
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let id = UUID(uuidString: todoID) else {
            return .result(dialog: "Todo was unavailable.")
        }

        _ = SharedTodoStore.completeTodo(id: id)
        await TodoIntentSync.refreshSurfaces()
        return .result(dialog: "Done.")
    }
}

struct CompleteCurrentTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Current Todo"
    static let description = IntentDescription("Complete the current Took todo.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard SharedTodoStore.completeCurrentTodo() != nil else {
            return .result(dialog: "No current todo.")
        }

        await TodoIntentSync.refreshSurfaces()
        return .result(dialog: "Done.")
    }
}

struct OpenQuickAddIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Add Todo"
    static let description = IntentDescription("Open Took directly to the todo input window.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        SharedTodoStore.requestQuickAddPresentation()
        return .result()
    }
}

#if TOOK_APP
struct TookShortcutsProvider: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTodoIntent(),
            phrases: [
                "Add a todo to \(.applicationName)",
                "Create a todo in \(.applicationName)"
            ],
            shortTitle: "Add Todo",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: OpenQuickAddIntent(),
            phrases: [
                "Quick add in \(.applicationName)",
                "Open \(.applicationName) quick add"
            ],
            shortTitle: "Quick Add",
            systemImageName: "square.and.pencil"
        )

        AppShortcut(
            intent: CompleteCurrentTodoIntent(),
            phrases: [
                "Complete current todo in \(.applicationName)",
                "Check off \(.applicationName)"
            ],
            shortTitle: "Complete Todo",
            systemImageName: "checkmark.circle"
        )
    }
}
#endif
