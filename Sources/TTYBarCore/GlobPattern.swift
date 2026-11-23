import Darwin

/// Shell-style glob matching against full device paths.
public enum GlobPattern {
    /// Returns whether `path` matches `pattern`.
    ///
    /// Uses `fnmatch(3)` with `FNM_PATHNAME`, so `*` and `?` never match `/`.
    /// Matching is case-sensitive and a backslash makes the next character literal.
    public static func matches(_ pattern: String, path: String) -> Bool {
        fnmatch(pattern, path, FNM_PATHNAME) == 0
    }

    /// Returns a pattern that matches exactly `path` and nothing else.
    public static func escape(_ path: String) -> String {
        var escaped = ""
        for character in path {
            if metacharacters.contains(character) {
                escaped.append("\\")
            }
            escaped.append(character)
        }
        return escaped
    }

    private static let metacharacters: Set<Character> = ["\\", "*", "?", "[", "]"]
}
