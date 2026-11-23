import Foundation
import Testing
@testable import TTYBarCore

struct DirectoryScannerTests {
    @Test func listsTopLevelEntriesAsFullPaths() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ttybar-scan-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let nested = root.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try Data().write(to: root.appendingPathComponent("tty.usbserial-A"))
        try Data().write(to: nested.appendingPathComponent("tty.hidden"))

        let paths = DirectoryScanner(directory: root.path).devicePaths().sorted()

        #expect(paths == [root.path + "/sub", root.path + "/tty.usbserial-A"])
    }

    @Test func missingDirectoryYieldsNothing() {
        #expect(DirectoryScanner(directory: "/nonexistent-\(UUID().uuidString)").devicePaths().isEmpty)
    }

    @Test func defaultsToDev() {
        let paths = DirectoryScanner().devicePaths()
        #expect(paths.contains("/dev/null"))
        #expect(paths.allSatisfy { $0.hasPrefix("/dev/") })
    }
}
