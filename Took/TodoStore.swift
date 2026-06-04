import Combine
import Foundation

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var todos: [TodoItem] = []
    @Published var draftTitle = ""
    @Published var isQuickAddPresented = false
    @Published var selectedFilter: TodoFilter = .open

    var currentTodo: TodoItem? {
        todos.first { !$0.isCompleted }
    }

    var visibleTodos: [TodoItem] {
        switch selectedFilter {
        case .open:
            todos.filter { !$0.isCompleted }
        case .done:
            todos.filter(\.isCompleted)
        }
    }

    init() {
        reload()
    }

    func reload() {
        todos = SharedTodoStore.loadTodos()
    }

    func presentQuickAdd(prefill: String? = nil) {
        if let prefill {
            draftTitle = prefill
        }
        isQuickAddPresented = true
    }

    func presentQuickAddIfRequested() {
        if SharedTodoStore.consumeQuickAddPresentationRequest() {
            presentQuickAdd()
        }
    }

    func handle(url: URL) {
        guard url.scheme == "took" else {
            return
        }

        if url.host == "quick-add" || url.host == "add" {
            presentQuickAdd()
        }
    }

    @discardableResult
    func addDraft() -> Bool {
        add(title: draftTitle)
    }

    @discardableResult
    func add(title: String) -> Bool {
        guard SharedTodoStore.addTodo(title: title) != nil else {
            return false
        }

        draftTitle = ""
        reload()
        LiveActivityController.refresh()
        return true
    }

    func complete(_ todo: TodoItem) {
        _ = SharedTodoStore.completeTodo(id: todo.id)
        reload()
        LiveActivityController.refresh()
    }

    func delete(_ todo: TodoItem) {
        SharedTodoStore.deleteTodo(id: todo.id)
        reload()
        LiveActivityController.refresh()
    }

    func clearCompleted() {
        SharedTodoStore.clearCompleted()
        reload()
        LiveActivityController.refresh()
    }
}
