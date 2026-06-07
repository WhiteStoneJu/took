import ActivityKit
import Foundation

struct TodoActivityItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var createdAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }
}

struct TodoActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var todos: [TodoActivityItem]
        var theme: LiveActivityTheme
        var updatedAt: Date

        var primaryTodo: TodoActivityItem? {
            todos.first
        }

        init(todos: [TodoActivityItem], theme: LiveActivityTheme = .defaultValue, updatedAt: Date) {
            self.todos = todos
            self.theme = theme
            self.updatedAt = updatedAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            todos = (try? container.decode([TodoActivityItem].self, forKey: .todos)) ?? []
            theme = (try? container.decode(LiveActivityTheme.self, forKey: .theme)) ?? .defaultValue
            updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(todos, forKey: .todos)
            try container.encode(theme, forKey: .theme)
            try container.encode(updatedAt, forKey: .updatedAt)
        }

        private enum CodingKeys: String, CodingKey {
            case todos
            case theme
            case updatedAt
        }
    }

    var listName: String
}

enum TodoActivitySynchronizer {
    private static let staleInterval: TimeInterval = 60 * 60 * 8

    static func syncFromStore(includeRecentlyCompleted: Bool = false) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let activities = Activity<TodoActivityAttributes>.activities

        let activityTodos = SharedTodoStore.activityTodos(
            limit: 5,
            includeRecentlyCompleted: includeRecentlyCompleted
        )

        guard !activityTodos.isEmpty else {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        let content = ActivityContent(
            state: TodoActivityAttributes.ContentState(
                todos: activityTodos.map { todo in
                    TodoActivityItem(
                        id: todo.id,
                        title: todo.title,
                        createdAt: todo.createdAt,
                        completedAt: todo.completedAt
                    )
                },
                theme: SharedTodoStore.loadLiveActivityTheme(),
                updatedAt: Date()
            ),
            staleDate: Date().addingTimeInterval(staleInterval)
        )

        if let existingActivity = activities.first {
            await existingActivity.update(content)

            for extraActivity in activities.dropFirst() {
                await extraActivity.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        #if TOOK_APP
        do {
            _ = try Activity<TodoActivityAttributes>.request(
                attributes: TodoActivityAttributes(listName: "Took"),
                content: content,
                pushType: nil
            )
        } catch {
            // ActivityKit can reject starts when the user disables Live Activities.
        }
        #endif
    }

    static func syncAfterCompletion() async {
        await syncFromStore(includeRecentlyCompleted: true)

        do {
            try await Task.sleep(nanoseconds: 900_000_000)
        } catch {
            return
        }

        await syncFromStore(includeRecentlyCompleted: false)
    }
}
