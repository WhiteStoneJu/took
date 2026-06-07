import SwiftUI
import WidgetKit

struct TodoWidgetEntry: TimelineEntry {
    let date: Date
    let todo: TodoItem?
}

struct TodoTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoWidgetEntry {
        TodoWidgetEntry(date: Date(), todo: TodoItem(title: "Write down the next thing"))
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoWidgetEntry) -> Void) {
        completion(TodoWidgetEntry(date: Date(), todo: SharedTodoStore.activeTodo()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoWidgetEntry>) -> Void) {
        let entry = TodoWidgetEntry(date: Date(), todo: SharedTodoStore.activeTodo())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15))))
    }
}

struct TodoWidget: Widget {
    private let kind = "TookCurrentTodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoTimelineProvider()) { entry in
            TodoWidgetView(entry: entry)
        }
        .configurationDisplayName("Current Todo")
        .description("Show the current Took todo.")
        .supportedFamilies([.accessoryRectangular, .systemSmall, .systemMedium])
    }
}

private struct TodoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodoWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                accessoryView
            default:
                systemView
            }
        }
        .widgetCompatibleBackground(Color(.systemBackground))
        .widgetURL(AppConstants.quickAddURL)
    }

    private var accessoryView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Took")
                .font(.caption2.weight(.semibold))
            Text(entry.todo?.title ?? "Nothing active")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    private var systemView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Took", systemImage: "checklist")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(entry.todo?.title ?? "Nothing active")
                .font(.title3.weight(.bold))
                .lineLimit(4)
                .minimumScaleFactor(0.6)

            Spacer()

            Text("Tap to add")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

private extension View {
    @ViewBuilder
    func widgetCompatibleBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                color
            }
        } else {
            self.background(color)
        }
    }
}
