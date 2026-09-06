# Lingua Sprint

A hyper-efficient language learning app for busy individuals focused on rapid, effective skill acquisition in 5-minute sessions.

## Features

- **Fast-paced Learning**: Complete maximum exercises in minimum time with instant transitions and no animations
- **Multiple Exercise Types**:
  - Translate This: Type translations of words/phrases
  - Match Pairs: Match words in native and target language
  - Multiple Choice: Quick answer selection
  - Listening Comprehension: Type what you hear
  - Speak This: Practice pronunciation with speech recognition
  - Fill in the Blank: Complete sentences
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
| 🇳🇱 Dutch | 69 | A1–C2 |
| 🇨🇳 Chinese | 69 | A1–C2 |
| 🇵🇹 Portuguese | 25 | A1–C2 |
| 🇯🇵 Japanese | 14 | A1–C2 |
| 🇫🇷 French | 11 | A1–C2 |

Courses cover greetings, common phrases and numbers through to grammar,
listening, and C-level rhetoric and literature, using the exercise types
listed above.

Every course reaches C2, but the density between A1 and C2 varies a great
deal — Japanese and French have few mid-tier skills, so a learner entering
at B1 or B2 there is placed at the nearest content below their level rather
than skipped ahead. `assets/courses/portuguese/planned_skills.json` tracks
skills that are outlined but not yet authored.

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

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd jlingo
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate model files:
```bash
flutter pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

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
├── models/
│   ├── book.dart
│   ├── course_manifest.dart
│   ├── exercise.dart
│   ├── flashcard.dart
│   ├── gamification.dart
│   ├── picture_dictionary.dart
│   ├── progress.dart
│   ├── skill.dart
│   ├── user_profile.dart
│   └── word_of_day.dart
├── providers/
│   ├── book_provider.dart
│   ├── course_provider.dart
│   ├── flashcard_provider.dart
│   ├── gamification_provider.dart
│   ├── onboarding_provider.dart
│   ├── progress_provider.dart
│   ├── settings_provider.dart
│   └── vocabulary_provider.dart
├── screens/
│   ├── onboarding/
│   │   ├── goals_screen.dart
│   │   ├── level_quiz_screen.dart
│   │   ├── onboarding_complete_screen.dart
│   │   └── welcome_screen.dart
│   ├── book_library_screen.dart
│   ├── book_reader_screen.dart
│   ├── flashcard_screen.dart
│   ├── home_screen.dart
│   ├── language_selection_screen.dart
│   ├── lesson_screen.dart
│   ├── picture_dictionary_screen.dart
│   ├── settings_screen.dart
│   ├── vocabulary_screen.dart
│   └── word_of_day_screen.dart
├── services/
│   ├── audio_service.dart
│   ├── course_bootstrap.dart
│   └── notification_service.dart
├── utils/
│   └── language_display.dart
├── widgets/
│   ├── exercises/
│   │   ├── cloze_test_widget.dart
│   │   ├── dialogue_listening_widget.dart
│   │   ├── exercise_renderer_registry.dart
│   │   ├── fill_blank_widget.dart
│   │   ├── interactive_dialogue_widget.dart
│   │   ├── listening_widget.dart
│   │   ├── match_pairs_widget.dart
│   │   ├── multiple_choice_widget.dart
│   │   ├── native_audio_widget.dart
│   │   ├── pronunciation_practice_widget.dart
│   │   ├── song_fill_widget.dart
│   │   ├── speak_this_widget.dart
│   │   ├── story_lesson_widget.dart
│   │   ├── translate_this_widget.dart
│   │   └── translation_exercise_widget.dart
│   ├── gamification/
│   │   ├── gamification_widgets.dart
│   │   ├── level_widgets.dart
│   │   ├── streak_widgets.dart
│   │   └── xp_widgets.dart
│   ├── responsive/
│   │   ├── desktop_scaffold.dart
│   │   ├── mobile_scaffold.dart
│   │   └── responsive_layout.dart
│   └── hover_card.dart
└── main.dart
```

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

Requires macOS 11.0 or later (`speech_to_text` sets this floor). Signing and
notarization are configured in Xcode against your Apple developer account.

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **SharedPreferences**: Local data persistence
- **flutter_tts**: Text-to-speech functionality
- **speech_to_text**: Speech recognition
- **json_serializable**: JSON serialization

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
