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
}

