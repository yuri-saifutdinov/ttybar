import Testing
@testable import TTYBarCore

struct PatternValidatorTests {
    @Test func acceptsTypicalPatterns() throws {
        #expect(try PatternValidator.validate("/dev/tty.*") == "/dev/tty.*")
        #expect(try PatternValidator.validate("/dev/tty.usbserial-BOBBY_[0-3]") == "/dev/tty.usbserial-BOBBY_[0-3]")
        #expect(try PatternValidator.validate("/dev/tty.[!B]*") == "/dev/tty.[!B]*")
        #expect(try PatternValidator.validate("/dev/tty.[]x]") == "/dev/tty.[]x]")
        #expect(try PatternValidator.validate(#"/dev/tty.a\[b"#) == #"/dev/tty.a\[b"#)
        #expect(try PatternValidator.validate(#"/dev/tty.[\]]"#) == #"/dev/tty.[\]]"#)
    }

    @Test func trimsSurroundingWhitespace() throws {
        #expect(try PatternValidator.validate("  /dev/tty.*  ") == "/dev/tty.*")
        #expect(try PatternValidator.validate("\t/dev/tty.*\n") == "/dev/tty.*")
    }

    @Test func rejectsEmpty() {
        #expect(throws: PatternError.empty) { try PatternValidator.validate("") }
        #expect(throws: PatternError.empty) { try PatternValidator.validate("   ") }
    }

    @Test func rejectsPatternsOutsideDev() {
        #expect(throws: PatternError.outsideDev) { try PatternValidator.validate("tty.*") }
        #expect(throws: PatternError.outsideDev) { try PatternValidator.validate("/dev") }
        #expect(throws: PatternError.outsideDev) { try PatternValidator.validate("/devices/*") }
        #expect(PatternError.outsideDev.reason.contains("/dev/"))
    }

    @Test func rejectsUnclosedBracket() {
        #expect(throws: PatternError.unclosedBracket) { try PatternValidator.validate("/dev/tty.usb[01") }
        #expect(throws: PatternError.unclosedBracket) { try PatternValidator.validate("/dev/tty.[]") }
        #expect(throws: PatternError.unclosedBracket) { try PatternValidator.validate(#"/dev/tty.[a\]"#) }
    }

    @Test func rejectsTrailingBackslash() throws {
        #expect(throws: PatternError.trailingBackslash) { try PatternValidator.validate(#"/dev/tty\"#) }
        #expect(try PatternValidator.validate(#"/dev/tty\\"#) == #"/dev/tty\\"#)
    }

    @Test func everyErrorHasAReason() {
        for error in [PatternError.empty, .outsideDev, .unclosedBracket, .trailingBackslash] {
            #expect(!error.reason.isEmpty)
        }
    }
}
