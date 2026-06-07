# Mac and iPhone Install Guide

This guide assumes the repository is published at:

```text
https://github.com/WhiteStoneJu/took
```

## 1. Prepare the Mac

Install these first:

- macOS that supports Xcode 26.
- Xcode 26 or later from the Mac App Store or Apple Developer.
- Git, if it is not already installed.
- Your Apple ID signed in to Xcode.

Open Xcode once after installing it so it can install required components.

## 2. Download Took

In Terminal on the Mac:

```bash
cd ~/Developer
git clone https://github.com/WhiteStoneJu/took.git
cd took
open Took.xcodeproj
```

If `~/Developer` does not exist:

```bash
mkdir -p ~/Developer
```

Alternative: open the GitHub page, choose **Code > Download ZIP**, unzip it, then open `Took.xcodeproj`.

## 3. Configure Signing

In Xcode:

1. Click the blue `Took` project icon in the left sidebar.
2. Select the `Took` target.
3. Open **Signing & Capabilities**.
4. Set **Team** to your Apple Developer team or personal Apple ID team.
5. Change **Bundle Identifier** from `com.example.took` to something unique, for example:

```text
com.whitestoneju.took
```

Then select the `TookWidgets` target and do the same:

```text
com.whitestoneju.took.TookWidgets
```

If the iPhone is older than the Xcode project's current setting, open **General > Minimum Deployments** for both `Took` and `TookWidgets` and change it from `iOS 26.0` to `iOS 16.2` or the iPhone's current iOS version.

## 4. Configure App Group

The app and widget must share the same App Group so the Live Activity button and shortcuts can read/write the same todo list.

Use a unique App Group such as:

```text
group.com.whitestoneju.took
```

Update all three places:

```text
Took/Took.entitlements
TookWidgets/TookWidgets.entitlements
TookShared/SharedStore.swift
```

In Xcode, for both `Took` and `TookWidgets` targets:

1. Open **Signing & Capabilities**.
2. Confirm **App Groups** exists.
3. Check the same group ID for both targets.

If Xcode shows a provisioning error, let it register the App Group automatically. A free personal team may be more limited; a paid Apple Developer account is more reliable for App Groups and device testing.

## 5. Enable iPhone For Development

On the iPhone:

1. Update to iOS 16.2 or later.
2. Connect the iPhone to the Mac with USB.
3. Trust the Mac when iOS asks.
4. Open **Settings > Privacy & Security > Developer Mode**.
5. Turn on Developer Mode and restart if prompted.

In Xcode:

1. Choose the iPhone from the run destination menu.
2. Select the `Took` scheme.
3. Press **Run**.

The first install may take a while because Xcode prepares device support and signing.

## 6. Allow Live Activities

After Took is installed:

1. Open Took.
2. Add a todo.
3. If iOS asks for Live Activities permission, allow it.
4. Lock the phone.
5. The current todo should appear on the Lock Screen Live Activity.

Tap the circle on the Live Activity to complete the todo. Direct Lock Screen completion requires iOS 17 or later, and iOS may require Face ID / unlock before the action runs. On iOS 16.2, tap the Live Activity to open Took and complete the todo in the app.

## 7. Add Todos From Shortcuts

Open the Shortcuts app:

1. Create a new shortcut.
2. Search for Took.
3. Choose **Add Todo**.
4. Provide text, or use a shortcut input variable.
5. Run it.

The new todo should become the current Lock Screen Live Activity item if there was no active todo, or update the visible current todo according to the app's top-open-item rule.

## 8. Configure Action Button Quick Add

On an iPhone with Action Button:

1. Open **Settings > Action Button**.
2. Choose **Shortcut**.
3. Select Took's **Quick Add Todo** shortcut.

Now long-pressing the Action Button opens Took directly to the quick-add input sheet.

Important limitation: iOS does not allow arbitrary keyboard text entry directly inside a Live Activity on the Lock Screen. The Action Button opens the app's input sheet after authentication. For hands-free capture, use Siri or Shortcuts with the `Add Todo` intent.

## 9. Troubleshooting

### The project does not build

- Confirm Xcode 26 or later is installed.
- Confirm both targets have a Development Team.
- Confirm the app and widget bundle identifiers are unique.
- Confirm the same App Group is used in both entitlements and `SharedStore.swift`.
- If Xcode says the iPhone iOS version is too low, lower **General > Minimum Deployments** for both targets.

### The widget or Live Activity cannot read todos

- Recheck the App Group ID in:

```text
Took/Took.entitlements
TookWidgets/TookWidgets.entitlements
TookShared/SharedStore.swift
```

- Clean build folder with **Product > Clean Build Folder**.
- Delete the app from the iPhone and run it again from Xcode.

### Lock Screen check button does not run while locked

iOS may require Face ID or device unlock before widget or Live Activity App Intent actions can mutate app state. This is expected system behavior. Direct Live Activity check buttons require iOS 17 or later.

### The Action Button shortcut does not appear

- Run Took once from Xcode.
- Open the Shortcuts app and search for Took.
- If needed, restart the iPhone after the first install.
