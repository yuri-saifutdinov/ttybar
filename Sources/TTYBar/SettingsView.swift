import SwiftUI
import TTYBarCore

/// Content of the right-click popover: editable filter and mute lists, About, Quit.
struct SettingsView: View {
    let store: SettingsStore
    let onAbout: () -> Void
    let onQuit: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PatternSection(
                title: "Filters", list: .filters, store: store,
                placeholder: "Add filter, e.g. /dev/tty.usb*", onDismiss: onDismiss)
            PatternSection(
                title: "Muted", list: .mutes, store: store,
                placeholder: "Add mute, e.g. /dev/tty.Bluetooth*", onDismiss: onDismiss)
            Divider()
            HStack {
                Button("About ttybar", action: onAbout)
                Spacer()
                Button("Quit", action: onQuit)
            }
        }
        .padding(14)
        .frame(width: 360)
    }
}

private struct PatternSection: View {
    let title: String
    let list: PatternList
    let store: SettingsStore
    let placeholder: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            // Patterns are unique within a list, so they double as row identity.
            ForEach(Array(store.patterns(list).enumerated()), id: \.element) { index, pattern in
                PatternRow(
                    committed: pattern,
                    placeholder: "",
                    isAddRow: false,
                    onCommit: { text throws(PatternError) in
                        try store.replace(at: index, with: text, in: list)
                    },
                    onRemove: { store.remove(at: index, from: list) },
                    onDismiss: onDismiss)
            }
            PatternRow(
                committed: "",
                placeholder: placeholder,
                isAddRow: true,
                onCommit: { text throws(PatternError) in try store.add(text, to: list) },
                onRemove: nil,
                onDismiss: onDismiss)
        }
    }
}

/// One editable pattern. Return commits, Escape reverts uncommitted text
/// (or closes the popover when there is nothing to revert).
private struct PatternRow: View {
    let committed: String
    let placeholder: String
    let isAddRow: Bool
    let onCommit: (String) throws(PatternError) -> Void
    let onRemove: (() -> Void)?
    let onDismiss: () -> Void

    @State private var draft: String
    @State private var error: PatternError?

    init(
        committed: String,
        placeholder: String,
        isAddRow: Bool,
        onCommit: @escaping (String) throws(PatternError) -> Void,
        onRemove: (() -> Void)?,
        onDismiss: @escaping () -> Void
    ) {
        self.committed = committed
        self.placeholder = placeholder
        self.isAddRow = isAddRow
        self.onCommit = onCommit
        self.onRemove = onRemove
        self.onDismiss = onDismiss
        _draft = State(initialValue: committed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                TextField(placeholder, text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.red, lineWidth: error == nil ? 0 : 1.5)
                    }
                    .onSubmit(commit)
                    .onExitCommand(perform: cancel)
                    .onChange(of: draft) { error = nil }
                if let onRemove {
                    Button(action: onRemove) { Image(systemName: "minus.circle") }
                        .buttonStyle(.borderless)
                        .help("Remove")
                } else {
                    Button(action: commit) { Image(systemName: "plus.circle") }
                        .buttonStyle(.borderless)
                        .help("Add")
                }
            }
            if let error {
                Text(error.reason)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func commit() {
        if isAddRow, draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
        do {
            try onCommit(draft)
            draft = isAddRow ? "" : draft.trimmingCharacters(in: .whitespacesAndNewlines)
            error = nil
        } catch {
            self.error = error
        }
    }

    private func cancel() {
        if draft != committed || error != nil {
            draft = committed
            error = nil
        } else {
            onDismiss()
        }
    }
}
