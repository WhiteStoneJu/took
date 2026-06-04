import ActivityKit
import Foundation

struct TodoActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var todoID: UUID
        var title: String
        var createdAt: Date
        var updatedAt: Date
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

        guard let activeTodo = SharedTodoStore.activeTodo() else {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        let content = ActivityContent(
            state: TodoActivityAttributes.ContentState(
                todoID: activeTodo.id,
                title: activeTodo.title,
                createdAt: activeTodo.createdAt,
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

