import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Matches LSUIElement in Info.plist, so `swift run` without a bundle behaves the same.
app.setActivationPolicy(.accessory)
app.run()
