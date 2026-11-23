import AppKit
import TTYBarCore

/// The left-click menu: matching devices, rebuilt from `/dev` every time it opens.
@MainActor
final class DeviceMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    var onCopy: (() -> Void)?
    var onClose: (() -> Void)?

    private let store: SettingsStore
    private let scanner: any DeviceScanner

    init(store: SettingsStore, scanner: any DeviceScanner) {
        self.store = store
        self.scanner = scanner
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard !store.filters.isEmpty else {
            menu.addItem(informational("No filters — right-click to add"))
            return
        }
        let devices = DeviceFilter.apply(
            paths: scanner.devicePaths(), filters: store.filters, mutes: store.mutes)
        guard !devices.isEmpty else {
            menu.addItem(informational("No matching devices"))
            return
        }
        for path in devices {
            menu.addItem(item(path, action: #selector(copyPath(_:)), path: path, modifiers: []))
            // Shown instead of the item above while Option is held.
            let mute = item("Mute \(path)", action: #selector(mutePath(_:)), path: path, modifiers: .option)
            mute.isAlternate = true
            menu.addItem(mute)
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        onClose?()
    }

    @objc private func copyPath(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
        onCopy?()
    }

    @objc private func mutePath(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        store.mute(exactPath: path)
    }

    private func item(
        _ title: String, action: Selector, path: String, modifiers: NSEvent.ModifierFlags
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.representedObject = path
        // Alternates are paired by equal key equivalents and differing modifier masks.
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    private func informational(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
