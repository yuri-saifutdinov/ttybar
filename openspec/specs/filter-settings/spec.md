# filter-settings Specification

## Purpose

Lets the user maintain the include filters and mute patterns that decide which devices the
device menu lists, directly from the menu bar and without a separate settings window.

## Requirements

### Requirement: Settings popover
Right-clicking the menu bar icon SHALL open a settings popover anchored to the icon,
containing a "Filters" list, a "Muted" list, an About action, and a Quit action. The popover
SHALL close when the user clicks outside it or presses Escape while no field is being edited.

#### Scenario: Open and dismiss
- **WHEN** the user right-clicks the menu bar icon
- **THEN** the settings popover appears below the icon showing both lists
- **WHEN** the user clicks anywhere outside the popover
- **THEN** the popover closes

### Requirement: Edit patterns in place
Each list SHALL show one editable row per pattern with a remove control, followed by an
empty row for adding a new pattern. Pressing Return in a row SHALL commit it: committing the
add row appends the pattern and presents a new empty add row; committing an existing row
replaces that pattern; committing an existing row with empty text removes it. Pressing
Escape while editing a row SHALL discard that row's uncommitted text. Committed changes SHALL
apply to the next opened device menu without restarting the app.

#### Scenario: Add a filter
- **WHEN** the user types `/dev/tty.usbmodem*` into the Filters add row and presses Return
- **THEN** the Filters list contains `/dev/tty.usbmodem*`
- **AND** a new empty add row is shown
- **AND** the next opened device menu applies the new filter

#### Scenario: Edit a mute pattern
- **WHEN** the user changes the mute `/dev/tty.debug-console` to `/dev/tty.debug-*` and presses Return
- **THEN** the mute list contains `/dev/tty.debug-*` instead of `/dev/tty.debug-console`

#### Scenario: Remove with the remove control
- **WHEN** the user activates the remove control on the filter `/dev/tty.*`
- **THEN** `/dev/tty.*` is no longer in the Filters list

#### Scenario: Remove by clearing the text
- **WHEN** the user clears an existing row's text and presses Return
- **THEN** that pattern is removed from its list

#### Scenario: Discard an edit
- **WHEN** the user changes a row's text and presses Escape
- **THEN** the row shows its previously committed pattern

#### Scenario: Duplicate pattern
- **WHEN** the user commits a pattern already present in the same list
- **THEN** the list still contains that pattern exactly once

### Requirement: Pattern validation
Before a pattern is committed, surrounding whitespace SHALL be trimmed. A pattern SHALL be
valid only if it is non-empty, starts with `/dev/`, has every `[` closed by a matching `]`,
and does not end with an unescaped backslash. An invalid pattern SHALL be visibly marked in
its row with a short reason, SHALL NOT be committed, and the list SHALL keep its previous
contents.

#### Scenario: Pattern outside /dev
- **WHEN** the user commits `tty.*` in the Filters add row
- **THEN** the row is marked invalid with a reason mentioning `/dev/`
- **AND** the Filters list is unchanged

#### Scenario: Unclosed bracket
- **WHEN** the user commits `/dev/tty.usb[01` in an existing row
- **THEN** the row is marked invalid
- **AND** the previously committed pattern for that row stays in effect

#### Scenario: Whitespace trimmed
- **WHEN** the user commits `  /dev/tty.*  `
- **THEN** the stored pattern is `/dev/tty.*`

### Requirement: Defaults and persistence
On first launch the include filter list SHALL be `/dev/tty.*` and the mute list SHALL be
empty. Both lists, including an intentionally empty include filter list, SHALL persist
across app relaunches and system restarts, preserving the user's order.

#### Scenario: First launch
- **WHEN** the app starts with no saved settings
- **THEN** the Filters list is `/dev/tty.*`
- **AND** the Muted list is empty

#### Scenario: Settings survive relaunch
- **WHEN** the user adds a mute pattern, quits, and starts the app again
- **THEN** the mute pattern is still present

#### Scenario: Empty filter list survives relaunch
- **WHEN** the user removes all include filters, quits, and starts the app again
- **THEN** the Filters list is empty and the default is not restored
