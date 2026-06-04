import WidgetKit
import SwiftUI

@main
struct TookWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodoLiveActivityWidget()
        TodoWidget()
    }
}

