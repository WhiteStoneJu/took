import Foundation

enum TodoFilter: String, CaseIterable, Identifiable {
    case open = "Open"
    case done = "Done"

    var id: String {
        rawValue
    }
}

extension TodoItem {
    var statusLabel: String {
        isCompleted ? "Done" : "Open"
    }
}

