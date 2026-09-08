# Lingua Sprint

A hyper-efficient language learning app for busy individuals focused on rapid, effective skill acquisition in 5-minute sessions.

## Features

- **Fast-paced Learning**: Complete maximum exercises in minimum time with instant transitions and no animations
- **18 Exercise Types**: typing, tap-to-assemble word banks, matching,
  multiple choice, listening, speaking, picture selection, cloze and story
  reading — see `ExerciseType` in `lib/models/exercise.dart` for the full list.
  Any type can be switched off globally or per course in settings.
- **Alphabet & Sounds**: a per-course letter chart with phonetic spelling,
  tap any letter to hear it
- **Rapid Drills**: high-volume word flash and match drills built from the
  course vocabulary
- **Simple Progress Tracking**: Streak counter, points, and skill mastery percentages
- **Minimal UI**: Clean, high-contrast dark mode interface
- **Offline-First**: All core learning available offline
- **Open Course Content**: Easily modify courses via JSON files

## Available Languages

Currently, Lingua Sprint supports the following languages:

| Course | Skills | Levels |
|---|---|---|
| 🇪🇸 Spanish | 69 | A1–C2 |
| 🇲🇽 Spanish (Latin America) | 69 | A1–C2 |
| 🇫🇷 French | 69 | A1–C2 |
| 🇳🇱 Dutch | 69 | A1–C2 |
| 🇵🇹 Portuguese (European) | 69 | A1–C2 |
| 🇧🇷 Portuguese (Brazilian) | 69 | A1–C2 |
| 🇯🇵 Japanese | 69 | A1–C2 |
| 🇨🇳 Chinese | 69 | A1–C2 |

Courses cover greetings, common phrases and numbers through to grammar,
listening, and C-level rhetoric and literature, using the exercise types
listed above.

Every course runs the full A1–C2 range at 69 skills. Where a course lacks
content in a tier a learner selects, they are placed at the nearest content
below it rather than skipped ahead.
`assets/courses/portuguese/planned_skills.json` tracks skills that are
outlined but not yet authored.

Learners pick a CEFR level when they start, or change it any time in
settings. The level decides where the course opens; everything below it
stays unlocked, so earlier lessons are always available.

## Philosophy

Lingua Sprint strips away all non-essential elements found in traditional language learning apps:
- No complex social features
- No punitive systems like "hearts" or "lives"
- No long animations or transitions
- No in-app purchases or subscriptions
- Just pure, focused learning

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK
- For macOS builds: macOS 11.0 or later (the `speech_to_text` plugin sets
  this floor)

### Installation

```bash
git clone <repository-url>
cd jlingo
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The generator step is required, not optional. Model serialization lives in
`.g.dart` files that are gitignored rather than committed, so a fresh clone
has none and the project will not compile until you run it. Re-run it
whenever you change a model class.

### Running

```bash
flutter run                 # default device
flutter run -d macos        # macOS desktop
flutter run -d chrome       # web
flutter run --release       # no debug banner
```

For macOS and web you may need to enable the platform once:

```bash
flutter config --enable-macos-desktop
flutter config --enable-web
```

### Troubleshooting

**Build errors, or `uri_has_not_been_generated`** — the generated model files
are missing or stale:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**Flutter's demo counter app appears instead of Lingua Sprint** — the build
picked up a stale `lib/main.dart`. Run `flutter clean` and rebuild.

**"Error loading lesson content" on every lesson** — a course's `skills/`
subdirectory is missing from `pubspec.yaml`. Asset directories are not
recursive; see [Adding New Languages](#adding-new-languages).

**No devices found** — open the iOS Simulator first, or enable the desktop
and web platforms with the `flutter config` commands above.

## Course Content

Each language lives in its own directory under `assets/courses/<language>/`:

```
assets/courses/spanish/
├── manifest.json          # Course metadata + the ordered list of skills
└── skills/
    ├── basics_1.json      # One file per skill, loaded lazily
    └── ...
```

`manifest.json` lists the course and its skills. Skill content is *not* inlined
here — each entry points at a file under `skills/`, loaded on demand:

```json
{
  "id": "spanish_en",
  "name": "Spanish for English Speakers",
  "targetLanguage": "es-ES",
  "nativeLanguage": "en-US",
  "skills": [
    { "id": "basics_1", "name": "Basics 1", "level": 1 }
  ]
}
```

A skill file holds the exercises:

```json
{
  "id": "basics_1",
  "name": "Basics 1",
  "description": "Learn basic greetings and introductions",
  "level": 1,
  "exercises": [
    {
      "id": "ex_1",
      "type": "translateThis",
      "question": "Hola",
      "options": [],
      "correctAnswer": "Hello"
    }
  ]
}
```

Every field above is required. `type` must be one of the values in the
`ExerciseType` enum (`lib/models/exercise.dart`); an unknown type makes the
whole skill fail to decode.

See `assets/courses/spanish/` for a complete example.

## Adding New Languages

1. Create `assets/courses/<language>/manifest.json` and a `skills/` directory
   beside it, following the structure above.
2. **Declare both directories in `pubspec.yaml`.** Flutter asset directories
   are not recursive, so the course directory and its `skills/` subdirectory
   each need their own entry:
   ```yaml
   assets:
     - assets/courses/<language>/
     - assets/courses/<language>/skills/
   ```
   Omitting the `skills/` line is the most common mistake: the app builds fine
   and every lesson fails at runtime with "Error loading lesson content".
3. Add the language to `loadAvailableLanguages` in
   `lib/providers/course_provider.dart`.
4. Add its display name and flag in `lib/screens/language_selection_screen.dart`.
5. Optionally add `assets/vocabulary/flashcards_<courseId>.json` and
   `word_of_day_<courseId>.json` for the vocabulary features.
6. Run `flutter test` — `test/asset_integrity_test.dart` verifies the manifest,
   the skill files, the pubspec declarations and the exercise types.

## Project Structure

```
lib/
├── models/       Data classes; each has a gitignored .g.dart counterpart
├── providers/    ChangeNotifier state (course, progress, settings, ...)
├── screens/      Top-level screens, plus onboarding/
├── services/     Audio, course bootstrap, lesson ordering, word pool
├── theme/        Colours, spacing and typography tokens
├── utils/        Small helpers
├── widgets/      exercises/ · drills/ · gamification/ · responsive/
└── main.dart

assets/
├── courses/      One directory per course (manifest + skills/)
├── vocabulary/   Flashcard decks, word of the day, picture dictionary
└── books/        Graded readers
```

`agents.md` holds a fuller map along with the project's conventions and
gotchas.

## Building for Release

The app id is `com.linguasprint.app` on all platforms.

### Android

Release builds are signed with the **debug key** until you provide a keystore,
so `flutter build apk --release` works out of the box but the result is **not
distributable**. To sign properly:

1. Create an upload keystore (keep the file and passwords safe — losing them
   means you can never update an existing Play listing):
   ```bash
   keytool -genkey -v -keystore ~/lingua-sprint-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` to `android/key.properties` and fill
   in your values. Both `key.properties` and `*.jks` are gitignored — never
   commit them.
3. Build:
   ```bash
   flutter build appbundle --release
   ```

Gradle picks up `key.properties` automatically when present and falls back to
the debug key when it is absent. Confirm which key was used with:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

`CN=Android Debug` means the fallback is still in effect.

Release builds are minified and resource-shrunk; see
`android/app/proguard-rules.pro` if a plugin needs keep rules.

### macOS

Requires macOS 11.0 or later — the `speech_to_text` plugin sets this floor,
and the Flutter template default of 10.15 makes `pod install` fail. This is
already set in `macos/Podfile` (`platform :osx, '11.0'`) and in
`MACOSX_DEPLOYMENT_TARGET` in the Xcode project.

```bash
flutter build macos --release
# App is at: build/macos/Build/Products/Release/Lingua Sprint.app
```

Signing and notarization are configured in Xcode against your Apple
developer account.

> **Do not run `flutter create .` on this project.** The `macos/`, `web/` and
> `ios/` directories already exist and are configured; regenerating the
> platform wrappers would overwrite the settings below.

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

## Tests

```bash
flutter test          # full suite
flutter analyze       # static analysis
```

`test/asset_integrity_test.dart` is the one to watch when editing course
content: it verifies every manifest, skill file, `pubspec.yaml` asset
declaration and exercise type, so a malformed course fails here rather than
at runtime in a lesson.

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **SharedPreferences**: Local data persistence
- **flutter_tts**: Text-to-speech functionality
- **speech_to_text**: Speech recognition
- **audioplayers**: Native audio playback
- **json_serializable**: JSON serialization (via `build_runner`)

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Areas for contribution:
- New language courses (JSON files)
- Additional exercise types
- UI improvements
- Bug fixes
- Documentation

Please ensure all contributions maintain the app's philosophy of speed and minimalism.
