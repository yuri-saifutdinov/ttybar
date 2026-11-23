import Foundation
import Observation

/// The two user-editable pattern lists.
public enum PatternList: String, CaseIterable, Sendable {
    case filters
    case mutes
}

/// Include filters and mute patterns, persisted in `UserDefaults`.
@MainActor
@Observable
public final class SettingsStore {
    public static let defaultFilters = ["/dev/tty.*"]
    public static let defaultMutes: [String] = []

    public private(set) var filters: [String]
    public private(set) var mutes: [String]

    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // A missing key means "never saved": use the default. A saved empty list stays empty.
        filters = defaults.stringArray(forKey: PatternList.filters.rawValue) ?? Self.defaultFilters
        mutes = defaults.stringArray(forKey: PatternList.mutes.rawValue) ?? Self.defaultMutes
    }

    public func patterns(_ list: PatternList) -> [String] {
        switch list {
        case .filters: filters
        case .mutes: mutes
        }
    }

    /// Appends a validated pattern. Adding a pattern that is already present changes nothing.
    public func add(_ raw: String, to list: PatternList) throws(PatternError) {
        let pattern = try PatternValidator.validate(raw)
        var patterns = patterns(list)
        guard !patterns.contains(pattern) else { return }
        patterns.append(pattern)
        set(patterns, for: list)
    }

    /// Replaces the pattern at `index`. Empty text removes it; invalid text changes nothing.
    public func replace(at index: Int, with raw: String, in list: PatternList) throws(PatternError) {
        var patterns = patterns(list)
        guard patterns.indices.contains(index) else { return }
        if raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            remove(at: index, from: list)
            return
        }
        let pattern = try PatternValidator.validate(raw)
        if let existing = patterns.firstIndex(of: pattern), existing != index {
            // Already present elsewhere: drop this row so the pattern stays listed once.
            patterns.remove(at: index)
        } else {
            patterns[index] = pattern
        }
        set(patterns, for: list)
    }

    public func remove(at index: Int, from list: PatternList) {
        var patterns = patterns(list)
        guard patterns.indices.contains(index) else { return }
        patterns.remove(at: index)
        set(patterns, for: list)
    }

    /// Adds a mute pattern that matches exactly `path`.
    public func mute(exactPath path: String) {
        try? add(GlobPattern.escape(path), to: .mutes)
    }

    private func set(_ patterns: [String], for list: PatternList) {
        switch list {
        case .filters: filters = patterns
        case .mutes: mutes = patterns
        }
        defaults.set(patterns, forKey: list.rawValue)
    }
}
