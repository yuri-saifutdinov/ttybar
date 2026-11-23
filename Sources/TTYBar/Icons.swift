import AppKit

/// Menu bar images. Placeholder SF Symbols until a designed icon exists.
@MainActor
enum Icons {
    static let normal = templateSymbol("cable.connector", description: "ttybar")
    static let copied = templateSymbol("checkmark", description: "Copied")

    private static func templateSymbol(_ name: String, description: String) -> NSImage {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: description) ?? NSImage()
        image.isTemplate = true
        return image
    }
}
