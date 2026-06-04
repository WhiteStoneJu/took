import SwiftUI

@main
struct TookApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onOpenURL { url in
                    store.handle(url: url)
                }
                .task {
                    store.presentQuickAddIfRequested()
                    await LiveActivityController.refreshNow()
                }
        }
    }
}
