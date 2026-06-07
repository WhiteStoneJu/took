import ActivityKit
import SwiftUI
import WidgetKit

struct TodoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodoActivityAttributes.self) { context in
            LockScreenTodoActivityView(state: context.state)
                .activityBackgroundTint(context.state.theme.activityBackgroundTint)
                .activitySystemActionForegroundColor(context.state.theme.widgetTextColor)
                .widgetURL(AppConstants.quickAddURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.state.todos.filter { !$0.isCompleted }.count)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(context.state.theme.widgetTextColor)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.primaryTodo?.title ?? "Took")
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(context.state.theme.widgetTextColor)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if let todo = context.state.primaryTodo {
                        TodoActivityCircle(todo: todo, theme: context.state.theme)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(context.state.todos.prefix(3))) { todo in
                            TodoActivityRow(todo: todo, theme: context.state.theme, isCompact: true)
                        }

                        Link(destination: AppConstants.quickAddURL) {
                            Label("Quick Add", systemImage: "square.and.pencil")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(context.state.theme.widgetTextColor.opacity(0.82))
                    }
                }
            } compactLeading: {
                Text("\(context.state.todos.filter { !$0.isCompleted }.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(context.state.theme.widgetTextColor)
            } compactTrailing: {
                if let todo = context.state.primaryTodo {
                    TodoActivityCircle(todo: todo, theme: context.state.theme)
                }
            } minimal: {
                Text("\(context.state.todos.filter { !$0.isCompleted }.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(context.state.theme.widgetTextColor)
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
                    .foregroundStyle(state.theme.widgetTextColor.opacity(0.72))

                Spacer()

                Link(destination: AppConstants.quickAddURL) {
                    Image(systemName: "square.and.pencil")
                        .font(.headline)
                }
                .foregroundStyle(state.theme.widgetTextColor)
                .accessibilityLabel("Quick Add")
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(state.todos) { todo in
                    TodoActivityRow(
                        todo: todo,
                        theme: state.theme,
                        isCompact: state.todos.count > 1
                    )
                }
            }
        }
        .padding(18)
    }
}

private struct TodoActivityRow: View {
    let todo: TodoActivityItem
    let theme: LiveActivityTheme
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 12) {
            TodoActivityCircle(todo: todo, theme: theme)

            Text(todo.title)
                .font(.system(size: isCompact ? 21 : 34, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.widgetTextColor.opacity(todo.isCompleted ? 0.55 : 1))
                .strikethrough(todo.isCompleted, color: theme.widgetTextColor.opacity(0.72))
                .lineLimit(isCompact ? 1 : 3)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(todo.isCompleted ? 0.58 : 1)
    }
}

private struct TodoActivityCircle: View {
    let todo: TodoActivityItem
    let theme: LiveActivityTheme

    var body: some View {
        Group {
            if todo.isCompleted {
                Image(systemName: "checkmark.circle.fill")
            } else {
                if #available(iOSApplicationExtension 17.0, *) {
                    Button(intent: CompleteTodoIntent(todo: TodoEntity(activityItem: todo))) {
                        Image(systemName: "circle")
                    }
                    .buttonStyle(.plain)
                } else {
                    Link(destination: AppConstants.quickAddURL) {
                        Image(systemName: "circle")
                    }
                }
            }
        }
        .font(.title2.weight(.semibold))
        .foregroundStyle(todo.isCompleted ? .green : theme.widgetTextColor)
        .tint(todo.isCompleted ? .green : theme.widgetTextColor)
        .accessibilityLabel(todo.isCompleted ? "Completed \(todo.title)" : "Complete \(todo.title)")
    }
}

private extension LiveActivityTheme {
    var widgetTextColor: Color {
        switch textColor {
        case .white:
            .white
        case .black:
            .black
        case .mint:
            .mint
        case .yellow:
            .yellow
        case .blue:
            .blue
        }
    }

    var activityBackgroundTint: Color {
        isTransparent ? .clear : .black.opacity(0.82)
    }
}
