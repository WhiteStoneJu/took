import ActivityKit
import Foundation

struct TodoActivityItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var createdAt: Date
}

struct TodoActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var todos: [TodoActivityItem]
        var updatedAt: Date

        var primaryTodo: TodoActivityItem? {
            todos.first
        }
    }

    var listName: String
}

enum TodoActivitySynchronizer {
    private static let staleInterval: TimeInterval = 60 * 60 * 8

    static func syncFromStore() async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let activities = Activity<TodoActivityAttributes>.activities

        let openTodos = SharedTodoStore.openTodos(limit: 5)

        guard !openTodos.isEmpty else {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        let content = ActivityContent(
            state: TodoActivityAttributes.ContentState(
                todos: openTodos.map { todo in
                    TodoActivityItem(
                        id: todo.id,
                        title: todo.title,
                        createdAt: todo.createdAt
                    )
                },
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
}
