# XCursor (Sync Xcode)

This extension enables seamless iOS development in VSCode/Cursor while maintaining live previews and navigation sync with Xcode.

## Prerequisites

Before you begin, ensure you have:

- VSCode/Cursor
- Xcode 14.0 or higher
- XCursor Mac app (TestFlight): [Join Beta](https://testflight.apple.com/join/64N57Q66)
- The following VSCode/Cursor extensions:
  - **Swift** by Swift Server Work Group
  - **Sweetpad** by sweetpad
  - **XCursor** (Sync Xcode) by tyleryust

## Setup Steps

1. Install required VSCode/Cursor extensions
2. Download XCursor from TestFlight
3. Open your iOS project in Xcode
4. Press `⌥⌘T` to enable compact Xcode view
5. Open a file with SwiftUI preview and maximize the preview pane
6. In VSCode/Cursor, open the parent folder containing your .xcodeproj
7. Press `⌘⇧P`, search for "sweetpad" and select "Generate Build Server Config"
8. Press `⌘⇧P` again, run "Build Without Run" and select any device
9. Position Xcode and VSCode/Cursor side by side
10. Resize Xcode to minimum width, keeping preview visible
11. Enable XCursor using the toggle in the menu bar

## Features

- Automatically syncs the currently active file in VSCode with Xcode
- Maintains connection with Xcode listener
- Handles connection interruptions gracefully

## Requirements

- VSCode 1.80.0 or higher
- Xcode must be running with the companion Xcode plugin

## Usage

The extension works automatically once installed. When you open or switch files in VSCode, it will automatically sync with Xcode.

## Known Issues

List any known issues here.

## Release Notes

### 0.0.1

Initial release of Sync with Xcode
