# ttybar

A tiny macOS menu bar utility for embedded developers: click the icon, see the serial
devices in `/dev`, click one to copy its path.

<p align="center">
  <img src="docs/screenshot.png" width="391" alt="ttybar menu open under its menu bar icon, listing four /dev/tty.* devices">
</p>

`/dev` is rescanned every time the menu opens, and devices are never opened, so sessions
in other tools are not affected. No dependencies, no network, no special permissions.

## Install

Requires macOS 26+ and Swift 6.2+ (the Xcode Command Line Tools are enough:
`xcode-select --install`).

```sh
git clone https://github.com/yuri-saifutdinov/ttybar.git
cd ttybar
make install
```

This builds the app, copies it to `/Applications` and launches it. To update, run
`git pull && make install`; settings are kept. To start at login, add ttybar under
**System Settings > General > Login Items & Extensions**.

To uninstall, quit ttybar, then:

```sh
rm -rf /Applications/ttybar.app
defaults delete dev.ttybar.TTYBar
```

## Usage

- **Click** the icon to list devices; click a device to copy its path
  (no trailing newline, so `picocom -b 115200 $(pbpaste)` works).
- **Option-click** a device to mute it.
- **Right-click** the icon for settings: filters, muted paths, About, Quit.

Filters and mutes are glob patterns on the full path (`*`, `?`, `[a-z]`, `[!a]`; `*` does
not cross `/`). A device is shown when it matches a filter and no mute. The default filter
is `/dev/tty.*`; narrower ones that are often handy:

```text
/dev/tty.usbmodem*      CDC-ACM boards (most dev kits, RP2040)
/dev/tty.usbserial-*    FTDI and similar USB-UART adapters
/dev/tty.wchusbserial*  CH34x adapters
```

If an adapter is missing, check `ls /dev/tty.*`: if it is not there, it needs a driver.

## Development

```sh
make test    # unit tests
make run     # build build/ttybar.app and launch it
```

Logic lives in `Sources/TTYBarCore` (unit-tested), the UI in `Sources/TTYBar`. UI changes
are checked by hand with [docs/manual-checklist.md](docs/manual-checklist.md). When bumping
the version, update both `Resources/Info.plist` and `Sources/TTYBarCore/Version.swift`.

Behavior is specified with [OpenSpec](https://github.com/Fission-AI/OpenSpec) in
`openspec/specs/`; larger changes start as a proposal in `openspec/changes/`. Issues and
pull requests are welcome.

## License

[MIT](LICENSE)
