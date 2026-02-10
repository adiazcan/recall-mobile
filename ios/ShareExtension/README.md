# iOS Share Extension Setup

## Overview

This directory contains the iOS Share Extension that allows users to share URLs from other apps (Safari, Chrome, etc.) directly to Recall.

## Xcode Setup Required

Since Flutter projects use Xcode for iOS builds, you need to manually add the Share Extension target to the Xcode project. Follow these steps:

### 1. Open the Project in Xcode

```bash
cd ios
open Runner.xcworkspace
```

### 2. Add Share Extension Target

1. In Xcode, select the **Runner** project in the Project Navigator
2. Click the **+** button at the bottom of the TARGETS list
3. Select **Share Extension** from the template chooser
4. Configure the target:
   - **Product Name**: `ShareExtension`
   - **Team**: Select your development team
   - **Bundle Identifier**: `com.recall.mobile.ShareExtension`
   - **Language**: Swift
   - Click **Finish**

### 3. Configure the Target

1. Delete the auto-generated files (if Xcode created them):
   - `ShareViewController.swift` (in the Xcode-created ShareExtension folder)
   - `MainInterface.storyboard`
   - `Info.plist`

2. Add the files from this directory to the ShareExtension target:
   - Right-click on the **ShareExtension** target in the Project Navigator
   - Select **Add Files to "ShareExtension"...**
   - Navigate to `ios/ShareExtension/`
   - Select `ShareViewController.swift` and `Info.plist`
   - Make sure **"Copy items if needed"** is UNCHECKED
   - Make sure the **ShareExtension** target is checked
   - Click **Add**

### 4. Configure App Groups

The Share Extension needs to communicate with the main app via shared storage:

1. Select the **Runner** target → **Signing & Capabilities**
2. Click **+ Capability** → Add **App Groups**
3. Click **+** to add a new group: `group.com.recall.mobile`

4. Select the **ShareExtension** target → **Signing & Capabilities**
5. Click **+ Capability** → Add **App Groups**
6. Check the existing `group.com.recall.mobile` group

### 5. Update Main App Info.plist

Add the custom URL scheme to the main app's Info.plist to handle URLs from the share extension:

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- Existing msauth scheme -->
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>msauth</string>
        </array>
        <key>CFBundleURLName</key>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    </dict>
    <!-- Add recall scheme for share extension -->
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>recall</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.recall.mobile.share</string>
    </dict>
</array>
```

### 6. Deployment Target

Make sure both targets have the same minimum deployment target:
- **Runner**: iOS 15.0
- **ShareExtension**: iOS 15.0

### 7. Build and Test

1. Select the **Runner** scheme
2. Build the project (⌘B)
3. Run on a device or simulator
4. Open Safari, navigate to a webpage, tap the Share button
5. You should see **Recall** in the share sheet

## How It Works

1. User shares a URL from another app
2. iOS presents the share sheet with Recall as an option
3. Share Extension receives the URL and stores it in a shared container (`group.com.recall.mobile`)
4. Share Extension opens the main app via the `recall://share?url=...` URL scheme
5. Main app reads the shared URL and navigates to the save screen (handled in `app.dart` and `router.dart`)

## Troubleshooting

### Share extension doesn't appear in share sheet
- Check that App Groups are configured correctly for both targets
- Verify the Info.plist has the correct `NSExtensionActivationRule`
- Make sure the ShareExtension target is included in the build

### App doesn't open after sharing
- Verify the `recall://` URL scheme is registered in the main app's Info.plist
- Check that the URL is being properly constructed in `ShareViewController.swift`

### Can't access shared URL in main app
- Ensure both targets use the same App Group ID: `group.com.recall.mobile`
- Check UserDefaults suite name matches the App Group ID

## Development Notes

- The Share Extension runs in a separate process from the main app
- Memory limits are stricter for extensions (~30MB)
- The extension should complete quickly and not perform heavy operations
- Use the shared container only for temporary data transfer
