# jlingo Exercise Authoring Guide (AI Prompt Reference)

Use this guide as system context or instructions when using an AI tool to create or edit course skills in `assets/courses/<lang>/skills/<skill_id>.json`.

---

## 1. Skill File Structure

Every skill file must have the following root structure:
```json
{
  "id": "skill_id_matching_filename",
  "name": "Skill Name",
  "description": "Short description of what the learner will learn",
  "level": 1,
  "exercises": [
    ...
  ]
}
```

### Core Rules for AI Generation
1. **Unique IDs**: Every exercise within a skill must have a unique `id` (e.g. `ex_1`, `ex_2`, `ex_food_1`).
2. **Audio Paths**: Do **not** invent arbitrary `.mp3` paths in `audioPath`. If you do not have a real file in `assets/`, omit `audioPath` or pass `null`. The app automatically uses native Text-To-Speech (TTS) for questions when `audioPath` is omitted.
3. **Languages**: `targetLanguage` and `nativeLanguage` are stamped automatically by the course loader from the manifest, so you can omit them or include standard BCP-47 codes (e.g. `es-ES`, `en-US`).
4. **Distractors**: In `multipleChoice`, `fillInBlank`, and `clozeTest`, ensure the `correctAnswer` is included in `options` and distractors are plausible.

---

## 2. All 18 Exercise Types: JSON Templates

### 1. `multipleChoice`
Learner picks 1 correct answer from 3–4 options.
```json
{
  "id": "ex_mc_1",
  "type": "multipleChoice",
  "question": "What does 'Gracias' mean?",
  "options": ["Thank you", "Please", "Goodbye", "Hello"],
  "correctAnswer": "Thank you"
}
```

### 2. `translateThis`
Text input or free translation.
```json
{
  "id": "ex_tr_1",
  "type": "translateThis",
  "question": "Hola",
  "options": [],
  "correctAnswer": "Hello / Hi"
}
```

### 3. `fillInBlank`
Sentence with blank `___` and word choices.
```json
{
  "id": "ex_fib_1",
  "type": "fillInBlank",
  "question": "Buenos ___ (Good morning)",
  "options": ["días", "noches", "tardes", "hola"],
  "correctAnswer": "días"
}
```

### 4. `matchPairs`
Pair matching (minimum 3–4 pairs). Note: `correctAnswer` is empty string.
```json
{
  "id": "ex_mp_1",
  "type": "matchPairs",
  "question": "Match the Spanish words with their English translations",
  "options": [],
  "correctAnswer": "",
  "metadata": {
    "pairs": [
      { "target": "Hola", "native": "Hello" },
      { "target": "Adiós", "native": "Goodbye" },
      { "target": "Gracias", "native": "Thank you" },
      { "target": "Por favor", "native": "Please" }
    ]
  }
}
```

### 5. `listeningComprehension`
Learner listens (via TTS) and picks or types the correct answer.
```json
{
  "id": "ex_lc_1",
  "type": "listeningComprehension",
  "question": "Buenas tardes",
  "options": ["Buenas tardes", "Buenas noches", "Buenos días"],
  "correctAnswer": "Buenas tardes"
}
```

### 6. `speakThis`
Learner speaks the target sentence aloud via microphone speech recognition.
```json
{
  "id": "ex_st_1",
  "type": "speakThis",
  "question": "Hola, ¿cómo estás?",
  "options": [],
  "correctAnswer": "Hola, ¿cómo estás?"
}
```

### 7. `wordBankTranslate`
Learner translates a sentence by tapping shuffled word tiles. `options` provides extra distractor tiles.
```json
{
  "id": "ex_wb_1",
  "type": "wordBankTranslate",
  "question": "Yo soy de México.",
  "options": ["and", "nice", "from"],
  "correctAnswer": "I am from Mexico"
}
```

### 8. `tapWhatYouHear`
Learner hears the phrase via audio/TTS and rebuilds it using word tiles.
```json
{
  "id": "ex_twyh_1",
  "type": "tapWhatYouHear",
  "question": "",
  "options": ["taco", "por favor"],
  "correctAnswer": "Yo soy de Alemania"
}
```

### 9. `clozeTest`
Multi-blank fill-in-the-blank with contextual options.
```json
{
  "id": "ex_cloze_1",
  "type": "clozeTest",
  "question": "El ___ es un animal que ___ en el agua.",
  "options": ["pez", "vive", "corre", "perro"],
  "correctAnswer": "pez,vive",
  "metadata": {
    "context": "Complete the sentence about animals and where they live.",
    "blanks": [
      {
        "index": 0,
        "answer": "pez",
        "options": ["pez", "perro", "gato"]
      },
      {
        "index": 1,
        "answer": "vive",
        "options": ["vive", "corre", "duerme"]
      }
    ]
  }
}
```

### 10. `interactiveDialogue`
Branched conversation where the learner selects their turn.
```json
{
  "id": "ex_id_1",
  "type": "interactiveDialogue",
  "question": "¿Cómo estás?",
  "options": ["Muy bien, gracias", "Un café, por favor"],
  "correctAnswer": "Muy bien, gracias",
  "metadata": {
    "topic": "Greetings",
    "dialogue": [
      { "speaker": "Ana", "text": "¡Hola! ¿Cómo estás?" },
      {
        "speaker": "You",
        "isUserTurn": true,
        "options": ["Muy bien, gracias", "Un café, por favor"],
        "answer": "Muy bien, gracias"
      }
    ]
  }
}
```

### 11. `dialogueListening`
Listens to multiple lines of dialogue, followed by a comprehension question.
```json
{
  "id": "ex_dl_1",
  "type": "dialogueListening",
  "question": "What does Ana ask?",
  "options": ["She asks how you are", "She orders a coffee"],
  "correctAnswer": "She asks how you are",
  "metadata": {
    "comprehensionQuestion": "What does Ana ask?",
    "options": ["She asks how you are", "She orders a coffee"],
    "dialogue": [
      { "speaker": "Ana", "text": "¡Hola Carlos! ¿Cómo estás?" },
      { "speaker": "Carlos", "text": "¡Hola Ana! Muy bien, ¿y tú?" }
    ]
  }
}
```

### 12. `storyLesson`
Reading comprehension with vocabulary highlights and a question.
```json
{
  "id": "ex_story_1",
  "type": "storyLesson",
  "question": "What does the cat drink?",
  "options": ["Milk", "Water", "Juice"],
  "correctAnswer": "Milk",
  "metadata": {
    "title": "El gato feliz",
    "story": "El gato bebe leche en la cocina. El gato es muy feliz.",
    "question": "What does the cat drink?",
    "vocabulary": [
      { "word": "gato", "translation": "cat" },
      { "word": "leche", "translation": "milk" }
    ]
  }
}
```

### 13. `completeTheChat`
Chat message history with missing response.
```json
{
  "id": "ex_chat_1",
  "type": "completeTheChat",
  "question": "Hola, yo soy Luis.",
  "options": ["¡Mucho gusto, Luis!", "No, un café, por favor."],
  "correctAnswer": "¡Mucho gusto, Luis!",
  "metadata": {
    "lines": [
      { "text": "Hola, yo soy Luis. Yo soy de México.", "isLearner": false }
    ]
  }
}
```

### 14. `selectImage`
Select the matching emoji or picture for a word.
```json
{
  "id": "ex_img_1",
  "type": "selectImage",
  "question": "helado",
  "options": ["ice cream", "taco", "sandwich", "tea"],
  "correctAnswer": "ice cream",
  "metadata": {
    "emoji": {
      "ice cream": "🍦",
      "taco": "🌮",
      "sandwich": "🥪",
      "tea": "🍵"
    }
  }
}
```

### 15. `pronunciationPractice`
Speech recognition scoring accent and pronunciation.
```json
{
  "id": "ex_pron_1",
  "type": "pronunciationPractice",
  "question": "Buenos días",
  "options": [],
  "correctAnswer": "Buenos días"
}
```

### 16. `nativeAudio`
Listen to audio (or TTS if file omitted) and choose/transcribe.
```json
{
  "id": "ex_na_1",
  "type": "nativeAudio",
  "question": "Buenos días",
  "options": [],
  "correctAnswer": "Buenos días"
}
```

### 17. `songFill`
Listen to lyrics and fill missing blanks.
```json
{
  "id": "ex_song_1",
  "type": "songFill",
  "question": "La ___ es bella",
  "options": ["vida", "casa"],
  "correctAnswer": "vida",
  "metadata": {
    "lyrics": ["La ___ es bella"],
    "blanks": ["vida"]
  }
}
```

### 18. `translationExercise`
Sentence translation with vocabulary hints.
```json
{
  "id": "ex_tr_adv_1",
  "type": "translationExercise",
  "question": "El gato bebe leche.",
  "options": [],
  "correctAnswer": "The cat drinks milk.",
  "metadata": {
    "hints": ["gato = cat", "leche = milk"]
  }
}
```
