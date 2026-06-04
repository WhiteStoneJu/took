import ActivityKit
import SwiftUI
import WidgetKit

struct TodoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodoActivityAttributes.self) { context in
            LockScreenTodoActivityView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.82))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(AppConstants.quickAddURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "checklist")
                        .font(.title2)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: CompleteTodoIntent(todoID: context.state.todoID.uuidString)) {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .tint(.green)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Link(destination: AppConstants.quickAddURL) {
                        Label("Quick Add", systemImage: "square.and.pencil")
                    }
                }
            } compactLeading: {
                Image(systemName: "checklist")
            } compactTrailing: {
                Button(intent: CompleteTodoIntent(todoID: context.state.todoID.uuidString)) {
                    Image(systemName: "checkmark")
                }
                .tint(.green)
            } minimal: {
                Image(systemName: "checkmark.circle")
            }
        }
    }
}

private struct LockScreenTodoActivityView: View {
    let state: TodoActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Took", systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))

                Spacer()

                Link(destination: AppConstants.quickAddURL) {
                    Image(systemName: "square.and.pencil")
                        .font(.headline)
                }
                .accessibilityLabel("Quick Add")
            }

            Text(state.title)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.42)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(intent: CompleteTodoIntent(todoID: state.todoID.uuidString)) {
                Label("Done", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(18)
    }
}

