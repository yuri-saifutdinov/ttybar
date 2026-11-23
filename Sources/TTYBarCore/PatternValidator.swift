import Foundation

/// Why a pattern was rejected.
public enum PatternError: Error, Equatable, Sendable {
    case empty
    case outsideDev
    case unclosedBracket
    case trailingBackslash

    /// Short human-readable reason shown next to the offending pattern.
    public var reason: String {
        switch self {
        case .empty: "Pattern is empty"
        case .outsideDev: "Must start with /dev/"
        case .unclosedBracket: "Unclosed [ in pattern"
        case .trailingBackslash: "Ends with a lone backslash"
        }
    }
}

/// Checks user-entered patterns before they are stored.
public enum PatternValidator {
    public static let requiredPrefix = "/dev/"

    /// Returns the trimmed pattern if it is valid.
    public static func validate(_ raw: String) throws(PatternError) -> String {
        let pattern = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pattern.isEmpty else { throw .empty }
        guard pattern.hasPrefix(requiredPrefix) else { throw .outsideDev }
        try checkSyntax(Array(pattern))
        return pattern
    }

    private static func checkSyntax(_ chars: [Character]) throws(PatternError) {
        var index = 0
        while index < chars.count {
            switch chars[index] {
            case "\\":
                guard index + 1 < chars.count else { throw .trailingBackslash }
                index += 2
            case "[":
                index = try indexAfterBracketSet(chars, openingAt: index)
            default:
                index += 1
            }
        }
    }

    /// Returns the index just past the `]` that closes the set opened at `start`.
    private static func indexAfterBracketSet(
        _ chars: [Character], openingAt start: Int
    ) throws(PatternError) -> Int {
        var index = start + 1
        if index < chars.count, chars[index] == "!" { index += 1 }
        // A `]` right after `[` or `[!` is a literal member of the set.
        if index < chars.count, chars[index] == "]" { index += 1 }
        while index < chars.count {
            switch chars[index] {
            case "]":
                return index + 1
            case "\\":
                index += 2
            default:
                index += 1
            }
        }
        throw .unclosedBracket
    }
}
