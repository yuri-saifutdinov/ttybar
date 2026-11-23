import AppKit
import TTYBarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusController = StatusController(store: SettingsStore(), scanner: DirectoryScanner())
    }
}
