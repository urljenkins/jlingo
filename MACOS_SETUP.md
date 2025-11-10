# Lingua Sprint - macOS Setup Fix

## Problem
The project is missing platform-specific files for macOS and web.

## Solution

Run this command in your project directory:

```bash
cd /path/to/jlingo
flutter create . --platforms=macos,web
```

**This is safe!** It will only add the missing `macos/` and `web/` directories without touching your existing code in `lib/`.

## Then Run the App

After adding platform support:

```bash
# For macOS Desktop
flutter run -d macos

# Or for Chrome browser
flutter run -d chrome
```

## Alternative: iOS Simulator

If you have Xcode installed, you can also add iOS support:

```bash
flutter create . --platforms=ios
open -a Simulator
flutter run
```

## What This Does

The `flutter create .` command:
- ✅ Adds `macos/` directory with native macOS app wrapper
- ✅ Adds `web/` directory with HTML/JS wrapper
- ✅ Does NOT modify your `lib/` code (your app stays intact)
- ✅ Does NOT modify `pubspec.yaml`, `assets/`, or any existing files

## Full Setup Commands

```bash
# Navigate to project
cd /path/to/jlingo

# Add platform support
flutter create . --platforms=macos,web,ios

# Get dependencies
flutter pub get

# Generate model files
flutter pub run build_runner build --delete-conflicting-outputs

# Run on macOS
flutter run -d macos --release
```

## Expected Result

You should see the **Lingua Sprint** language selection screen with:
- Dark background
- "Select Language" title
- 7 languages with flags (🇪🇸 🇫🇷 🇩🇪 🇳🇱 🇵🇹 🇯🇵 🇨🇳)

NOT Flutter's default demo app.
