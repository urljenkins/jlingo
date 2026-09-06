# Lingua Sprint — macOS Notes

The `macos/`, `web/` and `ios/` directories already exist and are configured.

> **Do not run `flutter create .` on this project.**
> It regenerates the platform wrappers and would overwrite the macOS
> deployment target, bundle identifier, product name and sandbox
> entitlements documented below.

## Requirements

macOS **11.0 or later**. The `speech_to_text` plugin sets this floor; the
Flutter template default of 10.15 makes `pod install` fail with:

```
Error: The plugin "speech_to_text" requires a higher minimum macOS
deployment version than your application is targeting.
```

This is already set in `macos/Podfile` (`platform :osx, '11.0'`) and in
`MACOSX_DEPLOYMENT_TARGET` in the Xcode project.

## Running

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos
```

## Building

```bash
flutter build macos --release
# App is at: build/macos/Build/Products/Release/Lingua Sprint.app
```

## Platform configuration

Already applied — listed so it is not lost in a future regeneration:

| Setting | Value | Where |
|---|---|---|
| Product name | `Lingua Sprint` | `macos/Runner/Configs/AppInfo.xcconfig` |
| Bundle id | `com.linguasprint.app` | `macos/Runner/Configs/AppInfo.xcconfig` |
| Deployment target | `11.0` | `macos/Podfile`, Xcode project |
| Microphone access | `NSMicrophoneUsageDescription` | `macos/Runner/Info.plist` |
| Speech recognition | `NSSpeechRecognitionUsageDescription` | `macos/Runner/Info.plist` |
| Audio input entitlement | `com.apple.security.device.audio-input` | both `.entitlements` files |

The microphone strings and the audio-input entitlement are required for the
speaking and pronunciation exercises. Without them macOS terminates the app
when speech recognition starts.

## Expected result

The language selection screen — dark background, "Select Language", and the
seven bundled courses:

🇪🇸 Spanish · 🇲🇽 Spanish (Latin America) · 🇫🇷 French · 🇳🇱 Dutch ·
🇵🇹 Portuguese · 🇯🇵 Japanese · 🇨🇳 Chinese

If you see Flutter's default demo counter app instead, the build picked up a
stale `lib/main.dart` — run `flutter clean` and rebuild.
