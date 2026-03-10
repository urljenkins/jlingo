# jlingo — Agent Context

## Project
Flutter language learning app ("Lingua Sprint"). Dark theme, portrait-only, no page transition animations. 7 languages: spanish, french, german, dutch, portuguese, japanese, chinese.

## Stack
- **Flutter** + Material 3, dark theme (`#0D0D0D` bg, `#00D9FF` primary, `#00FF85` secondary)
- **State:** Provider (ChangeNotifier), 7 providers in `MultiProvider` in `main.dart`
- **Persistence:** SharedPreferences + JSON (`json_serializable`)
- **Navigation:** `PageRouteBuilder` with `transitionDuration: Duration.zero` everywhere
- **Audio:** flutter_tts, audioplayers, speech_to_text

## Directory Structure
```
lib/
├── main.dart                        # Entry point, providers, theme
├── models/                          # Data classes (all have .g.dart counterparts)
├── providers/                       # State management (7 providers)
├── screens/                         # Route-level UI
│   └── onboarding/                  # 4 onboarding screens
├── services/                        # audio_service, notification_service
└── widgets/
    ├── exercises/                   # 14 exercise renderers + registry
    ├── gamification/                # XP, level, streak, progression widgets
    ├── responsive/                  # ResponsiveLayout, MobileScaffold, DesktopScaffold
    └── hover_card.dart
```

## Providers
| Provider | Responsibility |
|----------|---------------|
| `CourseProvider` | Manifest loading, lazy skill loading (cached), language persistence |
| `ProgressProvider` | Skill mastery %, points, streaks, achievements |
| `GamificationProvider` | XP, 30-level system, daily goals, progression paths |
| `FlashcardProvider` | SM-2 spaced repetition, deck management |
| `VocabularyProvider` | Word of Day, Picture Dictionary |
| `BookProvider` | Bilingual books, reading progress |
| `OnboardingProvider` | Level quiz, goals, user profile |

## Asset Structure
- `assets/courses/<lang>/manifest.json` — `CourseManifest` with `SkillHeader` list (lightweight)
- `assets/courses/<lang>/skills/<skillId>.json` — full `Skill` with exercises (lazy loaded)

## Key Screens
| Screen | File |
|--------|------|
| Main learning hub | `screens/home_screen.dart` |
| Language picker | `screens/language_selection_screen.dart` |
| Exercise delivery | `screens/lesson_screen.dart` |
| Vocabulary hub | `screens/vocabulary_screen.dart` |
| Flashcard review | `screens/flashcard_screen.dart` |
| Bilingual reading | `screens/book_reader_screen.dart` |

## Models (JSON-serializable)
`UserProgress`, `CourseManifest`/`SkillHeader`, `Skill`, `Exercise` (14 `ExerciseType` values), `UserLevel`, `StreakInfo`, `DailyGoal`, `XPEvent`, `ProgressionPath`, `Flashcard`/`FlashcardDeck`, `WordOfDay`, `PictureDictionaryTopic`, `BilingualBook`/`BookProgress`, `UserProfile`

## ExerciseType Values
`translateThis`, `matchPairs`, `multipleChoice`, `listeningComprehension`, `speakThis`, `fillInBlank`, `nativeAudio`, `pronunciationPractice`, `dialogueListening`, `songFill`, `interactiveDialogue`, `storyLesson`, `translationExercise`, `clozeTest`

## Conventions
- All navigation uses `PageRouteBuilder` with `transitionDuration: Duration.zero`
- Layouts always go through `ResponsiveLayout` → `MobileScaffold` / `DesktopScaffold`
- `context.read<>()` for imperative actions; `Consumer` / `context.watch<>()` for reactive UI
- State updates via `copyWith()` — all models are immutable
- SharedPreferences keys: `<type>_<courseId>` (e.g., `progress_spanish`, `selected_language`)
- Private members: `_leadingUnderscore`
- No "Co-Authored-By: Claude" in commit messages

## Gotchas
- `Course` model is legacy — current path uses `CourseManifest` + per-skill JSON files
- `main.dart` lists 5 providers in the comment but actually initializes 7
- Skills are cached in `CourseProvider._loadedSkills` after first load
- Language selection is persisted via `_selectedLanguageKey` in `CourseProvider`; restored in `HomeScreen._initializeApp()`
