# Spec Delta

## Purpose

Lets the user see which serial devices in `/dev` match their filters and copy a device path
to the clipboard with a single click, without opening a terminal.

## ADDED Requirements

### Requirement: Device discovery on menu open
The system SHALL build the device list from the entries directly inside `/dev` (not
recursively) at the moment the device menu is opened, identifying each entry by its full
path `/dev/<name>`. The system SHALL NOT keep a background watcher and SHALL NOT open,
read, or lock any device file.

#### Scenario: Adapter plugged in while the menu is closed
- **WHEN** `/dev/tty.usbserial-A` appears after the menu was last closed
- **AND** the user opens the device menu
- **THEN** `/dev/tty.usbserial-A` is listed if it passes filtering

#### Scenario: Adapter unplugged while the menu is closed
- **WHEN** `/dev/tty.usbserial-A` disappears after the menu was last closed
- **AND** the user opens the device menu
- **THEN** `/dev/tty.usbserial-A` is not listed

#### Scenario: Device in use by another tool
- **WHEN** `/dev/tty.usbserial-A` is open in another program
- **AND** the user opens the device menu
- **THEN** the device is listed and the other program's session is unaffected

### Requirement: Glob pattern matching
Filter and mute patterns SHALL be matched case-sensitively against the full device path
using shell glob semantics: `*` matches any run of characters except `/`, `?` matches
exactly one character except `/`, `[...]` matches one character from a set or range
(`[!...]` negates), and a backslash makes the following character literal.

#### Scenario: Star wildcard
- **WHEN** the pattern is `/dev/tty.*`
- **THEN** `/dev/tty.usbserial-BOBBY_0` matches
- **AND** `/dev/cu.usbserial-BOBBY_0` does not match

#### Scenario: Character set
- **WHEN** the pattern is `/dev/tty.usbserial-BOBBY_[02]`
- **THEN** `/dev/tty.usbserial-BOBBY_0` and `/dev/tty.usbserial-BOBBY_2` match
- **AND** `/dev/tty.usbserial-BOBBY_1` does not match

#### Scenario: Case sensitivity
- **WHEN** the pattern is `/dev/tty.USB*`
- **THEN** `/dev/tty.usbmodem11101` does not match

#### Scenario: Escaped metacharacter
- **WHEN** the pattern is `/dev/tty.weird\[1\]`
- **THEN** `/dev/tty.weird[1]` matches
- **AND** `/dev/tty.weird1` does not match

### Requirement: Include and mute filtering
A device SHALL be listed if and only if its path matches at least one include filter and
matches no mute pattern. Mute patterns SHALL take precedence over include filters.

#### Scenario: Union of include filters
- **WHEN** the include filters are `/dev/tty.usbserial-*` and `/dev/tty.usbmodem*`
- **THEN** devices matching either pattern are listed

#### Scenario: Device matching several filters is listed once
- **WHEN** the include filters are `/dev/tty.*` and `/dev/tty.usb*`
- **AND** `/dev/tty.usbmodem11101` exists
- **THEN** `/dev/tty.usbmodem11101` appears exactly once

#### Scenario: Mute wins over include
- **WHEN** the include filters are `/dev/tty.*`
- **AND** the mute list contains `/dev/tty.Bluetooth-Incoming-Port`
- **THEN** `/dev/tty.Bluetooth-Incoming-Port` is not listed
- **AND** other `/dev/tty.*` devices are listed

### Requirement: Device ordering
Listed devices SHALL be sorted ascending by path, comparing embedded numbers by numeric
value so that `..._2` sorts before `..._10`.

#### Scenario: Numeric-aware order
- **WHEN** `/dev/tty.usbserial-10`, `/dev/tty.usbserial-2`, and `/dev/tty.usbmodem1` are listed
- **THEN** they appear in the order `/dev/tty.usbmodem1`, `/dev/tty.usbserial-2`, `/dev/tty.usbserial-10`

### Requirement: Empty states
The device menu SHALL show a single disabled informational item instead of devices when
nothing can be listed: "No filters — right-click to add" when the include filter list is
empty, otherwise "No matching devices" when no device passes filtering.

#### Scenario: No include filters configured
- **WHEN** the include filter list is empty
- **AND** the user opens the device menu
- **THEN** the menu shows the disabled item "No filters — right-click to add"

#### Scenario: Filters configured but nothing matches
- **WHEN** the include filter list is non-empty
- **AND** no device passes filtering
- **AND** the user opens the device menu
- **THEN** the menu shows the disabled item "No matching devices"

### Requirement: Copy device path
Selecting a device in the device menu SHALL replace the clipboard contents with the device's
full path as plain text, with no trailing newline, and close the menu.

#### Scenario: Copy a device
- **WHEN** the user clicks `/dev/tty.usbserial-PUMP` in the device menu
- **THEN** the clipboard contains exactly `/dev/tty.usbserial-PUMP`
- **AND** the menu closes

### Requirement: Copy confirmation
After a successful copy, the menu bar icon SHALL show a checkmark for about one second and
then return to the normal icon. A new copy during that period SHALL restart the period.

#### Scenario: Checkmark after copy
- **WHEN** the user copies a device path
- **THEN** the menu bar icon shows a checkmark
- **AND** about one second later it shows the normal icon again

#### Scenario: Repeated copy
- **WHEN** the user copies a second path while the checkmark is still shown
- **THEN** the checkmark stays visible for about one second after the second copy

### Requirement: Quick mute with Option
While the device menu is open and the Option key is held, each device item SHALL read
"Mute <path>". Selecting it SHALL add a pattern that matches exactly that path (glob
metacharacters escaped) to the mute list, unless an identical pattern is already present,
and SHALL NOT change the clipboard. The muted device SHALL no longer be listed the next time
the device menu opens.

#### Scenario: Mute a noisy device
- **WHEN** the user holds Option and selects "Mute /dev/tty.debug-console"
- **THEN** the mute list contains `/dev/tty.debug-console`
- **AND** the clipboard is unchanged
- **AND** the next opened device menu does not list `/dev/tty.debug-console`

#### Scenario: Mute a path containing glob metacharacters
- **WHEN** the user quick-mutes `/dev/tty.weird[1]`
- **THEN** the added mute pattern is `/dev/tty.weird\[1\]`
- **AND** `/dev/tty.weird1` is not muted by it

#### Scenario: Releasing Option
- **WHEN** the user releases Option while the device menu is open
- **THEN** the items show plain device paths again and selecting one copies it
