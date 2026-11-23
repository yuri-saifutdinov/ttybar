# Manual checklist

UI behavior is not covered by automated tests. Run through this list on `build/ttybar.app` (`make run`)
after UI changes.

## Menu bar app
- [ ] Launch: one icon appears in the menu bar; no Dock icon, no window.
- [ ] Switch between light and dark appearance: the icon stays legible and monochrome.
- [ ] Left click opens the device menu.
- [ ] Right click opens the settings popover.
- [ ] Control-click opens the settings popover.
- [ ] Opening the device menu closes the popover, and vice versa.

## Device menu
- [ ] Plug in an adapter with the menu closed, then open it: the adapter is listed.
- [ ] Unplug it with the menu closed, then open it: the adapter is gone.
- [ ] A device opened in another tool (e.g. `screen`) is still listed and the session is unaffected.
- [ ] Remove all filters: the menu shows the disabled item "No filters — right-click to add".
- [ ] Use a filter that matches nothing: the menu shows the disabled item "No matching devices".
- [ ] Devices are sorted with numbers by value (`..._2` before `..._10`).
- [ ] Click a device: the menu closes and `pbpaste | od -c` shows the path with no trailing newline.
- [ ] After a copy the icon shows a checkmark for about a second; a second quick copy restarts it.
- [ ] Hold Option: items read "Mute <path>"; release Option: plain paths again.
- [ ] Option-click a device: the clipboard is unchanged, the path appears under Muted, and the
      device is gone the next time the menu opens.

## Settings popover
- [ ] Right click: the popover appears below the icon with Filters and Muted; clicking outside closes it.
- [ ] A text field accepts typing right after the popover opens.
- [ ] Type `/dev/tty.usbmodem*` in the Filters add row, press Return: it is added and a new
      empty add row appears; the next device menu uses it.
- [ ] Edit a mute pattern and press Return: it is replaced.
- [ ] The minus button removes a pattern.
- [ ] Clear a row and press Return: the pattern is removed.
- [ ] Change a row and press Escape: the previous text is restored and the popover stays open.
- [ ] Press Escape in an unchanged row: the popover closes.
- [ ] Add a pattern that already exists: it is listed once.
- [ ] Commit `tty.*`: the row is marked red with "Must start with /dev/", the list is unchanged.
- [ ] Commit `/dev/tty.usb[01` in an existing row: marked red, the old pattern stays in effect.
- [ ] Commit `  /dev/tty.*  `: stored without surrounding spaces.
- [ ] About shows the standard panel with "ttybar" and the version, in front of other windows.
- [ ] Quit removes the icon; after relaunch, filters and mutes (including an empty filter list) are kept.
