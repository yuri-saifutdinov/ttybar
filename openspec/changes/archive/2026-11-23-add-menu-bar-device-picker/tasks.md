# Tasks

## 1. Project scaffolding

- [x] 1.1 Create `Package.swift` (tools 6.2, macOS 26) with targets `TTYBarCore` (library), `TTYBar` (executable depending on core), and `TTYBarCoreTests` (Swift Testing), plus empty source files; verify `swift build` succeeds
- [x] 1.2 Add `.build/` and `build/` to `.gitignore`; verify `git status` stays clean after a build
- [x] 1.3 Add a `Makefile` with `build` and `test` targets, where `test` passes the Command Line Tools `Testing.framework` search and rpath flags when Xcode is absent and runs plain `swift test` otherwise; verify `make test` runs and passes one placeholder test
- [x] 1.4 Create `README.md` with purpose, requirements (macOS 26, Swift 6.2 CLT), and the `make build` / `make test` commands; verify each documented command runs as written

## 2. Core logic (`TTYBarCore`)

- [x] 2.1 Implement `GlobPattern.matches(_:path:)` on Darwin `fnmatch` with `FNM_PATHNAME`; verify with tests covering `*`, `?`, `[...]`, `[!...]`, case sensitivity, escaped metacharacters, and `*` not crossing `/`
- [x] 2.2 Implement `GlobPattern.escape(_:)` for `\ * ? [ ]`; verify by tests that an escaped path matches only itself (e.g. `/dev/tty.weird[1]` vs `/dev/tty.weird1`)
- [x] 2.3 Implement `PatternValidator` (trim, non-empty, `/dev/` prefix, balanced brackets including escapes and leading `]`/`!`, no trailing backslash), returning a short reason on failure; verify with tests for every rule and for the spec scenarios (`tty.*`, `/dev/tty.usb[01`, surrounding whitespace)
- [x] 2.4 Implement `DeviceFilter.apply(paths:filters:mutes:)` with union of filters, mute precedence, deduplication, and `.numeric` ordering; verify with tests for every scenario in the device-menu spec's filtering and ordering requirements
- [x] 2.5 Implement a `DeviceScanner` protocol and a `FileManager`-backed scanner returning `/dev/<name>` for top-level entries; verify with a test that scans a temporary directory and checks paths are full and not recursive
- [x] 2.6 Implement `@MainActor @Observable SettingsStore` over an injected `UserDefaults` (keys `filters`, `mutes`; defaults when a key is missing; write-through; add/replace/remove with validation and duplicate suppression; `mute(exactPath:)` using escape); verify with tests on a throwaway suite for first-launch defaults, persistence across store instances, a persisted empty filter list, duplicates, and invalid input that leaves the lists unchanged

## 3. Menu bar app shell

- [x] 3.1 Add the app entry point and `AppDelegate`: set `.accessory` activation policy, create `SettingsStore` with `UserDefaults.standard`, and create a status item with the template SF Symbol `cable.connector`; verify `swift run TTYBar` shows one icon, no Dock icon, and no window
- [x] 3.2 Add `Resources/Info.plist` (`LSUIElement`, `LSMinimumSystemVersion` 26.0, name, version, placeholder bundle id and copyright) and Makefile targets `app` (release build, assemble `build/ttybar.app`, `codesign --sign -`), `run`, and `clean`; verify `make app && open build/ttybar.app` launches the agent and `codesign -dv build/ttybar.app` reports an ad-hoc signature
- [x] 3.3 Implement click routing in `StatusController` (left → device menu via assign-menu-and-click, right or Control-left → toggle popover, each closing the other) with placeholder menu and popover content; verify all three click scenarios of the menu-bar-app spec manually and add them to the README manual checklist
- [x] 3.4 Document `make app` / `make run` and how to install the app (copy to `/Applications`) in the README; verify the documented steps produce a working app

## 4. Device menu

- [x] 4.1 Build the device menu in `menuNeedsUpdate` from scanner, store, and `DeviceFilter`, including the two disabled empty-state items; verify manually by plugging and unplugging an adapter between openings, removing all filters, and setting a filter that matches nothing
- [x] 4.2 Implement copy on selection (clear pasteboard, set plain string) and the one-second checkmark icon with a cancellable restore task; verify by pasting into a terminal (`pbpaste | od -c` shows no trailing newline) and by watching the checkmark restart on a quick second copy
- [x] 4.3 Add Option alternate items "Mute <path>" that call `store.mute(exactPath:)` without touching the pasteboard; verify manually that holding and releasing Option swaps items, that a muted device disappears on the next opening, and that the clipboard is unchanged
- [x] 4.4 Add the device-menu scenarios (discovery, empty states, copy, checkmark, quick mute) to the README manual checklist and a short usage section; verify every checklist entry passes on the built app

## 5. Settings popover

- [x] 5.1 Show an `NSPopover` (`.transient`) hosting `SettingsView` below the status button, activating the app first; verify the popover opens on right click, a text field accepts typing immediately, and clicking outside closes it
- [x] 5.2 Implement the Filters and Muted sections with editable rows (local draft, Return commits through the store, empty commit removes, Escape reverts), remove buttons, and an add row that resets after commit; verify every edit scenario of the filter-settings spec manually, including that changes apply to the next device menu
- [x] 5.3 Show validation errors as a red caption under the offending row, keeping the committed value; verify with `tty.*` and `/dev/tty.usb[01` that the row is marked and the list is unchanged
- [x] 5.4 Add About (activate app, standard About panel) and Quit actions to the popover; verify About appears in front with name and version, and Quit removes the icon while settings survive a relaunch
- [x] 5.5 Check that Escape inside a field reverts only the field and Escape outside a field closes the popover, adding a `cancelOperation` override if needed; verify both behaviors manually
- [x] 5.6 Add the settings scenarios (open/dismiss, add/edit/remove, validation, About, Quit, persistence) to the README manual checklist and usage section; verify every entry passes on the built app

## 6. Integration check

- [x] 6.1 From a clean clone, run `make clean test app`, launch `build/ttybar.app`, and walk the full README manual checklist with real adapters attached; verify all core tests and all checklist entries pass, and run `openspec validate add-menu-bar-device-picker --strict` with no errors
