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
- 🇪🇸 Spanish
- 🇫🇷 French
- 🇩🇪 German
- 🇳🇱 Dutch
- 🇵🇹 Portuguese
- 🇯🇵 Japanese
- 🇨🇳 Chinese

Each language course includes basic greetings, common phrases, and numbers with multiple exercise types.

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

Course content is stored in JSON format in `assets/courses/`. Each language has its own JSON file with the following structure:

```json
{
  "id": "language_code",
  "name": "Language Name",
  "targetLanguage": "language-code",
  "nativeLanguage": "en-US",
  "skills": [...]
}
```

See `assets/courses/spanish.json` for a complete example.

## Adding New Languages

1. Create a new JSON file in `assets/courses/` (e.g., `german.json`)
2. Follow the structure in existing course files
3. Update the `availableLanguages` list in `lib/providers/course_provider.dart`
4. Add the language flag in `lib/screens/language_selection_screen.dart`

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── course.dart
│   ├── exercise.dart
│   ├── skill.dart
│   └── progress.dart
├── providers/                     # State management
│   ├── course_provider.dart
│   └── progress_provider.dart
├── screens/                       # Main screens
│   ├── home_screen.dart
│   ├── language_selection_screen.dart
│   └── lesson_screen.dart
└── widgets/                       # Reusable widgets
    └── exercises/                 # Exercise type widgets
        ├── translate_this_widget.dart
        ├── multiple_choice_widget.dart
        ├── match_pairs_widget.dart
        ├── listening_widget.dart
        ├── speak_this_widget.dart
        └── fill_blank_widget.dart
```

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
