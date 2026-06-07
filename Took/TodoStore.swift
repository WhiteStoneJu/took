import Combine
import Foundation
import SwiftUI

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var todos: [TodoItem] = []
    @Published private(set) var completingTodoIDs: Set<UUID> = []
    @Published var liveActivityTheme: LiveActivityTheme = .defaultValue
    @Published var draftTitle = ""
    @Published var isQuickAddPresented = false
    @Published var selectedFilter: TodoFilter = .open
    @Published var selectedDate = Date()

    var currentTodo: TodoItem? {
        openTodos(on: Date()).first ?? todos.first { !$0.isCompleted }
    }

    var visibleTodos: [TodoItem] {
        switch selectedFilter {
        case .open:
            todos.filter { !$0.isCompleted }
        case .done:
            todos.filter(\.isCompleted)
        }
    }

    var todayTodos: [TodoItem] {
        todos(on: Date())
    }

    var availableDates: [Date] {
        let calendar = Calendar.current
        let days = Set(todos.flatMap { todo in
            var dates = [calendar.startOfDay(for: todo.createdAt)]
            if let completedAt = todo.completedAt {
                dates.append(calendar.startOfDay(for: completedAt))
            }
            return dates
        })
        return days.sorted(by: >)
    }

    init() {
        reload()
    }

    func reload() {
        todos = SharedTodoStore.loadTodos()
        liveActivityTheme = SharedTodoStore.loadLiveActivityTheme()
    }

    func todos(on date: Date) -> [TodoItem] {
        let calendar = Calendar.current
        return todos.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }

    func openTodos(on date: Date) -> [TodoItem] {
        todos(on: date).filter { !$0.isCompleted || completingTodoIDs.contains($0.id) }
    }

    func completedTodos(on date: Date) -> [TodoItem] {
        todos.filter { todo in
            guard let completedAt = todo.completedAt, !completingTodoIDs.contains(todo.id) else {
                return false
            }

            return Calendar.current.isDate(completedAt, inSameDayAs: date)
        }
    }

    func isCompleting(_ todo: TodoItem) -> Bool {
        completingTodoIDs.contains(todo.id)
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
        guard !completingTodoIDs.contains(todo.id) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            completingTodoIDs.insert(todo.id)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            Task { @MainActor in
                self?.finishCompletion(for: todo)
            }
        }
    }

    private func finishCompletion(for todo: TodoItem) {
        _ = SharedTodoStore.completeTodo(id: todo.id)
        completingTodoIDs.remove(todo.id)
        reload()
        LiveActivityController.refreshAfterCompletion()
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

    func updateLiveActivityTheme(_ theme: LiveActivityTheme) {
        liveActivityTheme = theme
        SharedTodoStore.saveLiveActivityTheme(theme)
        LiveActivityController.refresh()
    }

    func updateLiveActivityTransparency(_ isTransparent: Bool) {
        var theme = liveActivityTheme
        theme.isTransparent = isTransparent
        updateLiveActivityTheme(theme)
    }

    func updateLiveActivityTextColor(_ textColor: LiveActivityTextColor) {
        var theme = liveActivityTheme
        theme.textColor = textColor
        updateLiveActivityTheme(theme)
    }
}
