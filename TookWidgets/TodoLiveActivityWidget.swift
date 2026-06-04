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
                    Text("\(context.state.todos.count)")
                        .font(.title2.weight(.bold))
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.primaryTodo?.title ?? "Took")
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if let todo = context.state.primaryTodo {
                        Button(intent: CompleteTodoIntent(todo: TodoEntity(activityItem: todo))) {
                            Image(systemName: "circle")
                        }
                        .tint(.white)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Link(destination: AppConstants.quickAddURL) {
                        Label("Quick Add", systemImage: "square.and.pencil")
                    }
                }
            } compactLeading: {
                Text("\(context.state.todos.count)")
                    .font(.caption.weight(.bold))
            } compactTrailing: {
                if let todo = context.state.primaryTodo {
                    Button(intent: CompleteTodoIntent(todo: TodoEntity(activityItem: todo))) {
                        Image(systemName: "circle")
                    }
                    .tint(.white)
                }
            } minimal: {
                Text("\(context.state.todos.count)")
                    .font(.caption2.weight(.bold))
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

            VStack(alignment: .leading, spacing: 10) {
                ForEach(state.todos) { todo in
                    HStack(spacing: 12) {
                        Button(intent: CompleteTodoIntent(todo: TodoEntity(activityItem: todo))) {
                            Image(systemName: "circle")
                                .font(.title2.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .tint(.white)
                        .accessibilityLabel("Complete \(todo.title)")

                        Text(todo.title)
                            .font(.system(size: state.todos.count == 1 ? 34 : 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(state.todos.count == 1 ? 3 : 1)
                            .minimumScaleFactor(0.55)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(18)
    }
}
