# Quick Start Guide - Lingua Sprint

## If You See the Wrong App or Demo App

If you're seeing Flutter's default counter app or something other than Lingua Sprint, follow these steps:

### Step 1: Clean Build
```bash
cd /path/to/jlingo
flutter clean
flutter pub get
```

### Step 2: Generate Required Files
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 3: Run the App
```bash
# For iOS Simulator
flutter run

# For macOS Desktop
flutter run -d macos

# For Chrome
flutter run -d chrome
```

### Step 4: Verify You're in the Right Directory
```bash
# Make sure you see Lingua Sprint files
ls lib/main.dart
cat pubspec.yaml | grep "lingua_sprint"
```

## What You Should See

When Lingua Sprint launches correctly, you'll see:

1. **First Screen**: Language Selection
   - Black background
   - "Select Language" title at top
   - List of 7 languages with flags:
     - 🇪🇸 Spanish
     - 🇲🇽 Spanish (Latin America)
     - 🇫🇷 French
     - 🇳🇱 Dutch
     - 🇵🇹 Portuguese
     - 🇯🇵 Japanese
     - 🇨🇳 Chinese

2. **After Selecting a Language**: Home Screen
   - Streak counter (🔥 Day 0) at top left
   - Points (⭐ 0) at top right
   - Large "CONTINUE" button
   - List of skills with circular progress indicators

3. **During Lessons**: Exercise Screen
   - Progress bar at top
   - Current question
   - Instant feedback (no animations)
   - Fast transitions between questions

## Common Issues

### Issue: Wrong App Showing
**Solution**: Make sure you're in `/path/to/jlingo` directory and run `flutter clean`

### Issue: Build Errors
**Solution**: Run `flutter pub get` then `flutter pub run build_runner build`

### Issue: "No devices found"
**Solution**:
- For iOS: Open Simulator app first
- For macOS: Run `flutter config --enable-macos-desktop`
- For Chrome: Run `flutter config --enable-web`

### Issue: Assets Not Loading
**Solution**: Make sure `assets/courses/` directory exists with JSON files

## Build Release Version

To get rid of the debug banner:

```bash
# Run in release mode
flutter run --release

# Or build release app
flutter build macos --release
# App will be at: build/macos/Build/Products/Release/Lingua Sprint.app
```

## Verify Installation

Run this to check everything is set up:

```bash
# Should show Lingua Sprint
grep "name:" pubspec.yaml

# Should list all language files
ls assets/courses/

# Should show main app code
head -5 lib/main.dart
```

If you see "LinguaSprintApp" in main.dart, you're good to go!
