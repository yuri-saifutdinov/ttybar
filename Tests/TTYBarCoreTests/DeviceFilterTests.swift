import Testing
@testable import TTYBarCore

struct DeviceFilterTests {
    let devices = [
        "/dev/tty.Bluetooth-Incoming-Port",
        "/dev/tty.debug-console",
        "/dev/tty.usbmodem11101",
        "/dev/tty.usbserial-BOBBY_0",
        "/dev/cu.usbserial-BOBBY_0",
        "/dev/null",
    ]

    @Test func unionOfFilters() {
        let result = DeviceFilter.apply(
            paths: devices, filters: ["/dev/tty.usbserial-*", "/dev/tty.usbmodem*"], mutes: [])
        #expect(result == ["/dev/tty.usbmodem11101", "/dev/tty.usbserial-BOBBY_0"])
    }

    @Test func deviceMatchingSeveralFiltersIsListedOnce() {
        let result = DeviceFilter.apply(paths: devices, filters: ["/dev/tty.*", "/dev/tty.usb*"], mutes: [])
        #expect(result.filter { $0 == "/dev/tty.usbmodem11101" }.count == 1)
    }

    @Test func duplicateInputPathsAreListedOnce() {
        let result = DeviceFilter.apply(
            paths: ["/dev/tty.a", "/dev/tty.a"], filters: ["/dev/tty.*"], mutes: [])
        #expect(result == ["/dev/tty.a"])
    }

    @Test func muteWinsOverInclude() {
        let result = DeviceFilter.apply(
            paths: devices, filters: ["/dev/tty.*"], mutes: ["/dev/tty.Bluetooth-Incoming-Port"])
        #expect(!result.contains("/dev/tty.Bluetooth-Incoming-Port"))
        #expect(result.contains("/dev/tty.debug-console"))
        #expect(result.contains("/dev/tty.usbmodem11101"))
    }

    @Test func noFiltersListsNothing() {
        #expect(DeviceFilter.apply(paths: devices, filters: [], mutes: []).isEmpty)
    }

    @Test func numericAwareOrder() {
        let result = DeviceFilter.apply(
            paths: ["/dev/tty.usbserial-10", "/dev/tty.usbserial-2", "/dev/tty.usbmodem1"],
            filters: ["/dev/tty.*"], mutes: [])
        #expect(result == ["/dev/tty.usbmodem1", "/dev/tty.usbserial-2", "/dev/tty.usbserial-10"])
    }

    @Test func orderIsDeterministicForNumericallyEqualNames() {
        let paths = ["/dev/tty.a1", "/dev/tty.a01"]
        let forward = DeviceFilter.apply(paths: paths, filters: ["/dev/tty.*"], mutes: [])
        let reversed = DeviceFilter.apply(paths: paths.reversed(), filters: ["/dev/tty.*"], mutes: [])
        #expect(forward == reversed)
    }
}
