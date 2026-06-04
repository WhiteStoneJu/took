import Foundation

enum AppConstants {
    static let appGroupID = "group.com.example.took"
    static let quickAddURL = URL(string: "took://quick-add")!
}

struct TodoItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var createdAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

enum SharedTodoStore {
    static let storeDidChangeNotification = Notification.Name("SharedTodoStoreDidChangeNotification")

    private static let todosKey = "todos.v1"
    private static let quickAddRequestKey = "quickAddRequest.v1"
    private static let versionKey = "todos.version.v1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func loadTodos() -> [TodoItem] {
        guard
            let data = defaults.data(forKey: todosKey),
            let todos = try? decoder.decode([TodoItem].self, from: data)
        else {
            return []
        }

        return todos
    }

    static func activeTodo() -> TodoItem? {
        loadTodos().first { !$0.isCompleted }
    }

    static func openTodos(limit: Int = 5) -> [TodoItem] {
        Array(loadTodos().filter { !$0.isCompleted }.prefix(limit))
    }

    @discardableResult
    static func addTodo(title: String) -> TodoItem? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return nil
        }

        let todo = TodoItem(title: trimmedTitle)
        var todos = loadTodos()
        todos.insert(todo, at: 0)
        saveTodos(todos)
        return todo
    }

    @discardableResult
    static func completeTodo(id: UUID) -> TodoItem? {
        var todos = loadTodos()
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        if todos[index].completedAt == nil {
            todos[index].completedAt = Date()
        }
        let completed = todos[index]
        saveTodos(todos)
        return completed
    }

    @discardableResult
    static func completeCurrentTodo() -> TodoItem? {
        guard let todo = activeTodo() else {
            return nil
        }

        return completeTodo(id: todo.id)
    }

    static func deleteTodo(id: UUID) {
        let todos = loadTodos().filter { $0.id != id }
        saveTodos(todos)
    }

    static func clearCompleted() {
        let todos = loadTodos().filter { !$0.isCompleted }
        saveTodos(todos)
    }

    static func requestQuickAddPresentation() {
        defaults.set(Date().timeIntervalSince1970, forKey: quickAddRequestKey)
        defaults.synchronize()
    }

    static func consumeQuickAddPresentationRequest() -> Bool {
        guard defaults.object(forKey: quickAddRequestKey) != nil else {
            return false
        }

        defaults.removeObject(forKey: quickAddRequestKey)
        defaults.synchronize()
        return true
    }

    private static func saveTodos(_ todos: [TodoItem]) {
        guard let data = try? encoder.encode(todos) else {
            return
        }

        defaults.set(data, forKey: todosKey)
        defaults.set(Date().timeIntervalSince1970, forKey: versionKey)
        defaults.synchronize()
        NotificationCenter.default.post(name: storeDidChangeNotification, object: nil)
    }
}
