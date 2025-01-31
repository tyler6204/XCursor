# XCursor

XCursor enables seamless iOS development in VSCode/Cursor while maintaining live previews and navigation sync with Xcode. Write your code in VSCode/Cursor while keeping Xcode's powerful SwiftUI previews visible and in sync.

## Quick Start

1. Join the [TestFlight Beta](https://testflight.apple.com/join/64N57Q66)
2. Install required VSCode extensions:
   - Swift by Swift Server Work Group
   - Sweetpad by sweetpad
   - XCursor (Sync Xcode)
3. For detailed setup instructions, click the XCursor icon in your Mac's menu bar and select "How to Use"

## Features

- 🔄 Real-time sync between VSCode/Cursor and Xcode
- 👀 Live SwiftUI previews
- 📱 iOS development in your preferred editor
- 🚀 Intelligent dependency resolution
- ⚡️ Swift/iOS code completion
- 🔄 **Smart File Switching**: Automatically switches to files with preview content
  - Currently only switches to files that have preview content available
  - Full file switching capability coming soon if wanted (I don't prefer it)

## How It Works

XCursor consists of two parts:

1. A native Mac app (available on TestFlight) that handles the Xcode integration
2. A VSCode extension that manages the editor integration

Together, they create a seamless development experience that combines the power of Xcode's preview system with the flexibility of VSCode/Cursor.

## Status Indicators

The menu bar icon shows the current sync status:

- 📄 Connected and syncing
- 🔍 Not connected to project
- 📄❌ XCursor is disabled

## Troubleshooting

If sync isn't working:

- Verify all extensions are installed
- Check Accessibility permissions
- Ensure build server configuration is generated
- Confirm both Xcode and VSCode/Cursor are running

## Support

Having issues? Please check the [issues](https://github.com/tyleryust/xcursor/issues) page or create a new one.

## License

MIT License - see LICENSE file for details
