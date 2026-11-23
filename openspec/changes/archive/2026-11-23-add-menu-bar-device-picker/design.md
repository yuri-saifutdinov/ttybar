# Design

## Context

Greenfield repository: only OpenSpec scaffolding exists. The target machine runs macOS 26 with
Swift 6.2 from the Command Line Tools; Xcode is not installed. Two consequences were verified
on this machine:

- `swift build` works, but there is no `xcodebuild`, so the `.app` bundle must be assembled by
  a script.
- `XCTest` is not available. Swift Testing (`import Testing`) ships with the Command Line Tools
  but is not on the default search path; `swift test` succeeds when given
  `-F <CLT>/Library/Developer/Frameworks` plus matching linker `-F` and `-rpath` flags. The
  Command Line Tools also ship the `_Testing_Foundation` cross-import overlay without its
  module, so test files that import both `Testing` and `Foundation` fail unless cross-import
  overlays are disabled (`-Xfrontend -disable-cross-import-overlays`).

Requirements are in `specs/device-menu`, `specs/filter-settings`, and `specs/menu-bar-app`;
motivation is in proposal.md.

## Goals / Non-Goals

**Goals:**
- Zero third-party dependencies; only AppKit, SwiftUI, Foundation, Darwin.
- Build, test, and run entirely from the command line (`make app`, `make test`, `make run`).
- All filtering logic lives in a UI-free module covered by unit tests.
- Code small enough to read in one sitting.

**Non-Goals:**
- Automated UI tests (manual checklist instead).
- Notarization or distribution signing; ad-hoc signing for local use only.
- Real-time list updates while the device menu is open.

## Decisions

### Swift + AppKit, with SwiftUI only inside the popover
AppKit's `NSStatusItem` and `NSMenu` give the native device menu, including Option-key
alternate items. The settings popover hosts a SwiftUI view, where editable text lists with
focus, Return, and Escape handling are straightforward.
- *Alternatives:* Rust + `objc2` (same AppKit calls through bindings, plus several crates and no
  SwiftUI); Rust + `tray-icon`/`muda` (cannot host text fields in menus); SwiftUI
  `MenuBarExtra` (cannot tell left clicks from right clicks).

### Package layout
```
Package.swift                 swift-tools-version 6.2, platforms: macOS 26
Sources/TTYBarCore/           pure logic, no AppKit
  GlobPattern.swift           match, escape
  PatternValidator.swift      validation rules and reasons
  DeviceFilter.swift          (paths, filters, mutes) -> sorted [String]
  DeviceScanner.swift         lists /dev (protocol + FileManager impl)
  SettingsStore.swift         @Observable model over UserDefaults
Sources/TTYBar/               executable, AppKit/SwiftUI
  main.swift / AppDelegate    activation policy, wiring
  StatusController.swift      status item, click routing, icon feedback
  DeviceMenu.swift            NSMenu building, copy, quick mute
  SettingsView.swift          SwiftUI popover content
Tests/TTYBarCoreTests/        Swift Testing
Resources/Info.plist          bundle metadata (LSUIElement = true)
Makefile                      build / app / run / test / clean
```
Splitting out `TTYBarCore` lets tests exercise all behavior from `specs/device-menu` and the
validation and persistence rules from `specs/filter-settings` without launching UI.

### Glob matching via Darwin `fnmatch`
Use `fnmatch(pattern, path, FNM_PATHNAME)`: `FNM_PATHNAME` stops `*` and `?` from matching `/`;
backslash escaping stays enabled; matching is case-sensitive by default. This is exactly the
shell semantics in the spec, with no custom matcher to maintain. `fnmatch` does not report
malformed patterns, so `PatternValidator` checks them before they are stored: non-empty after
trimming, `/dev/` prefix, balanced `[`/`]` (respecting escapes and a leading `]` or `!` in a
set), and no trailing unescaped backslash. Quick mute escapes `\ * ? [ ]` in the exact path.
- *Alternative:* a hand-written matcher (more code and tests, same behavior).

### Filtering and ordering as a pure function
`DeviceFilter.apply(paths:filters:mutes:)` keeps a path if it matches any filter and no mute,
deduplicates, and sorts with `compare(_:options: [.numeric])`. This ordering is deterministic and
locale-independent, unlike `localizedStandardCompare`.

### Scan in `menuNeedsUpdate`
The device menu's `NSMenuDelegate.menuNeedsUpdate(_:)` rebuilds the items. `contentsOfDirectory`
on `/dev` returns a few hundred names in microseconds, so no caching or IOKit notifications are
needed. The scanner sits behind a protocol so tests can inject fixed listings.

### Click routing
`statusItem.button.sendAction(on: [.leftMouseUp, .rightMouseUp])` with a single action that
reads `NSApp.currentEvent`. Right-mouse-up, or left-mouse-up with `.control`, toggles the popover.
Otherwise the controller closes the popover, temporarily assigns `statusItem.menu`, calls
`button.performClick(nil)`, and clears `statusItem.menu` in `menuDidClose`. This keeps the
system's menu placement and button highlight.
- *Alternative:* `NSMenu.popUp(positioning:at:in:)`, which positions the menu manually and loses
  the highlight. It is the fallback if the assign-and-click pattern misbehaves.

### Quick mute via alternate items
Each device gets two `NSMenuItem`s: the primary item (copy) and an alternate item
(`isAlternate = true`, `keyEquivalentModifierMask = .option`) titled "Mute <path>". AppKit swaps
them live while Option is held, which gives the "release Option" scenario for free.

### Copy feedback
Copying writes `path` via `NSPasteboard.general.clearContents()` + `setString(_:forType: .string)`.
Then the button image swaps to the template SF Symbol `checkmark`. A stored `Task` sleeps one
second and restores the normal icon; a new copy cancels and replaces the task, which restarts
the period. The normal icon is a template SF Symbol placeholder (`cable.connector`) until the
designer's asset exists.

### Settings popover
`NSPopover` (`behavior = .transient`) whose content is `NSHostingController(rootView:
SettingsView(store:))`, shown relative to the status button with `preferredEdge: .minY`. Because
the app is an accessory, `NSApp.activate()` is called before showing so text fields can take
keyboard focus. Each row holds a local draft string: `onSubmit` validates and commits through the
store, and `onExitCommand` reverts the draft. Validation errors render as a red caption under the
row. About calls `NSApp.orderFrontStandardAboutPanel(nil)` after activating the app; Quit calls
`NSApp.terminate(nil)`.

### Persistence in `UserDefaults`
Keys `filters` and `mutes` store `[String]`. When a key is missing (`object(forKey:) == nil`),
the store uses the default (`["/dev/tty.*"]` / `[]`). An explicitly stored empty array is kept,
which satisfies the "empty filter list survives relaunch" scenario. Every mutation writes
through immediately. `SettingsStore` takes a `UserDefaults` instance so tests can use a
throwaway suite. Store and UI types are `@MainActor` to satisfy Swift 6 strict concurrency.
- *Alternative:* a text config file (hand-editable, but needs a file format, parsing, and
  file watching). `defaults read/write` already allows hand edits.

### Agent mode and bundle
`Info.plist` sets `LSUIElement = true`, `LSMinimumSystemVersion = 26.0`, version strings, and
`NSHumanReadableCopyright` (shown in About). The app also calls
`NSApp.setActivationPolicy(.accessory)` at startup, so `swift run` without a bundle behaves the
same during development. `make app` runs `swift build -c release`, copies the binary into
`build/ttybar.app/Contents/MacOS/`, copies `Info.plist`, and signs with `codesign --sign -`.

### Tests without Xcode
`make test` runs `swift test` with the Command Line Tools framework flags from Context. If
`xcode-select -p` points into an Xcode app, it runs plain `swift test`. UI behavior is checked
by a manual checklist in the README, one entry per UI scenario in the specs.

## Risks / Trade-offs

- [Text fields in an accessory app's popover may not receive focus] → activate the app before
  showing the popover; covered by an early manual check.
- [Escape in a field might close the transient popover instead of reverting the draft] →
  `onExitCommand` on the focused field consumes it first; verify manually, and if needed handle
  `cancelOperation` in the hosting controller.
- [The assign-`statusItem.menu`-then-click pattern is a convention, not a documented API] →
  isolate it in `StatusController`; fall back to `NSMenu.popUp`.
- [Test flags depend on the Command Line Tools layout] → contained in the Makefile, with a
  plain `swift test` path when Xcode is present.
- [Ad-hoc signed app is not distributable] → acceptable for personal use; notarization is a
  separate change.
- [`/dev/tty.*` includes system noise such as Bluetooth and debug consoles] → handled by the
  user via mute and quick mute; no hardcoded exclusions.

## Open Questions

- Final bundle identifier and copyright string (placeholders until there is a publishing home).
- Final icon asset (designer); the SF Symbol placeholder is swapped in one place.
