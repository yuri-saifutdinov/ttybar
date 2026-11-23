import Foundation
import Testing
@testable import TTYBarCore

@MainActor
final class SettingsStoreTests {
    let suiteName = "ttybar-tests-\(UUID().uuidString)"
    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    @Test func firstLaunchDefaults() {
        let store = SettingsStore(defaults: defaults)
        #expect(store.filters == ["/dev/tty.*"])
        #expect(store.mutes.isEmpty)
    }

    @Test func changesPersistAcrossInstances() throws {
        let store = SettingsStore(defaults: defaults)
        try store.add("/dev/tty.usbmodem*", to: .filters)
        try store.add("/dev/tty.debug-console", to: .mutes)

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.filters == ["/dev/tty.*", "/dev/tty.usbmodem*"])
        #expect(reloaded.mutes == ["/dev/tty.debug-console"])
    }

    @Test func emptyFilterListPersists() {
        let store = SettingsStore(defaults: defaults)
        store.remove(at: 0, from: .filters)

        #expect(SettingsStore(defaults: defaults).filters.isEmpty)
    }

    @Test func addTrimsAndIgnoresDuplicates() throws {
        let store = SettingsStore(defaults: defaults)
        try store.add("  /dev/tty.*  ", to: .filters)
        #expect(store.filters == ["/dev/tty.*"])
    }

    @Test func invalidAddLeavesListUnchanged() {
        let store = SettingsStore(defaults: defaults)
        #expect(throws: PatternError.outsideDev) { try store.add("tty.*", to: .filters) }
        #expect(store.filters == ["/dev/tty.*"])
    }

    @Test func replaceEditsInPlace() throws {
        let store = SettingsStore(defaults: defaults)
        try store.add("/dev/tty.debug-console", to: .mutes)
        try store.replace(at: 0, with: "/dev/tty.debug-*", in: .mutes)
        #expect(store.mutes == ["/dev/tty.debug-*"])
    }

    @Test func invalidReplaceKeepsPreviousPattern() {
        let store = SettingsStore(defaults: defaults)
        #expect(throws: PatternError.unclosedBracket) {
            try store.replace(at: 0, with: "/dev/tty.usb[01", in: .filters)
        }
        #expect(store.filters == ["/dev/tty.*"])
        #expect(SettingsStore(defaults: defaults).filters == ["/dev/tty.*"])
    }

    @Test func replaceWithEmptyTextRemoves() throws {
        let store = SettingsStore(defaults: defaults)
        try store.replace(at: 0, with: "   ", in: .filters)
        #expect(store.filters.isEmpty)
    }

    @Test func replaceWithExistingPatternKeepsItOnce() throws {
        let store = SettingsStore(defaults: defaults)
        try store.add("/dev/tty.usb*", to: .filters)
        try store.replace(at: 1, with: "/dev/tty.*", in: .filters)
        #expect(store.filters == ["/dev/tty.*"])
    }

    @Test func outOfRangeIndicesAreIgnored() throws {
        let store = SettingsStore(defaults: defaults)
        try store.replace(at: 5, with: "/dev/x", in: .filters)
        store.remove(at: 5, from: .filters)
        #expect(store.filters == ["/dev/tty.*"])
    }

    @Test func muteExactPathEscapesAndDeduplicates() {
        let store = SettingsStore(defaults: defaults)
        store.mute(exactPath: "/dev/tty.weird[1]")
        store.mute(exactPath: "/dev/tty.weird[1]")
        #expect(store.mutes == [#"/dev/tty.weird\[1\]"#])

        let listed = DeviceFilter.apply(
            paths: ["/dev/tty.weird[1]", "/dev/tty.weird1"], filters: store.filters, mutes: store.mutes)
        #expect(listed == ["/dev/tty.weird1"])
    }
}
