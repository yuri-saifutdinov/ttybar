import Foundation

/// Decides which devices are listed and in what order.
public enum DeviceFilter {
    /// Keeps paths that match at least one filter and no mute, without duplicates,
    /// sorted ascending with embedded numbers compared by value.
    public static func apply(paths: [String], filters: [String], mutes: [String]) -> [String] {
        let kept = Set(paths.filter { path in
            filters.contains { GlobPattern.matches($0, path: path) }
                && !mutes.contains { GlobPattern.matches($0, path: path) }
        })
        return kept.sorted(by: numericAscending)
    }

    static func numericAscending(_ lhs: String, _ rhs: String) -> Bool {
        switch lhs.compare(rhs, options: [.numeric]) {
        case .orderedAscending: true
        case .orderedDescending: false
        case .orderedSame: lhs < rhs
        }
    }
}
