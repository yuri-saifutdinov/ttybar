# menu-bar-app Specification

## Purpose

Defines how ttybar lives in the macOS menu bar: an unobtrusive background agent with one
status icon that routes left and right clicks, plus About and Quit.

## Requirements

### Requirement: Background agent
The app SHALL run without a Dock icon, without an entry in the application switcher, and
without opening any window at launch. Its only persistent UI SHALL be one menu bar icon.

#### Scenario: Launch
- **WHEN** the user launches ttybar
- **THEN** one ttybar icon appears in the menu bar
- **AND** no Dock icon and no window appear

### Requirement: Status icon appearance
The menu bar icon SHALL be a monochrome template image that follows the menu bar's light or
dark appearance, sized like standard system menu bar icons.

#### Scenario: Appearance change
- **WHEN** the system switches between light and dark appearance
- **THEN** the icon remains legible and matches other monochrome menu bar icons

### Requirement: Click routing
A left click on the icon SHALL open the device menu. A right click, or a left click with
Control held, SHALL open the settings popover. Opening one SHALL close the other if it is
open.

#### Scenario: Left click
- **WHEN** the user left-clicks the icon
- **THEN** the device menu opens

#### Scenario: Right click
- **WHEN** the user right-clicks the icon
- **THEN** the settings popover opens

#### Scenario: Control-click
- **WHEN** the user Control-clicks the icon
- **THEN** the settings popover opens

### Requirement: About
The About action SHALL show the standard macOS About panel with the app name, version, and
a short description, brought to the front.

#### Scenario: Show About
- **WHEN** the user chooses About in the settings popover
- **THEN** an About panel with the name "ttybar" and the app version appears in front of other windows

### Requirement: Quit
The Quit action SHALL terminate the app and remove its menu bar icon. Settings committed
before quitting SHALL be preserved.

#### Scenario: Quit
- **WHEN** the user chooses Quit in the settings popover
- **THEN** the app exits and its icon disappears from the menu bar
