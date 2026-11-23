# Proposal

## Why

Embedded development on macOS means juggling many USB-UART adapters at once, and their
`/dev/tty.*` paths (e.g. `/dev/tty.usbserial-BOBBY_2`) have to be typed or copied into
terminals, scripts, and tools many times a day. A small, unobtrusive menu bar utility that
lists the matching devices and copies a path with one click removes that friction.

## What Changes

- New macOS 26+ menu bar application `ttybar` that runs as a background agent (no Dock icon,
  no main window) and shows a single template icon in the menu bar.
- Left click opens a device menu: entries of `/dev` that match at least one user-defined
  include filter and no mute pattern, scanned fresh every time the menu opens.
- Clicking a device copies its full path to the clipboard; the menu bar icon briefly turns
  into a checkmark as confirmation.
- Holding Option while the device menu is open turns each entry into "Mute <path>", which adds
  that exact path to the mute list.
- Right click opens a settings popover anchored to the icon, where include filters and mute
  patterns are edited in place (add, edit, remove), with invalid patterns highlighted and not
  applied. The popover also offers About and Quit.
- Filters and mutes are glob patterns matched against the full device path; defaults are one
  filter `/dev/tty.*` and an empty mute list. Settings persist across launches.
- Build tooling that produces a runnable `ttybar.app` from the command line without Xcode.

Non-goals for this change: `/dev/cu.*` pairing or special handling, launch at login,
USB descriptor details (vendor/product/serial) for devices, automatic updates, and a final
icon design (a placeholder system symbol is used).

## Capabilities

### New Capabilities

- `device-menu`: discovering `/dev` entries, include/mute filtering semantics, the left-click
  device menu, copy-to-clipboard with visual confirmation, and Option-click quick mute.
- `filter-settings`: the right-click settings popover, in-place editing of include filters and
  mute patterns, pattern validation, defaults, and persistence.
- `menu-bar-app`: the app's presence in the menu bar (background agent, status icon, left vs.
  right click routing), About, and Quit.

### Modified Capabilities

None.

## Impact

- Greenfield: adds a Swift package (app target, core logic target, tests), a build script /
  Makefile that assembles and ad-hoc signs `ttybar.app`, and a README.
- No external dependencies; only system frameworks (AppKit, SwiftUI, Foundation, Darwin).
- Reads directory entries of `/dev` only; never opens devices, so it cannot interfere with
  serial sessions in other tools.
- Writes only to the app's own user defaults and the general pasteboard.
