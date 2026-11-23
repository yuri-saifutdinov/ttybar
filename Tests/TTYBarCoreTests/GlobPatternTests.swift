import Testing
@testable import TTYBarCore

struct GlobPatternTests {
    @Test func starMatchesWithinOneComponent() {
        #expect(GlobPattern.matches("/dev/tty.*", path: "/dev/tty.usbserial-BOBBY_0"))
        #expect(!GlobPattern.matches("/dev/tty.*", path: "/dev/cu.usbserial-BOBBY_0"))
    }

    @Test func starDoesNotCrossSlash() {
        #expect(!GlobPattern.matches("/dev/*", path: "/dev/fd/0"))
        #expect(GlobPattern.matches("/dev/*", path: "/dev/fd"))
    }

    @Test func questionMarkMatchesOneCharacter() {
        #expect(GlobPattern.matches("/dev/tty.usbserial-BOBBY_?", path: "/dev/tty.usbserial-BOBBY_3"))
        #expect(!GlobPattern.matches("/dev/tty.usbserial-BOBBY_?", path: "/dev/tty.usbserial-BOBBY_10"))
        #expect(!GlobPattern.matches("/dev?fd", path: "/dev/fd"))
    }

    @Test func characterSet() {
        let pattern = "/dev/tty.usbserial-BOBBY_[02]"
        #expect(GlobPattern.matches(pattern, path: "/dev/tty.usbserial-BOBBY_0"))
        #expect(GlobPattern.matches(pattern, path: "/dev/tty.usbserial-BOBBY_2"))
        #expect(!GlobPattern.matches(pattern, path: "/dev/tty.usbserial-BOBBY_1"))
    }

    @Test func characterRangeAndNegation() {
        #expect(GlobPattern.matches("/dev/tty.usbserial-BOBBY_[0-2]", path: "/dev/tty.usbserial-BOBBY_1"))
        #expect(!GlobPattern.matches("/dev/tty.usbserial-BOBBY_[!0-2]", path: "/dev/tty.usbserial-BOBBY_1"))
        #expect(GlobPattern.matches("/dev/tty.usbserial-BOBBY_[!0-2]", path: "/dev/tty.usbserial-BOBBY_3"))
    }

    @Test func caseSensitive() {
        #expect(!GlobPattern.matches("/dev/tty.USB*", path: "/dev/tty.usbmodem11101"))
    }

    @Test func escapedMetacharacter() {
        #expect(GlobPattern.matches(#"/dev/tty.weird\[1\]"#, path: "/dev/tty.weird[1]"))
        #expect(!GlobPattern.matches(#"/dev/tty.weird\[1\]"#, path: "/dev/tty.weird1"))
    }

    @Test(arguments: [
        "/dev/tty.weird[1]",
        "/dev/tty.star*name",
        "/dev/tty.what?",
        #"/dev/tty.back\slash"#,
        "/dev/tty.usbserial-PUMP",
    ])
    func escapedPathMatchesOnlyItself(path: String) {
        let pattern = GlobPattern.escape(path)
        #expect(GlobPattern.matches(pattern, path: path))
        #expect((try? PatternValidator.validate(pattern)) == pattern)
    }

    @Test func escapeProducesExpectedPattern() {
        #expect(GlobPattern.escape("/dev/tty.weird[1]") == #"/dev/tty.weird\[1\]"#)
        #expect(!GlobPattern.matches(GlobPattern.escape("/dev/tty.weird[1]"), path: "/dev/tty.weird1"))
        #expect(!GlobPattern.matches(GlobPattern.escape("/dev/tty.star*"), path: "/dev/tty.starfish"))
    }
}
