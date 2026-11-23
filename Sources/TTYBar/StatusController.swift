import AppKit
import SwiftUI
import TTYBarCore

/// Owns the status item and routes clicks: left opens the device menu,
/// right or Control-left toggles the settings popover.
@MainActor
final class StatusController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let deviceMenu: DeviceMenu
    private let popover = NSPopover()
    private var feedbackTask: Task<Void, Never>?

    init(store: SettingsStore, scanner: any DeviceScanner) {
        deviceMenu = DeviceMenu(store: store, scanner: scanner)
        super.init()

        deviceMenu.onCopy = { [weak self] in self?.showCopyFeedback() }
        deviceMenu.onClose = { [weak self] in self?.statusItem.menu = nil }

        let settings = SettingsView(
            store: store,
            onAbout: { [weak self] in self?.showAbout() },
            onQuit: { NSApp.terminate(nil) },
            onDismiss: { [weak self] in self?.popover.performClose(nil) })
        let hosting = NSHostingController(rootView: settings)
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting
        popover.behavior = .transient

        if let button = statusItem.button {
            button.image = Icons.normal
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let wantsSettings = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if wantsSettings {
            toggleSettings()
        } else {
            showDeviceMenu()
        }
    }

    private func showDeviceMenu() {
        if popover.isShown { popover.performClose(nil) }
        // Assigning the menu and clicking keeps the system's placement and button highlight.
        // `DeviceMenu.onClose` detaches it again so the next click reaches `handleClick`.
        statusItem.menu = deviceMenu.menu
        statusItem.button?.performClick(nil)
    }

    private func toggleSettings() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        // An accessory app must be active for the popover's text fields to take keyboard focus.
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func showCopyFeedback() {
        feedbackTask?.cancel()
        statusItem.button?.image = Icons.copied
        feedbackTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.statusItem.button?.image = Icons.normal
        }
    }

    private func showAbout() {
        popover.performClose(nil)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "ttybar",
            .applicationVersion: version ?? TTYBarCore.version,
            .version: "",
            .credits: NSAttributedString(string: "Copy serial device paths from the menu bar."),
        ])
    }
}
