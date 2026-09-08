# jlingo — Agent Context

## Project
Flutter language learning app ("Lingua Sprint"). Dark theme, portrait-only, no page transition animations. 7 languages: spanish, spanish_latam, french, dutch, portuguese, japanese, chinese.

## Stack
- **Flutter** + Material 3, dark theme (`#0D0D0D` bg, `#00D9FF` primary, `#00FF85` secondary)
- **State:** Provider (ChangeNotifier), 8 providers in `MultiProvider` in `main.dart`
- **Persistence:** SharedPreferences + JSON (`json_serializable`)
- **Navigation:** `PageRouteBuilder` with `transitionDuration: Duration.zero` everywhere
- **Audio:** flutter_tts, audioplayers, speech_to_text

## Directory Structure
```
lib/
├── main.dart                        # Entry point, providers, theme
├── models/                          # Data classes (all have .g.dart counterparts)
├── providers/                       # State management (8 providers)
├── screens/                         # Route-level UI
│   └── onboarding/                  # 4 onboarding screens
├── services/                        # audio_service, course_bootstrap, notification_service
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
| `ProgressProvider` | Skill mastery %, exercise stats, achievements |
| `GamificationProvider` | XP, 30-level system, daily goals, progression paths, **streaks** |
| `FlashcardProvider` | SM-2 spaced repetition, deck management |
| `VocabularyProvider` | Word of Day, Picture Dictionary |
| `BookProvider` | Bilingual books, reading progress |
| `OnboardingProvider` | Level quiz, goals, user profile |
| `SettingsProvider` | App preferences (progress tracking, notifications, TTS speech rate) |

## Asset Structure
- `assets/courses/<lang>/manifest.json` — `CourseManifest` with `SkillHeader` list (lightweight)
- `assets/courses/<lang>/skills/<skillId>.json` — full `Skill` with exercises (lazy loaded)
- `assets/vocabulary/flashcards_<courseId>.json`, `word_of_day_<courseId>.json` — per-course
- **Flutter asset dirs are not recursive:** `pubspec.yaml` must declare both
  `assets/courses/<lang>/` *and* `assets/courses/<lang>/skills/`. Omitting the
  second silently ships a course whose every lesson fails to load.

## Key Screens
| Screen | File |
|--------|------|
| Main learning hub | `screens/home_screen.dart` |
| Language picker | `screens/language_selection_screen.dart` |
| Exercise delivery | `screens/lesson_screen.dart` |
| Vocabulary hub | `screens/vocabulary_screen.dart` |
| Flashcard review | `screens/flashcard_screen.dart` |
| Bilingual reading | `screens/book_reader_screen.dart` |
| Application settings | `screens/settings_screen.dart` |

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
- Skills are cached in `CourseProvider._loadedSkills` after first load
- Language selection is persisted via `_selectedLanguageKey` in `CourseProvider`; restored in `HomeScreen._initializeApp()`
- **Per-course state must be keyed to `CourseProvider.currentManifest!.id`.** Several
  screens previously hardcoded `'default_course'`, so their writes landed under a key
  nothing read. `test/course_keying_test.dart` guards against this regressing.
- **Use `CourseBootstrap`** (`services/course_bootstrap.dart`) to load per-course
  providers — they must be loaded as a set when the course changes, or gamification
  and vocabulary end up stale on the previous course.
- Bundled vocabulary assets omit `createdAt` / `date`; the loaders stamp them. Adding
  those fields to an asset is not required, but removing the stamping breaks decoding.
- `GamificationProvider` owns streaks and XP. `ProgressProvider` no longer tracks
  either — pass the streak into `checkAndUnlockAchievements(currentStreak:)`.
- Don't run `flutter create .` — it overwrites platform config (see the macOS section of `README.md`).
- macOS requires deployment target 11.0 (`speech_to_text`).

## Tests
- `test/asset_integrity_test.dart` — manifests, skill files, pubspec declarations,
  exercise types, audio paths, bundled vocabulary. Run it after touching `assets/`.
- `test/course_keying_test.dart` — source-level guard against placeholder course ids.
- `test/gamification_math_test.dart` — level thresholds and streak multipliers.
