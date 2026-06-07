import Foundation
import WidgetKit

@MainActor
enum LiveActivityController {
    static func refresh() {
        Task {
            await refreshNow()
        }
    }

    static func refreshNow() async {
        await TodoActivitySynchronizer.syncFromStore()
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func refreshAfterCompletion() {
        Task {
            await TodoActivitySynchronizer.syncAfterCompletion()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
