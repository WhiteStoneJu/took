# Took

Took is a native SwiftUI todo app prototype for modern iOS.

Core behavior:

- Add todos in the app.
- Add todos through App Shortcuts / Shortcuts using `Add Todo`.
- Keep incomplete todos visible in a Live Activity on the Lock Screen.
- Check visible todos from the Live Activity on iOS 17 or later.
- Open the app into quick-add mode from the Live Activity or widget URL.
- Browse remaining and completed todos by date.
- Customize the Lock Screen Live Activity background transparency and text color.
- Assign iPhone Action Button to the `Quick Add Todo` shortcut so a long press opens Took's input sheet.

## Requirements

- macOS with Xcode 26 or later.
- iOS 16.2 or later simulator or device.
- An Apple Developer team configured in Xcode for App Groups and Live Activities.

## Setup

1. Open `Took.xcodeproj` in Xcode 26.
2. Select the `Took` project and set your Development Team for both targets.
3. In **General > Minimum Deployments**, if Xcode still shows `iOS 26.0` and the iPhone is older, change it to `iOS 16.2` or the iPhone's current iOS version.
4. Replace these placeholder identifiers if needed:
   - App bundle ID: `com.example.took`
   - Widget bundle ID: `com.example.took.TookWidgets`
   - App Group: `group.com.example.took`
5. If you change the App Group, update it in:
   - `Took/Took.entitlements`
   - `TookWidgets/TookWidgets.entitlements`
   - `TookShared/SharedStore.swift`
6. Run the `Took` scheme on an iOS 16.2 or later simulator or device.

For detailed Mac-to-iPhone installation steps, see `INSTALL_ON_MAC_AND_IPHONE.md`.

## Action Button

On iPhone models with Action Button:

1. Open Settings.
2. Choose Action Button.
3. Select Shortcut.
4. Pick Took's `Quick Add Todo` shortcut.

After that, long-pressing the Action Button opens Took directly to the quick todo input sheet.

## Platform Note

iOS Live Activities can show information and run limited interactive App Intent controls, such as a check button on iOS 17 or later. They cannot present arbitrary free-text entry directly on the Lock Screen. Took handles quick capture through the app, URL deep link, Siri, and Shortcuts/App Intents, while the Lock Screen Live Activity focuses on displaying and completing todos.
