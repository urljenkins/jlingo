#!/usr/bin/env python3
"""Generate all Dutch skill JSON files from English→Dutch translations."""
import json
import os

SKILLS_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'courses', 'dutch', 'skills')

def write_skill(data):
    path = os.path.join(SKILLS_DIR, f"{data['id']}.json")
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    print(f"  ✓ {data['id']}.json")

def main():
    os.makedirs(SKILLS_DIR, exist_ok=True)
    skills = []

    # ── 1. ALPHABET ──────────────────────────────────────────────
    skills.append({
        "id": "alphabet",
        "name": "Alphabet & Sounds",
        "description": "Learn the basics of Dutch pronunciation and vowels",
        "level": 1,
        "exercises": [
            {
                "id": "ex_alp_1",
                "type": "multipleChoice",
                "question": "Which Dutch vowel combination makes the 'ow' sound (like in 'house')?",
                "options": ["ui", "ij", "oe", "eu"],
                "correctAnswer": "ui"
            },
            {
                "id": "ex_alp_2",
                "type": "listeningComprehension",
                "question": "A",
                "options": [],
                "correctAnswer": "A"
            },
            {
                "id": "ex_alp_3",
                "type": "listeningComprehension",
                "question": "E",
                "options": [],
                "correctAnswer": "E"
            },
            {
                "id": "ex_alp_4",
                "type": "multipleChoice",
                "question": "How do you pronounce 'G' in Dutch?",
                "options": ["A guttural/throat sound", "Like English G", "Like English H", "Silent"],
                "correctAnswer": "A guttural/throat sound"
            },
            {
                "id": "ex_alp_5",
                "type": "translateThis",
                "question": "Het kind",
                "options": [],
                "correctAnswer": "The child"
            }
        ]
    })

    # ── 2. BASICS_1 ──────────────────────────────────────────────
    skills.append({
        "id": "basics_1",
        "name": "Basics 1",
        "description": "Learn basic greetings and introductions",
        "level": 1,
        "exercises": [
            {"id": "ex_1", "type": "translateThis", "question": "Hallo", "options": [], "correctAnswer": "Hello"},
            {"id": "ex_2", "type": "multipleChoice", "question": "What does 'Dank je' mean?", "options": ["Thank you", "Please", "Goodbye", "Hello"], "correctAnswer": "Thank you"},
            {"id": "ex_3", "type": "fillInBlank", "question": "Goedemorgen ___", "options": ["allemaal", "dag", "avond", "hallo"], "correctAnswer": "allemaal"},
            {"id": "ex_4", "type": "translateThis", "question": "Tot ziens", "options": [], "correctAnswer": "Goodbye"},
            {"id": "ex_5", "type": "multipleChoice", "question": "How do you say 'Good night' in Dutch?", "options": ["Goedenacht", "Goedemorgen", "Goedemiddag", "Hallo"], "correctAnswer": "Goedenacht"},
            {"id": "ex_6", "type": "matchPairs", "question": "Match the Dutch words with their English translations", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Hallo", "native": "Hello"}, {"target": "Dag", "native": "Goodbye"}, {"target": "Dank je", "native": "Thank you"}, {"target": "Alsjeblieft", "native": "Please"}]}},
            {"id": "ex_7", "type": "listeningComprehension", "question": "Goedemiddag", "options": [], "correctAnswer": "Goedemiddag"},
            {"id": "ex_8", "type": "speakThis", "question": "Hallo, hoe gaat het?", "options": [], "correctAnswer": "Hallo, hoe gaat het?"},
            {"id": "ex_b1_9", "type": "translateThis", "question": "Alsjeblieft", "options": [], "correctAnswer": "Please"},
            {"id": "ex_b1_10", "type": "multipleChoice", "question": "How do you say 'Excuse me' in Dutch?", "options": ["Pardon", "Hallo", "Dank je", "Tot ziens"], "correctAnswer": "Pardon"},
            {"id": "ex_b1_11", "type": "fillInBlank", "question": "Graag ___", "options": ["gedaan", "alles", "iets", "weinig"], "correctAnswer": "gedaan"},
            {"id": "ex_b1_12", "type": "listeningComprehension", "question": "Aangenaam kennis te maken", "options": [], "correctAnswer": "Aangenaam kennis te maken"}
        ]
    })

    # ── 3. GREETINGS_2 ──────────────────────────────────────────
    skills.append({
        "id": "greetings_2",
        "name": "Greetings 2",
        "description": "More common greetings and polite phrases",
        "level": 1,
        "exercises": [
            {"id": "ex_g2_1", "type": "translateThis", "question": "Aangenaam", "options": [], "correctAnswer": "Pleased to meet you"},
            {"id": "ex_g2_2", "type": "multipleChoice", "question": "What does 'Wat is er?' mean?", "options": ["What's up?", "How are you?", "Goodbye", "Please"], "correctAnswer": "What's up?"},
            {"id": "ex_g2_3", "type": "fillInBlank", "question": "Tot ___", "options": ["later", "hallo", "dag", "dank"], "correctAnswer": "later"},
            {"id": "ex_g2_4", "type": "matchPairs", "question": "Match the phrases", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Tot morgen", "native": "See you tomorrow"}, {"target": "Goedemiddag", "native": "Good afternoon"}, {"target": "Het spijt me", "native": "I'm sorry"}, {"target": "Pardon", "native": "Excuse me"}]}}
        ]
    })

    # ── 4. INTRODUCTIONS ────────────────────────────────────────
    skills.append({
        "id": "introductions",
        "name": "Introductions",
        "description": "Learn to introduce yourself and ask about others",
        "level": 1,
        "exercises": [
            {"id": "ex_intro_1", "type": "translateThis", "question": "Ik heet Maria", "options": [], "correctAnswer": "My name is Maria"},
            {"id": "ex_intro_2", "type": "multipleChoice", "question": "How do you ask 'What is your name?' formally?", "options": ["Hoe heet u?", "Hoe heet je?", "Hoe gaat het?", "Waar kom je vandaan?"], "correctAnswer": "Hoe heet u?"},
            {"id": "ex_intro_3", "type": "fillInBlank", "question": "Ik kom ___ Nederland", "options": ["uit", "in", "naar", "met"], "correctAnswer": "uit"},
            {"id": "ex_intro_4", "type": "matchPairs", "question": "Match the introductions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik heet", "native": "My name is"}, {"target": "Ik kom uit", "native": "I am from"}, {"target": "Aangenaam", "native": "Nice to meet you"}, {"target": "Leuk je te ontmoeten", "native": "Pleased to meet you"}]}},
            {"id": "ex_intro_5", "type": "speakThis", "question": "Aangenaam kennis te maken", "options": [], "correctAnswer": "Aangenaam kennis te maken"}
        ]
    })

    # ── 5. BASICS_2 ──────────────────────────────────────────────
    skills.append({
        "id": "basics_2",
        "name": "Basics 2",
        "description": "Learn basic phrases and common words",
        "level": 2,
        "exercises": [
            {"id": "ex_9", "type": "translateThis", "question": "Hoe gaat het?", "options": [], "correctAnswer": "How are you?"},
            {"id": "ex_10", "type": "multipleChoice", "question": "What does 'Ik' mean?", "options": ["I", "You", "He", "She"], "correctAnswer": "I"},
            {"id": "ex_11", "type": "fillInBlank", "question": "Ik ___ Jan", "options": ["heet", "ben", "heb", "ga"], "correctAnswer": "heet"},
            {"id": "ex_12", "type": "translateThis", "question": "Leuk je te ontmoeten", "options": [], "correctAnswer": "Nice to meet you"},
            {"id": "ex_13", "type": "multipleChoice", "question": "How do you say 'I am' in Dutch?", "options": ["Ik ben", "Jij bent", "Hij is", "Wij zijn"], "correctAnswer": "Ik ben"},
            {"id": "ex_14", "type": "matchPairs", "question": "Match the pronouns", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik", "native": "I"}, {"target": "Jij", "native": "You"}, {"target": "Hij", "native": "He"}, {"target": "Zij", "native": "She"}]}}
        ]
    })

    # ── 6. LISTENING_PRONUNCIATION ───────────────────────────────
    skills.append({
        "id": "listening_pronunciation",
        "name": "Listening & Pronunciation",
        "description": "Master Dutch sounds through listening exercises, pronunciation practice, dialogues, and songs",
        "level": 2,
        "exercises": [
            {"id": "lp_ex_1", "type": "nativeAudio", "question": "Goedemorgen, hoe gaat het met u?", "options": [], "correctAnswer": "Goedemorgen, hoe gaat het met u?", "targetLanguage": "nl-NL", "metadata": {"speaker": "Native Speaker - Marieke", "difficulty": "beginner"}},
            {"id": "lp_ex_2", "type": "pronunciationPractice", "question": "Ik heet Jan en ik kom uit Nederland", "options": [], "correctAnswer": "Ik heet Jan en ik kom uit Nederland", "targetLanguage": "nl-NL", "metadata": {"phonetics": "ik HAYT yahn en ik KOM owt NAY-der-lahnt", "focus": "The 'ij' diphthong and guttural 'g' sound"}},
            {"id": "lp_ex_3", "type": "dialogueListening", "question": "Listen to the conversation at a café", "options": ["He ordered coffee", "He ordered tea", "He ordered water", "He ordered juice"], "correctAnswer": "He ordered coffee", "targetLanguage": "nl-NL", "metadata": {"type": "dialogue", "context": "A customer ordering at a café in Amsterdam", "dialogue": [{"speaker": "Ober", "text": "Goedemorgen, wat mag het zijn?", "translation": "Good morning, what would you like?"}, {"speaker": "Klant", "text": "Goedemorgen. Een koffie met melk, alstublieft.", "translation": "Good morning. A coffee with milk, please."}, {"speaker": "Ober", "text": "Nog iets anders?", "translation": "Anything else?"}, {"speaker": "Klant", "text": "Nee, dank u. Hoeveel kost het?", "translation": "No, thank you. How much is it?"}, {"speaker": "Ober", "text": "Dat is twee euro vijftig.", "translation": "That's two euros fifty."}], "comprehensionQuestion": "What did the customer order?", "correctOptionIndex": 0}},
            {"id": "lp_ex_4", "type": "pronunciationPractice", "question": "Ik heb drieëndertig jaar", "options": [], "correctAnswer": "Ik heb drieëndertig jaar", "targetLanguage": "nl-NL", "metadata": {"phonetics": "ik HEP dree-en-DER-tikh yahr", "focus": "The guttural 'g' and 'r' sounds"}},
            {"id": "lp_ex_5", "type": "dialogueListening", "question": "Listen to the weather report", "options": ["Sunny weather expected", "Rain expected tomorrow", "Snow in the mountains", "Strong winds tonight"], "correctAnswer": "Rain expected tomorrow", "targetLanguage": "nl-NL", "metadata": {"type": "news", "context": "Weather forecast from Dutch television", "dialogue": [{"speaker": "Presentator", "text": "Goedemorgen. Hier is het weerbericht voor morgen.", "translation": "Good morning. Here is the weather forecast for tomorrow."}, {"speaker": "Presentator", "text": "Er wordt regen verwacht in het hele land.", "translation": "Rain is expected throughout the country."}, {"speaker": "Presentator", "text": "De temperaturen liggen tussen de 10 en 16 graden.", "translation": "Temperatures will range between 10 and 16 degrees."}, {"speaker": "Presentator", "text": "Het is aan te raden een paraplu mee te nemen.", "translation": "It is recommended to take an umbrella."}], "comprehensionQuestion": "What is the weather forecast for tomorrow?", "correctOptionIndex": 1}},
            {"id": "lp_ex_6", "type": "nativeAudio", "question": "Waar is het treinstation?", "options": [], "correctAnswer": "Waar is het treinstation?", "targetLanguage": "nl-NL", "metadata": {"speaker": "Native Speaker - Karel", "difficulty": "intermediate"}},
            {"id": "lp_ex_7", "type": "pronunciationPractice", "question": "De hond rent snel door het park", "options": [], "correctAnswer": "De hond rent snel door het park", "targetLanguage": "nl-NL", "metadata": {"phonetics": "duh HONT rent SNEL dohr het PARK", "focus": "The 'sch' cluster and rolled 'r'"}},
            {"id": "lp_ex_8", "type": "nativeAudio", "question": "Ik zou graag een tafel voor vier personen willen reserveren", "options": [], "correctAnswer": "Ik zou graag een tafel voor vier personen willen reserveren", "targetLanguage": "nl-NL", "metadata": {"speaker": "Native Speaker - Elena", "difficulty": "intermediate"}}
        ]
    })

    # ── 7. FAMILY_1 ──────────────────────────────────────────────
    skills.append({
        "id": "family_1",
        "name": "Family",
        "description": "Learn words for family members",
        "level": 2,
        "exercises": [
            {"id": "ex_fam_1", "type": "multipleChoice", "question": "How do you say 'Mother' in Dutch?", "options": ["Moeder", "Vader", "Broer", "Oma"], "correctAnswer": "Moeder"},
            {"id": "ex_fam_2", "type": "translateThis", "question": "Vader", "options": [], "correctAnswer": "Father"},
            {"id": "ex_fam_3", "type": "fillInBlank", "question": "Mijn ___ heet Maria", "options": ["zus", "broer", "moeder", "vader"], "correctAnswer": "zus"},
            {"id": "ex_fam_4", "type": "matchPairs", "question": "Match family members", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Zoon", "native": "Son"}, {"target": "Dochter", "native": "Daughter"}, {"target": "Opa", "native": "Grandfather"}, {"target": "Oma", "native": "Grandmother"}]}}
        ]
    })

    # ── 8. GRAMMAR_1 ─────────────────────────────────────────────
    skills.append({
        "id": "grammar_1",
        "name": "Grammar: Pronouns",
        "description": "Learn basic pronouns and the verb 'Zijn'",
        "level": 2,
        "exercises": [
            {"id": "ex_g1_1", "type": "multipleChoice", "question": "How do you say 'They' in Dutch?", "options": ["Zij", "Wij", "Jullie", "U"], "correctAnswer": "Zij"},
            {"id": "ex_g1_2", "type": "translateThis", "question": "Ik ben", "options": [], "correctAnswer": "I am"},
            {"id": "ex_g1_3", "type": "fillInBlank", "question": "Hij ___ een student", "options": ["is", "ben", "bent", "zijn"], "correctAnswer": "is"},
            {"id": "ex_g1_4", "type": "matchPairs", "question": "Match pronouns with Zijn (to be)", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik ben", "native": "I am"}, {"target": "Jij bent", "native": "You are"}, {"target": "Wij zijn", "native": "We are"}, {"target": "Zij zijn", "native": "They are"}]}}
        ]
    })

    # ── 9. GRAMMAR_ARTICLES ──────────────────────────────────────
    skills.append({
        "id": "grammar_articles",
        "name": "Grammar: Articles",
        "description": "Learn definite and indefinite articles in Dutch",
        "level": 2,
        "exercises": [
            {"id": "ex_art_1", "type": "multipleChoice", "question": "Which is the correct article for 'the book' (het-word)?", "options": ["Het boek", "De boek", "Een boek", "Die boek"], "correctAnswer": "Het boek"},
            {"id": "ex_art_2", "type": "fillInBlank", "question": "___ huis is groot", "options": ["Het", "De", "Een", "Die"], "correctAnswer": "Het"},
            {"id": "ex_art_3", "type": "matchPairs", "question": "Match the articles", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De", "native": "The (common gender)"}, {"target": "Het", "native": "The (neuter)"}, {"target": "Een", "native": "A/An"}]}},
            {"id": "ex_art_4", "type": "multipleChoice", "question": "How do you say 'a woman'?", "options": ["Een vrouw", "De vrouw", "Het vrouw", "Die vrouw"], "correctAnswer": "Een vrouw"},
            {"id": "ex_art_5", "type": "translateThis", "question": "Enkele boeken", "options": [], "correctAnswer": "Some books"}
        ]
    })

    # ── 10. NUMBERS ──────────────────────────────────────────────
    skills.append({
        "id": "numbers",
        "name": "Numbers",
        "description": "Learn numbers 1-10",
        "level": 3,
        "exercises": [
            {"id": "ex_15", "type": "translateThis", "question": "Een", "options": [], "correctAnswer": "One"},
            {"id": "ex_16", "type": "multipleChoice", "question": "What number is 'Vijf'?", "options": ["5", "3", "7", "9"], "correctAnswer": "5"},
            {"id": "ex_17", "type": "fillInBlank", "question": "Twee plus twee is ___", "options": ["vier", "drie", "vijf", "zes"], "correctAnswer": "vier"},
            {"id": "ex_18", "type": "matchPairs", "question": "Match the numbers", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Een", "native": "One"}, {"target": "Twee", "native": "Two"}, {"target": "Drie", "native": "Three"}, {"target": "Vier", "native": "Four"}]}},
            {"id": "ex_n_19", "type": "translateThis", "question": "Zeven", "options": [], "correctAnswer": "Seven"},
            {"id": "ex_n_20", "type": "multipleChoice", "question": "What number is 'Tien'?", "options": ["10", "8", "6", "2"], "correctAnswer": "10"},
            {"id": "ex_n_21", "type": "listeningComprehension", "question": "Acht", "options": [], "correctAnswer": "Acht"},
            {"id": "ex_n_22", "type": "speakThis", "question": "Negen", "options": [], "correctAnswer": "Negen"}
        ]
    })

    # ── 11. NUMBERS_2 ────────────────────────────────────────────
    skills.append({
        "id": "numbers_2",
        "name": "Numbers 2",
        "description": "Learn numbers 11-20",
        "level": 3,
        "exercises": [
            {"id": "ex_n2_1", "type": "translateThis", "question": "Elf", "options": [], "correctAnswer": "Eleven"},
            {"id": "ex_n2_2", "type": "multipleChoice", "question": "What is 'Vijftien'?", "options": ["15", "11", "5", "20"], "correctAnswer": "15"},
            {"id": "ex_n2_3", "type": "fillInBlank", "question": "Tien plus tien is ___", "options": ["twintig", "vijftien", "twaalf", "dertien"], "correctAnswer": "twintig"},
            {"id": "ex_n2_4", "type": "matchPairs", "question": "Match the numbers", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Twaalf", "native": "Twelve"}, {"target": "Dertien", "native": "Thirteen"}, {"target": "Veertien", "native": "Fourteen"}, {"target": "Twintig", "native": "Twenty"}]}}
        ]
    })

    # ── 12. ORDINAL_NUMBERS ──────────────────────────────────────
    skills.append({
        "id": "ordinal_numbers",
        "name": "Ordinal Numbers",
        "description": "Learn first, second, third and other ordinal numbers",
        "level": 3,
        "exercises": [
            {"id": "ex_ord_1", "type": "translateThis", "question": "Eerste", "options": [], "correctAnswer": "First"},
            {"id": "ex_ord_2", "type": "multipleChoice", "question": "How do you say 'second' in Dutch?", "options": ["Tweede", "Twee", "Derde", "Vierde"], "correctAnswer": "Tweede"},
            {"id": "ex_ord_3", "type": "matchPairs", "question": "Match the ordinal numbers", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Eerste", "native": "First"}, {"target": "Tweede", "native": "Second"}, {"target": "Derde", "native": "Third"}, {"target": "Vierde", "native": "Fourth"}, {"target": "Vijfde", "native": "Fifth"}]}},
            {"id": "ex_ord_4", "type": "fillInBlank", "question": "Het is mijn ___ dag op het werk", "options": ["eerste", "een", "ene", "eer"], "correctAnswer": "eerste"},
            {"id": "ex_ord_5", "type": "translateThis", "question": "De derde straat", "options": [], "correctAnswer": "The third street"}
        ]
    })

    # ── 13. COLORS ───────────────────────────────────────────────
    skills.append({
        "id": "colors",
        "name": "Colors",
        "description": "Learn the names of colors in Dutch",
        "level": 4,
        "exercises": [
            {"id": "ex_col_1", "type": "multipleChoice", "question": "How do you say 'red' in Dutch?", "options": ["Rood", "Blauw", "Groen", "Geel"], "correctAnswer": "Rood"},
            {"id": "ex_col_2", "type": "translateThis", "question": "Blauw", "options": [], "correctAnswer": "Blue"},
            {"id": "ex_col_3", "type": "matchPairs", "question": "Match the colors", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Rood", "native": "Red"}, {"target": "Blauw", "native": "Blue"}, {"target": "Groen", "native": "Green"}, {"target": "Geel", "native": "Yellow"}, {"target": "Zwart", "native": "Black"}, {"target": "Wit", "native": "White"}]}},
            {"id": "ex_col_4", "type": "fillInBlank", "question": "Het overhemd is ___", "options": ["blauw", "blauwe", "blauwen", "blauwt"], "correctAnswer": "blauw"},
            {"id": "ex_col_5", "type": "speakThis", "question": "De rode auto", "options": [], "correctAnswer": "De rode auto"}
        ]
    })

    # ── 14. DAYS_MONTHS ──────────────────────────────────────────
    skills.append({
        "id": "days_months",
        "name": "Days & Months",
        "description": "Learn days of the week and months of the year",
        "level": 4,
        "exercises": [
            {"id": "ex_dm_1", "type": "multipleChoice", "question": "How do you say 'Monday' in Dutch?", "options": ["Maandag", "Dinsdag", "Zondag", "Vrijdag"], "correctAnswer": "Maandag"},
            {"id": "ex_dm_2", "type": "matchPairs", "question": "Match the days of the week", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Maandag", "native": "Monday"}, {"target": "Dinsdag", "native": "Tuesday"}, {"target": "Woensdag", "native": "Wednesday"}, {"target": "Donderdag", "native": "Thursday"}, {"target": "Vrijdag", "native": "Friday"}, {"target": "Zaterdag", "native": "Saturday"}, {"target": "Zondag", "native": "Sunday"}]}},
            {"id": "ex_dm_3", "type": "translateThis", "question": "Januari", "options": [], "correctAnswer": "January"},
            {"id": "ex_dm_4", "type": "matchPairs", "question": "Match the months", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Januari", "native": "January"}, {"target": "Februari", "native": "February"}, {"target": "Maart", "native": "March"}, {"target": "April", "native": "April"}, {"target": "Mei", "native": "May"}, {"target": "Juni", "native": "June"}]}},
            {"id": "ex_dm_5", "type": "fillInBlank", "question": "Vandaag is ___ 15 maart", "options": ["het", "de", "een", "die"], "correctAnswer": "het"}
        ]
    })

    # ── 15. TIME ─────────────────────────────────────────────────
    skills.append({
        "id": "time",
        "name": "Telling Time",
        "description": "Learn to tell time and express duration",
        "level": 4,
        "exercises": [
            {"id": "ex_time_1", "type": "multipleChoice", "question": "How do you ask 'What time is it?'", "options": ["Hoe laat is het?", "Hoeveel tijd?", "Welke dag is het?", "Wanneer is het?"], "correctAnswer": "Hoe laat is het?"},
            {"id": "ex_time_2", "type": "translateThis", "question": "Het is drie uur", "options": [], "correctAnswer": "It's three o'clock"},
            {"id": "ex_time_3", "type": "fillInBlank", "question": "Het is ___ uur 's middags", "options": ["een", "één", "de", "het"], "correctAnswer": "een"},
            {"id": "ex_time_4", "type": "matchPairs", "question": "Match the time expressions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Half", "native": "Half past"}, {"target": "Kwart over", "native": "Quarter past"}, {"target": "Kwart voor", "native": "Quarter to"}, {"target": "Precies", "native": "Exactly/On the dot"}]}},
            {"id": "ex_time_5", "type": "multipleChoice", "question": "How do you say '8:30' in Dutch?", "options": ["Half negen", "Acht en half", "Half acht", "Acht dertig"], "correctAnswer": "Half negen"}
        ]
    })

    # ── 16. FOOD ─────────────────────────────────────────────────
    skills.append({
        "id": "food",
        "name": "Food",
        "description": "Learn common food items",
        "level": 5,
        "exercises": [
            {"id": "ex_f_1", "type": "multipleChoice", "question": "How do you say 'Bread' in Dutch?", "options": ["Brood", "Melk", "Water", "Appel"], "correctAnswer": "Brood"},
            {"id": "ex_f_2", "type": "translateThis", "question": "Appel", "options": [], "correctAnswer": "Apple"},
            {"id": "ex_f_3", "type": "fillInBlank", "question": "Ik wil een ___ water", "options": ["fles", "eten", "tafel", "huis"], "correctAnswer": "fles"},
            {"id": "ex_f_4", "type": "matchPairs", "question": "Match food items", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Melk", "native": "Milk"}, {"target": "Water", "native": "Water"}, {"target": "Kaas", "native": "Cheese"}, {"target": "Ei", "native": "Egg"}]}},
            {"id": "ex_f_5", "type": "speakThis", "question": "Ik eet brood", "options": [], "correctAnswer": "Ik eet brood"}
        ]
    })

    # ── 17. DRINKS ───────────────────────────────────────────────
    skills.append({
        "id": "drinks",
        "name": "Drinks",
        "description": "Learn vocabulary for beverages",
        "level": 5,
        "exercises": [
            {"id": "ex_dr_1", "type": "multipleChoice", "question": "How do you say 'water' in Dutch?", "options": ["Water", "Melk", "Koffie", "Sap"], "correctAnswer": "Water"},
            {"id": "ex_dr_2", "type": "matchPairs", "question": "Match the drinks", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Water", "native": "Water"}, {"target": "Melk", "native": "Milk"}, {"target": "Koffie", "native": "Coffee"}, {"target": "Thee", "native": "Tea"}, {"target": "Sap", "native": "Juice"}, {"target": "Bier", "native": "Beer"}]}},
            {"id": "ex_dr_3", "type": "translateThis", "question": "Een glas rode wijn", "options": [], "correctAnswer": "A glass of red wine"},
            {"id": "ex_dr_4", "type": "fillInBlank", "question": "Ik wil een ___ sinaasappelsap", "options": ["glas", "water", "melk", "koffie"], "correctAnswer": "glas"},
            {"id": "ex_dr_5", "type": "speakThis", "question": "Een koffie met melk, alstublieft", "options": [], "correctAnswer": "Een koffie met melk, alstublieft"}
        ]
    })

    # ── 18. ANIMALS ──────────────────────────────────────────────
    skills.append({
        "id": "animals",
        "name": "Animals",
        "description": "Learn common animal names",
        "level": 5,
        "exercises": [
            {"id": "ex_an_1", "type": "multipleChoice", "question": "How do you say 'dog' in Dutch?", "options": ["Hond", "Kat", "Vogel", "Vis"], "correctAnswer": "Hond"},
            {"id": "ex_an_2", "type": "matchPairs", "question": "Match the animals", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Hond", "native": "Dog"}, {"target": "Kat", "native": "Cat"}, {"target": "Vogel", "native": "Bird"}, {"target": "Vis", "native": "Fish"}, {"target": "Paard", "native": "Horse"}, {"target": "Koe", "native": "Cow"}]}},
            {"id": "ex_an_3", "type": "translateThis", "question": "De olifant is groot", "options": [], "correctAnswer": "The elephant is big"},
            {"id": "ex_an_4", "type": "fillInBlank", "question": "De ___ vliegt", "options": ["vogel", "hond", "vis", "kat"], "correctAnswer": "vogel"},
            {"id": "ex_an_5", "type": "multipleChoice", "question": "Which animal says 'miauw' in Dutch?", "options": ["Kat", "Hond", "Koe", "Paard"], "correctAnswer": "Kat"}
        ]
    })

    # ── 19. READING_WRITING ──────────────────────────────────────
    skills.append({
        "id": "reading_writing",
        "name": "Reading & Writing",
        "description": "Practice reading comprehension through dialogues, stories, and fill-in-the-blank exercises",
        "level": 5,
        "exercises": [
            {"id": "rw_dialogue_1", "type": "interactiveDialogue", "question": "Practice a conversation at a café", "options": ["Goed, dank je", "Tot ziens", "Ik begrijp het niet"], "correctAnswer": "Goed, dank je", "targetLanguage": "nl-NL", "nativeLanguage": "en-US", "metadata": {"topic": "At the Café", "dialogue": [{"speaker": "A", "text": "Hallo! Hoe gaat het?", "isNative": True}, {"speaker": "B", "text": "___", "isUserTurn": True, "options": ["Goed, dank je", "Tot ziens", "Ik begrijp het niet"]}, {"speaker": "A", "text": "Fijn! Wil je een koffie?", "isNative": True}]}},
            {"id": "rw_story_1", "type": "storyLesson", "question": "Wat zag Maria in het park?", "options": ["Een zwarte kat", "Een grote hond", "Een blauwe vogel", "Een vlinder"], "correctAnswer": "Een zwarte kat", "targetLanguage": "nl-NL", "nativeLanguage": "en-US", "metadata": {"title": "De Kat in het Park", "level": "A1", "story": "Maria liep door het park op een zonnige dag. De vogels zongen in de bomen en de wind was zacht. Opeens zag ze een zwarte kat op een bankje zitten. De kat had hele groene ogen. Maria kwam langzaam dichterbij en de kat begon te spinnen. Vanaf die dag bezoekt Maria het park elke dag om haar nieuwe vriend te zien.", "vocabulary": [{"word": "liep", "translation": "was walking", "highlight": True}, {"word": "zonnig", "translation": "sunny", "highlight": True}, {"word": "kat", "translation": "cat", "highlight": True}, {"word": "ogen", "translation": "eyes", "highlight": True}, {"word": "spinnen", "translation": "to purr", "highlight": True}], "question": "Wat zag Maria in het park?"}},
            {"id": "rw_translation_1", "type": "translationExercise", "question": "Ik lees heel graag boeken in het Nederlands.", "options": [], "correctAnswer": "I really like to read books in Dutch.", "targetLanguage": "nl-NL", "nativeLanguage": "en-US", "metadata": {"direction": "toNative", "sourceText": "Ik lees heel graag boeken in het Nederlands.", "hints": ["'Ik lees graag' means 'I like to read'", "'heel' emphasizes 'very' or 'really'"], "acceptableAnswers": ["I like reading books in Dutch a lot", "I really enjoy reading books in Dutch"], "difficulty": "sentence"}},
            {"id": "rw_translation_2", "type": "translationExercise", "question": "The weather is beautiful today.", "options": [], "correctAnswer": "Het weer is mooi vandaag.", "targetLanguage": "nl-NL", "nativeLanguage": "en-US", "metadata": {"direction": "toTarget", "sourceText": "The weather is beautiful today.", "hints": ["'weather' = 'weer'", "'beautiful' = 'mooi' or 'prachtig'"], "acceptableAnswers": ["Het is mooi weer vandaag", "Vandaag is het weer mooi"], "difficulty": "sentence"}},
            {"id": "rw_cloze_1", "type": "clozeTest", "question": "De ___ is een dier dat ___ in het water.", "options": ["vis", "leeft", "rent", "hond"], "correctAnswer": "vis,leeft", "targetLanguage": "nl-NL", "nativeLanguage": "en-US", "metadata": {"blanks": [{"index": 0, "answer": "vis", "options": ["vis", "hond", "kat"]}, {"index": 1, "answer": "leeft", "options": ["leeft", "rent", "slaapt"]}], "context": "Complete the sentence about animals and where they live."}},
            {"id": "rw_cloze_2", "type": "clozeTest", "question": "Mijn zus ___ muziek terwijl ze haar ___ maakt.", "options": ["luistert", "huiswerk", "eet", "slaapt"], "correctAnswer": "luistert,huiswerk", "targetLanguage": "nl-NL", "nativeLanguage": "en-US", "metadata": {"blanks": [{"index": 0, "answer": "luistert", "options": ["luistert", "eet", "slaapt"]}, {"index": 1, "answer": "huiswerk", "options": ["huiswerk", "film", "boek"]}], "context": "Complete the sentence about daily activities."}}
        ]
    })

    # ── 20. CLOTHING ─────────────────────────────────────────────
    skills.append({
        "id": "clothing",
        "name": "Clothing",
        "description": "Learn vocabulary for clothes and accessories",
        "level": 6,
        "exercises": [
            {"id": "ex_cl_1", "type": "multipleChoice", "question": "How do you say 'shirt' in Dutch?", "options": ["Overhemd", "Broek", "Schoen", "Hoed"], "correctAnswer": "Overhemd"},
            {"id": "ex_cl_2", "type": "matchPairs", "question": "Match the clothing items", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Overhemd", "native": "Shirt"}, {"target": "Broek", "native": "Pants"}, {"target": "Schoenen", "native": "Shoes"}, {"target": "Jurk", "native": "Dress"}, {"target": "Rok", "native": "Skirt"}, {"target": "Jas", "native": "Jacket"}]}},
            {"id": "ex_cl_3", "type": "translateThis", "question": "De zwarte schoenen", "options": [], "correctAnswer": "The black shoes"},
            {"id": "ex_cl_4", "type": "fillInBlank", "question": "Zij draagt een blauwe ___", "options": ["rok", "broek", "schoen", "hoed"], "correctAnswer": "rok"},
            {"id": "ex_cl_5", "type": "speakThis", "question": "Ik vind je overhemd mooi", "options": [], "correctAnswer": "Ik vind je overhemd mooi"}
        ]
    })

    # ── 21. WEATHER ──────────────────────────────────────────────
    skills.append({
        "id": "weather",
        "name": "Weather",
        "description": "Learn to talk about weather and climate",
        "level": 6,
        "exercises": [
            {"id": "ex_we_1", "type": "multipleChoice", "question": "How do you ask 'What's the weather like?'", "options": ["Wat voor weer is het?", "Hoe laat is het?", "Hoe gaat het?", "Waar is het?"], "correctAnswer": "Wat voor weer is het?"},
            {"id": "ex_we_2", "type": "matchPairs", "question": "Match the weather expressions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Het is warm", "native": "It's hot"}, {"target": "Het is koud", "native": "It's cold"}, {"target": "De zon schijnt", "native": "It's sunny"}, {"target": "Het regent", "native": "It's raining"}, {"target": "Het sneeuwt", "native": "It's snowing"}, {"target": "Het is bewolkt", "native": "It's cloudy"}]}},
            {"id": "ex_we_3", "type": "translateThis", "question": "Het is mooi weer vandaag", "options": [], "correctAnswer": "The weather is nice today"},
            {"id": "ex_we_4", "type": "fillInBlank", "question": "Vandaag ___ het hard", "options": ["waait", "is", "zijn", "heeft"], "correctAnswer": "waait"},
            {"id": "ex_we_5", "type": "speakThis", "question": "Morgen gaat het regenen", "options": [], "correctAnswer": "Morgen gaat het regenen"}
        ]
    })

    # ── 22. ADJECTIVES_1 ─────────────────────────────────────────
    skills.append({
        "id": "adjectives_1",
        "name": "Common Adjectives",
        "description": "Learn basic adjectives to describe things",
        "level": 6,
        "exercises": [
            {"id": "ex_adj_1", "type": "matchPairs", "question": "Match the adjectives", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Groot", "native": "Big"}, {"target": "Klein", "native": "Small"}, {"target": "Goed", "native": "Good"}, {"target": "Slecht", "native": "Bad"}, {"target": "Warm", "native": "Hot"}, {"target": "Koud", "native": "Cold"}]}},
            {"id": "ex_adj_2", "type": "translateThis", "question": "Het grote huis", "options": [], "correctAnswer": "The big house"},
            {"id": "ex_adj_3", "type": "fillInBlank", "question": "De koffie is erg ___", "options": ["warm", "groot", "klein", "goed"], "correctAnswer": "warm"},
            {"id": "ex_adj_4", "type": "multipleChoice", "question": "What is the opposite of 'lang' (tall)?", "options": ["Kort", "Groot", "Klein", "Dik"], "correctAnswer": "Kort"},
            {"id": "ex_adj_5", "type": "matchPairs", "question": "Match more adjectives", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Nieuw", "native": "New"}, {"target": "Oud", "native": "Old"}, {"target": "Mooi", "native": "Pretty"}, {"target": "Lelijk", "native": "Ugly"}, {"target": "Makkelijk", "native": "Easy"}, {"target": "Moeilijk", "native": "Difficult"}]}}
        ]
    })

    # ── 23. GRAMMAR_SER_ESTAR (Core Verbs: zijn/hebben) ──────────
    skills.append({
        "id": "grammar_ser_estar",
        "name": "Grammar: Core Verbs",
        "description": "Learn the Dutch verbs 'zijn' (to be) and 'hebben' (to have)",
        "level": 7,
        "exercises": [
            {"id": "ex_se_1", "type": "multipleChoice", "question": "What is the Dutch verb for 'to be'?", "options": ["Zijn", "Hebben", "Worden", "Gaan"], "correctAnswer": "Zijn"},
            {"id": "ex_se_2", "type": "fillInBlank", "question": "Ik ___ Nederlander", "options": ["ben", "heb", "word", "ga"], "correctAnswer": "ben"},
            {"id": "ex_se_3", "type": "fillInBlank", "question": "Maria ___ moe", "options": ["is", "ben", "bent", "zijn"], "correctAnswer": "is"},
            {"id": "ex_se_4", "type": "matchPairs", "question": "Match ZIJN conjugations", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik ben", "native": "I am"}, {"target": "Jij bent", "native": "You are"}, {"target": "Hij/Zij is", "native": "He/She is"}, {"target": "Wij zijn", "native": "We are"}, {"target": "Zij zijn", "native": "They are"}]}},
            {"id": "ex_se_5", "type": "multipleChoice", "question": "Het feest ___ in mijn huis", "options": ["is", "ben", "zijn", "bent"], "correctAnswer": "is"},
            {"id": "ex_se_6", "type": "translateThis", "question": "Ik ben op kantoor", "options": [], "correctAnswer": "I am at the office"}
        ]
    })

    # ── 24. GRAMMAR_TENER (Have/Own: hebben) ─────────────────────
    skills.append({
        "id": "grammar_tener",
        "name": "Grammar: Have/Own",
        "description": "Learn the verb hebben and its expressions",
        "level": 7,
        "exercises": [
            {"id": "ex_ten_1", "type": "matchPairs", "question": "Match HEBBEN conjugations", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik heb", "native": "I have"}, {"target": "Jij hebt", "native": "You have"}, {"target": "Hij/Zij heeft", "native": "He/She has"}, {"target": "Wij hebben", "native": "We have"}, {"target": "Zij hebben", "native": "They have"}]}},
            {"id": "ex_ten_2", "type": "translateThis", "question": "Ik heb twee broers", "options": [], "correctAnswer": "I have two brothers"},
            {"id": "ex_ten_3", "type": "fillInBlank", "question": "Zij ___ honger", "options": ["heeft", "heb", "hebt", "hebben"], "correctAnswer": "heeft"},
            {"id": "ex_ten_4", "type": "matchPairs", "question": "Match HEBBEN expressions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Honger hebben", "native": "To be hungry"}, {"target": "Dorst hebben", "native": "To be thirsty"}, {"target": "Het koud hebben", "native": "To be cold"}, {"target": "Het warm hebben", "native": "To be hot"}, {"target": "Slaap hebben", "native": "To be sleepy"}]}},
            {"id": "ex_ten_5", "type": "multipleChoice", "question": "How do you say 'I am 25 years old'?", "options": ["Ik ben 25 jaar oud", "Ik heb 25 jaar", "Ik ben 25 jaren", "Ik heb 25 oud"], "correctAnswer": "Ik ben 25 jaar oud"}
        ]
    })

    # ── 25. PRESENT_TENSE ────────────────────────────────────────
    skills.append({
        "id": "present_tense",
        "name": "Present Tense",
        "description": "Learn regular verb conjugations in the present tense",
        "level": 7,
        "exercises": [
            {"id": "ex_pt_1", "type": "multipleChoice", "question": "How do you form the present tense in Dutch?", "options": ["Verb stem + endings (-t, -en)", "Add -ing to the verb", "Use 'zijn' + infinitive", "No changes needed"], "correctAnswer": "Verb stem + endings (-t, -en)"},
            {"id": "ex_pt_2", "type": "matchPairs", "question": "Match WERKEN (to work) conjugations", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik werk", "native": "I work"}, {"target": "Jij werkt", "native": "You work"}, {"target": "Hij werkt", "native": "He works"}, {"target": "Wij werken", "native": "We work"}, {"target": "Zij werken", "native": "They work"}]}},
            {"id": "ex_pt_3", "type": "fillInBlank", "question": "Zij ___ goed Nederlands", "options": ["spreekt", "spreek", "spreeken", "spreken"], "correctAnswer": "spreekt"},
            {"id": "ex_pt_4", "type": "translateThis", "question": "Wij eten thuis", "options": [], "correctAnswer": "We eat at home"},
            {"id": "ex_pt_5", "type": "fillInBlank", "question": "De kinderen ___ in het park", "options": ["wonen", "woont", "woon", "woonen"], "correctAnswer": "wonen"}
        ]
    })

    # ── 26. DAILY_ROUTINE ────────────────────────────────────────
    skills.append({
        "id": "daily_routine",
        "name": "Daily Routine",
        "description": "Learn to talk about your daily activities",
        "level": 8,
        "exercises": [
            {"id": "ex_dr_1", "type": "multipleChoice", "question": "How do you say 'I wake up' in Dutch?", "options": ["Ik word wakker", "Ik wakker", "Hij wordt wakker", "Jij wordt wakker"], "correctAnswer": "Ik word wakker"},
            {"id": "ex_dr_2", "type": "translateThis", "question": "Ik douche 's ochtends", "options": [], "correctAnswer": "I shower in the morning"},
            {"id": "ex_dr_3", "type": "fillInBlank", "question": "Zij ___ om acht uur op", "options": ["staat", "sta", "staan", "staat"], "correctAnswer": "staat"},
            {"id": "ex_dr_4", "type": "matchPairs", "question": "Match the routine verbs", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Naar bed gaan", "native": "To go to bed"}, {"target": "Slapen", "native": "To sleep"}, {"target": "Eten", "native": "To eat"}, {"target": "Werken", "native": "To work"}]}}
        ]
    })

    # ── 27. REFLEXIVE_VERBS ──────────────────────────────────────
    skills.append({
        "id": "reflexive_verbs",
        "name": "Reflexive Verbs",
        "description": "Learn verbs that reflect back to the subject",
        "level": 8,
        "exercises": [
            {"id": "ex_rv_1", "type": "multipleChoice", "question": "Which pronoun goes with 'ik' for reflexive verbs?", "options": ["me", "je", "zich", "ons"], "correctAnswer": "me"},
            {"id": "ex_rv_2", "type": "matchPairs", "question": "Match reflexive pronouns", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Me", "native": "Myself (ik)"}, {"target": "Je", "native": "Yourself (jij)"}, {"target": "Zich", "native": "Himself/Herself"}, {"target": "Ons", "native": "Ourselves"}, {"target": "Zich", "native": "Themselves"}]}},
            {"id": "ex_rv_3", "type": "translateThis", "question": "Ik was mijn handen", "options": [], "correctAnswer": "I wash my hands"},
            {"id": "ex_rv_4", "type": "fillInBlank", "question": "Zij kamt ___ haar", "options": ["haar", "mijn", "je", "ons"], "correctAnswer": "haar"},
            {"id": "ex_rv_5", "type": "matchPairs", "question": "Match common reflexive verbs", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Zich aankleden", "native": "To get dressed"}, {"target": "Zich douchen", "native": "To shower"}, {"target": "Zich scheren", "native": "To shave"}, {"target": "Zich vergissen", "native": "To make a mistake"}, {"target": "Zich voelen", "native": "To feel"}]}}
        ]
    })

    # ── 28. GETTING_AROUND ───────────────────────────────────────
    skills.append({
        "id": "getting_around",
        "name": "Getting Around",
        "description": "Learn to ask for directions and use transportation",
        "level": 9,
        "exercises": [
            {"id": "ex_ga_1", "type": "multipleChoice", "question": "How do you say 'Turn left' in Dutch?", "options": ["Sla linksaf", "Sla rechtsaf", "Ga rechtdoor", "Stop hier"], "correctAnswer": "Sla linksaf"},
            {"id": "ex_ga_2", "type": "translateThis", "question": "Waar is het treinstation?", "options": [], "correctAnswer": "Where is the train station?"},
            {"id": "ex_ga_3", "type": "fillInBlank", "question": "Ik ga naar het vliegveld met de ___", "options": ["taxi", "huis", "restaurant", "park"], "correctAnswer": "taxi"},
            {"id": "ex_ga_4", "type": "matchPairs", "question": "Match transportation", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Bus", "native": "Bus"}, {"target": "Metro", "native": "Subway"}, {"target": "Fiets", "native": "Bicycle"}, {"target": "Auto", "native": "Car"}]}}
        ]
    })

    # ── 29. DIRECTIONS ───────────────────────────────────────────
    skills.append({
        "id": "directions",
        "name": "Directions",
        "description": "Learn to ask for and give directions",
        "level": 9,
        "exercises": [
            {"id": "ex_dir_1", "type": "multipleChoice", "question": "How do you ask 'Where is the bank?'", "options": ["Waar is de bank?", "Wat is de bank?", "Hoe is de bank?", "Welke is de bank?"], "correctAnswer": "Waar is de bank?"},
            {"id": "ex_dir_2", "type": "matchPairs", "question": "Match direction words", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Naar rechts", "native": "To the right"}, {"target": "Naar links", "native": "To the left"}, {"target": "Rechtdoor", "native": "Straight ahead"}, {"target": "Op de hoek", "native": "On the corner"}, {"target": "Naast", "native": "Next to"}]}},
            {"id": "ex_dir_3", "type": "translateThis", "question": "Sla rechtsaf", "options": [], "correctAnswer": "Turn right"},
            {"id": "ex_dir_4", "type": "fillInBlank", "question": "Het museum is ___ het park", "options": ["dichtbij", "ver van", "binnen", "buiten"], "correctAnswer": "dichtbij"},
            {"id": "ex_dir_5", "type": "speakThis", "question": "Ga rechtdoor en sla dan linksaf", "options": [], "correctAnswer": "Ga rechtdoor en sla dan linksaf"}
        ]
    })

    # ── 30. TRANSPORTATION ───────────────────────────────────────
    skills.append({
        "id": "transportation",
        "name": "Transportation",
        "description": "Learn vocabulary for getting around",
        "level": 9,
        "exercises": [
            {"id": "ex_tr_1", "type": "matchPairs", "question": "Match transportation words", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De bus", "native": "The bus"}, {"target": "De trein", "native": "The train"}, {"target": "Het vliegtuig", "native": "The airplane"}, {"target": "De taxi", "native": "The taxi"}, {"target": "De metro", "native": "The subway"}, {"target": "De auto", "native": "The car"}]}},
            {"id": "ex_tr_2", "type": "translateThis", "question": "Een retourkaartje", "options": [], "correctAnswer": "A round-trip ticket"},
            {"id": "ex_tr_3", "type": "fillInBlank", "question": "Hoe laat ___ de trein?", "options": ["vertrekt", "aankomt", "komt", "gaat"], "correctAnswer": "vertrekt"},
            {"id": "ex_tr_4", "type": "multipleChoice", "question": "How do you say 'platform' (at a train station)?", "options": ["Perron", "Station", "Halte", "Kaartje"], "correctAnswer": "Perron"},
            {"id": "ex_tr_5", "type": "speakThis", "question": "Ik wil een kaartje naar Amsterdam", "options": [], "correctAnswer": "Ik wil een kaartje naar Amsterdam"}
        ]
    })

    # ── 31-67: Remaining skills ──────────────────────────────────
    remaining = [
        {"id": "shopping", "name": "Shopping", "desc": "Learn vocabulary for shopping and buying things", "level": 10, "section": "intermediate", "exercises": [
            {"id": "ex_sh_1", "type": "multipleChoice", "question": "How do you ask 'How much does it cost?'", "options": ["Hoeveel kost het?", "Wat is de prijs?", "Hoe kost het?", "Waar kost het?"], "correctAnswer": "Hoeveel kost het?"},
            {"id": "ex_sh_2", "type": "matchPairs", "question": "Match shopping vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De winkel", "native": "The store"}, {"target": "De prijs", "native": "The price"}, {"target": "De aanbieding", "native": "The sale/offer"}, {"target": "De korting", "native": "The discount"}, {"target": "De kassa", "native": "The cash register"}, {"target": "Het wisselgeld", "native": "The change"}]}},
            {"id": "ex_sh_3", "type": "translateThis", "question": "Heeft u dit in een andere maat?", "options": [], "correctAnswer": "Do you have this in another size?"},
            {"id": "ex_sh_4", "type": "fillInBlank", "question": "Ik wil deze jurk ___", "options": ["kopen", "verkopen", "betalen", "sluiten"], "correctAnswer": "kopen"},
            {"id": "ex_sh_5", "type": "speakThis", "question": "Kan ik met pinpas betalen?", "options": [], "correctAnswer": "Kan ik met pinpas betalen?"}
        ]},
        {"id": "at_the_market", "name": "At the Market", "desc": "Learn vocabulary for the supermarket and local markets", "level": 10, "section": "intermediate", "exercises": [
            {"id": "ex_mk_1", "type": "matchPairs", "question": "Match market vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De supermarkt", "native": "The supermarket"}, {"target": "De markt", "native": "The market"}, {"target": "De slager", "native": "The butcher shop"}, {"target": "De bakker", "native": "The bakery"}, {"target": "De groenteboer", "native": "The greengrocer"}, {"target": "De viswinkel", "native": "The fish shop"}]}},
            {"id": "ex_mk_2", "type": "translateThis", "question": "Een halve kilo appels, alstublieft", "options": [], "correctAnswer": "Half a kilo of apples, please"},
            {"id": "ex_mk_3", "type": "fillInBlank", "question": "Mag ik een ___ brood?", "options": ["stuk", "glas", "kopje", "bord"], "correctAnswer": "stuk"},
            {"id": "ex_mk_4", "type": "multipleChoice", "question": "How do you say 'Is it fresh?'", "options": ["Is het vers?", "Is het nieuw?", "Is het goed?", "Is het lekker?"], "correctAnswer": "Is het vers?"},
            {"id": "ex_mk_5", "type": "speakThis", "question": "Ik wil twee kilo sinaasappels", "options": [], "correctAnswer": "Ik wil twee kilo sinaasappels"}
        ]},
        {"id": "services", "name": "Services", "desc": "Learn vocabulary for banks, post offices, and other services", "level": 10, "section": "intermediate", "exercises": [
            {"id": "ex_sv_1", "type": "matchPairs", "question": "Match service locations", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De bank", "native": "The bank"}, {"target": "Het postkantoor", "native": "The post office"}, {"target": "De apotheek", "native": "The pharmacy"}, {"target": "Het politiebureau", "native": "The police station"}, {"target": "Het ziekenhuis", "native": "The hospital"}, {"target": "Het tankstation", "native": "The gas station"}]}},
            {"id": "ex_sv_2", "type": "translateThis", "question": "Ik wil een pakket versturen", "options": [], "correctAnswer": "I want to send a package"},
            {"id": "ex_sv_3", "type": "fillInBlank", "question": "Ik moet geld ___", "options": ["opnemen", "stoppen", "geven", "hebben"], "correctAnswer": "opnemen"},
            {"id": "ex_sv_4", "type": "multipleChoice", "question": "How do you say 'stamp' (for mail)?", "options": ["Postzegel", "Brief", "Envelop", "Pakket"], "correctAnswer": "Postzegel"},
            {"id": "ex_sv_5", "type": "speakThis", "question": "Waar kan ik geld wisselen?", "options": [], "correctAnswer": "Waar kan ik geld wisselen?"}
        ]},
        {"id": "restaurant", "name": "At the Restaurant", "desc": "Learn vocabulary for dining out", "level": 11, "section": "intermediate", "exercises": [
            {"id": "ex_rest_1", "type": "matchPairs", "question": "Match restaurant vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De tafel", "native": "The table"}, {"target": "Het menu", "native": "The menu"}, {"target": "De ober", "native": "The waiter"}, {"target": "De rekening", "native": "The bill"}, {"target": "De fooi", "native": "The tip"}, {"target": "De reservering", "native": "The reservation"}]}},
            {"id": "ex_rest_2", "type": "translateThis", "question": "Een tafel voor twee, alstublieft", "options": [], "correctAnswer": "A table for two, please"},
            {"id": "ex_rest_3", "type": "fillInBlank", "question": "Mag ik het ___, alstublieft?", "options": ["menu", "tafel", "rekening", "glas"], "correctAnswer": "menu"},
            {"id": "ex_rest_4", "type": "multipleChoice", "question": "How do you ask for the bill?", "options": ["De rekening, alstublieft", "Het menu, alstublieft", "De tafel, alstublieft", "Het bord, alstublieft"], "correctAnswer": "De rekening, alstublieft"},
            {"id": "ex_rest_5", "type": "speakThis", "question": "Ik zou graag een reservering willen maken voor vanavond", "options": [], "correctAnswer": "Ik zou graag een reservering willen maken voor vanavond"}
        ]},
        {"id": "ordering_food", "name": "Ordering Food", "desc": "Learn to order food and express dietary needs", "level": 11, "section": "intermediate", "exercises": [
            {"id": "ex_of_1", "type": "multipleChoice", "question": "How do you say 'I would like...'?", "options": ["Ik zou graag...", "Ik wil...", "Ik heb...", "Ik kan..."], "correctAnswer": "Ik zou graag..."},
            {"id": "ex_of_2", "type": "matchPairs", "question": "Match menu sections", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Voorgerecht", "native": "Starters"}, {"target": "Hoofdgerecht", "native": "Main course"}, {"target": "Nagerecht", "native": "Dessert"}, {"target": "Dranken", "native": "Drinks"}, {"target": "Bijgerecht", "native": "Side dish"}]}},
            {"id": "ex_of_3", "type": "translateThis", "question": "Ik ben vegetariër", "options": [], "correctAnswer": "I am vegetarian"},
            {"id": "ex_of_4", "type": "fillInBlank", "question": "Ik ben allergisch voor ___", "options": ["noten", "keuken", "menu", "borden"], "correctAnswer": "noten"},
            {"id": "ex_of_5", "type": "speakThis", "question": "Voor mij de kip met rijst", "options": [], "correctAnswer": "Voor mij de kip met rijst"}
        ]},
        {"id": "present_continuous", "name": "Present Continuous", "desc": "Learn to express ongoing actions (aan het + infinitive)", "level": 12, "section": "intermediate", "exercises": [
            {"id": "ex_pc_1", "type": "multipleChoice", "question": "How do you form the present continuous in Dutch?", "options": ["zijn + aan het + infinitive", "zijn + infinitive", "hebben + voltooid deelwoord", "gaan + infinitive"], "correctAnswer": "zijn + aan het + infinitive"},
            {"id": "ex_pc_2", "type": "matchPairs", "question": "Match the continuous forms", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Aan het praten", "native": "Speaking"}, {"target": "Aan het eten", "native": "Eating"}, {"target": "Aan het leven", "native": "Living"}, {"target": "Aan het doen", "native": "Doing"}, {"target": "Aan het lezen", "native": "Reading"}]}},
            {"id": "ex_pc_3", "type": "translateThis", "question": "Ik ben Nederlands aan het studeren", "options": [], "correctAnswer": "I am studying Dutch"},
            {"id": "ex_pc_4", "type": "fillInBlank", "question": "Zij is een boek aan het ___", "options": ["lezen", "leest", "las", "gelezen"], "correctAnswer": "lezen"},
            {"id": "ex_pc_5", "type": "speakThis", "question": "Wat ben je aan het doen?", "options": [], "correctAnswer": "Wat ben je aan het doen?"}
        ]},
        {"id": "past_tense_1", "name": "Past Tense: Simple Past", "desc": "Learn the simple past tense for completed actions", "level": 12, "section": "intermediate", "exercises": [
            {"id": "ex_pret_1", "type": "multipleChoice", "question": "When do we use the simple past (onvoltooid verleden tijd)?", "options": ["For completed actions in the past", "For ongoing past actions", "For future plans", "For habitual actions"], "correctAnswer": "For completed actions in the past"},
            {"id": "ex_pret_2", "type": "matchPairs", "question": "Match WERKEN simple past conjugations", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik werkte", "native": "I worked"}, {"target": "Jij werkte", "native": "You worked"}, {"target": "Hij werkte", "native": "He worked"}, {"target": "Wij werkten", "native": "We worked"}, {"target": "Zij werkten", "native": "They worked"}]}},
            {"id": "ex_pret_3", "type": "translateThis", "question": "Gisteren at ik in een restaurant", "options": [], "correctAnswer": "Yesterday I ate at a restaurant"},
            {"id": "ex_pret_4", "type": "fillInBlank", "question": "Zij ___ vorig jaar naar Nederland", "options": ["reisde", "reist", "reizen", "zal reizen"], "correctAnswer": "reisde"},
            {"id": "ex_pret_5", "type": "multipleChoice", "question": "What is the simple past of 'gaan' (to go) for 'ik'?", "options": ["Ging", "Ga", "Gegaan", "Zal gaan"], "correctAnswer": "Ging"}
        ]},
        {"id": "past_tense_2", "name": "Past Tense: Imperfect", "desc": "Learn the imperfect tense for ongoing or habitual past actions", "level": 13, "section": "intermediate", "exercises": [
            {"id": "ex_imp_1", "type": "multipleChoice", "question": "When do we use the imperfect tense in Dutch?", "options": ["For habitual or ongoing past actions", "For completed one-time actions", "For future events", "For commands"], "correctAnswer": "For habitual or ongoing past actions"},
            {"id": "ex_imp_2", "type": "matchPairs", "question": "Match SPREKEN imperfect conjugations", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik sprak", "native": "I used to speak"}, {"target": "Jij sprak", "native": "You used to speak"}, {"target": "Hij sprak", "native": "He used to speak"}, {"target": "Wij spraken", "native": "We used to speak"}, {"target": "Zij spraken", "native": "They used to speak"}]}},
            {"id": "ex_imp_3", "type": "translateThis", "question": "Toen ik een kind was, speelde ik in het park", "options": [], "correctAnswer": "When I was a child, I used to play in the park"},
            {"id": "ex_imp_4", "type": "fillInBlank", "question": "Vroeger ___ ik veel koffie", "options": ["dronk", "drink", "gedronken", "zal drinken"], "correctAnswer": "dronk"},
            {"id": "ex_imp_5", "type": "multipleChoice", "question": "What is the imperfect of 'zijn' for 'ik'?", "options": ["Was", "Ben", "Geweest", "Zal zijn"], "correctAnswer": "Was"}
        ]},
        {"id": "present_perfect", "name": "Present Perfect", "desc": "Learn to express past actions with present relevance", "level": 13, "section": "intermediate", "exercises": [
            {"id": "ex_pp_1", "type": "multipleChoice", "question": "How do you form the present perfect in Dutch?", "options": ["hebben/zijn + past participle", "zijn + aan het + infinitive", "zijn + bijvoeglijk", "gaan + infinitive"], "correctAnswer": "hebben/zijn + past participle"},
            {"id": "ex_pp_2", "type": "matchPairs", "question": "Match HEBBEN conjugations (present)", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik heb", "native": "I have"}, {"target": "Jij hebt", "native": "You have"}, {"target": "Hij heeft", "native": "He has"}, {"target": "Wij hebben", "native": "We have"}, {"target": "Zij hebben", "native": "They have"}]}},
            {"id": "ex_pp_3", "type": "translateThis", "question": "Ik heb stamppot gegeten", "options": [], "correctAnswer": "I have eaten stamppot"},
            {"id": "ex_pp_4", "type": "fillInBlank", "question": "Zij ___ nooit Parijs bezocht", "options": ["heeft", "heb", "hebt", "hebben"], "correctAnswer": "heeft"},
            {"id": "ex_pp_5", "type": "matchPairs", "question": "Match irregular past participles", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Gedaan", "native": "Done/Made"}, {"target": "Gezegd", "native": "Said"}, {"target": "Geschreven", "native": "Written"}, {"target": "Gezien", "native": "Seen"}, {"target": "Gezet", "native": "Put"}]}}
        ]},
        {"id": "future_tense", "name": "Future Tense", "desc": "Learn to express future actions", "level": 14, "section": "intermediate", "exercises": [
            {"id": "ex_fut_1", "type": "multipleChoice", "question": "What are the two ways to express future in Dutch?", "options": ["gaan + infinitive AND zullen + infinitive", "zijn + infinitive AND hebben + voltooid deelwoord", "hebben + infinitive AND present tense", "None of the above"], "correctAnswer": "gaan + infinitive AND zullen + infinitive"},
            {"id": "ex_fut_2", "type": "matchPairs", "question": "Match future tense with ZULLEN", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik zal spreken", "native": "I will speak"}, {"target": "Jij zult spreken", "native": "You will speak"}, {"target": "Hij zal spreken", "native": "He will speak"}, {"target": "Wij zullen spreken", "native": "We will speak"}, {"target": "Zij zullen spreken", "native": "They will speak"}]}},
            {"id": "ex_fut_3", "type": "translateThis", "question": "Morgen ga ik naar de bioscoop", "options": [], "correctAnswer": "Tomorrow I will go to the cinema"},
            {"id": "ex_fut_4", "type": "fillInBlank", "question": "Ik ___ vanavond studeren", "options": ["ga", "ben", "heb", "zal"], "correctAnswer": "ga"},
            {"id": "ex_fut_5", "type": "speakThis", "question": "Volgend jaar ga ik naar Nederland reizen", "options": [], "correctAnswer": "Volgend jaar ga ik naar Nederland reizen"}
        ]},
        {"id": "making_plans", "name": "Making Plans", "desc": "Learn to make suggestions and invitations", "level": 14, "section": "intermediate", "exercises": [
            {"id": "ex_mp_1", "type": "multipleChoice", "question": "How do you suggest 'Let's go'?", "options": ["Laten we gaan", "Ik ga", "Jij gaat", "Zij gaan"], "correctAnswer": "Laten we gaan"},
            {"id": "ex_mp_2", "type": "matchPairs", "question": "Match plan-making phrases", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Zou je willen...?", "native": "Would you like to...?"}, {"target": "Wat vind je ervan als...?", "native": "What do you think if...?"}, {"target": "Waarom niet...?", "native": "Why don't we...?"}, {"target": "We kunnen...", "native": "We can..."}, {"target": "Spreken we af om...?", "native": "Shall we meet at...?"}]}},
            {"id": "ex_mp_3", "type": "translateThis", "question": "Heb je zin om naar de bioscoop te gaan?", "options": [], "correctAnswer": "Do you feel like going to the cinema?"},
            {"id": "ex_mp_4", "type": "fillInBlank", "question": "___ gaan we vanavond eten?", "options": ["Waar", "Wat", "Wie", "Hoeveel"], "correctAnswer": "Waar"},
            {"id": "ex_mp_5", "type": "speakThis", "question": "Goed idee! Tot acht uur", "options": [], "correctAnswer": "Goed idee! Tot acht uur"}
        ]},
        {"id": "appointments", "name": "Appointments", "desc": "Learn to schedule and manage appointments", "level": 14, "section": "intermediate", "exercises": [
            {"id": "ex_apt_1", "type": "multipleChoice", "question": "How do you say 'I have an appointment'?", "options": ["Ik heb een afspraak", "Ik heb een tijd", "Ik heb een uur", "Ik heb een plek"], "correctAnswer": "Ik heb een afspraak"},
            {"id": "ex_apt_2", "type": "matchPairs", "question": "Match appointment vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Annuleren", "native": "To cancel"}, {"target": "Uitstellen", "native": "To postpone"}, {"target": "Bevestigen", "native": "To confirm"}, {"target": "Verzetten", "native": "To reschedule"}, {"target": "Beschikbaar", "native": "Available"}]}},
            {"id": "ex_apt_3", "type": "translateThis", "question": "Ik zou graag een afspraak willen maken voor maandag", "options": [], "correctAnswer": "I would like to request an appointment for Monday"},
            {"id": "ex_apt_4", "type": "fillInBlank", "question": "Het spijt me, maar ik moet de afspraak ___", "options": ["annuleren", "gaan", "hebben", "zijn"], "correctAnswer": "annuleren"},
            {"id": "ex_apt_5", "type": "speakThis", "question": "Heeft u morgen een vrij moment?", "options": [], "correctAnswer": "Heeft u morgen een vrij moment?"}
        ]},
        {"id": "comparatives", "name": "Comparatives", "desc": "Learn to compare things using meer, minder, zo...als", "level": 15, "section": "intermediate", "exercises": [
            {"id": "ex_comp_1", "type": "multipleChoice", "question": "How do you say 'bigger than'?", "options": ["groter dan", "zo groot als", "heel groot", "het grootste"], "correctAnswer": "groter dan"},
            {"id": "ex_comp_2", "type": "matchPairs", "question": "Match comparative structures", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "...er dan", "native": "More...than"}, {"target": "Minder...dan", "native": "Less...than"}, {"target": "Zo...als", "native": "As...as"}, {"target": "Evenveel als", "native": "As much as"}, {"target": "Beter dan", "native": "Better than"}]}},
            {"id": "ex_comp_3", "type": "translateThis", "question": "Maria is langer dan Jan", "options": [], "correctAnswer": "Maria is taller than Jan"},
            {"id": "ex_comp_4", "type": "fillInBlank", "question": "Dit boek is ___ interessant dan dat", "options": ["interessanter", "heel", "veel", "zo"], "correctAnswer": "interessanter"},
            {"id": "ex_comp_5", "type": "multipleChoice", "question": "What is the comparative of 'goed'?", "options": ["Beter", "Goeder", "Heel goed", "Best"], "correctAnswer": "Beter"}
        ]},
        {"id": "superlatives", "name": "Superlatives", "desc": "Learn to express 'the most' and 'the least'", "level": 15, "section": "intermediate", "exercises": [
            {"id": "ex_sup_1", "type": "multipleChoice", "question": "How do you say 'the tallest'?", "options": ["de langste", "langer dan", "heel lang", "zo lang als"], "correctAnswer": "de langste"},
            {"id": "ex_sup_2", "type": "matchPairs", "question": "Match superlative forms", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De beste", "native": "The best"}, {"target": "De slechtste", "native": "The worst"}, {"target": "De oudste", "native": "The oldest"}, {"target": "De jongste", "native": "The youngest"}, {"target": "De grootste", "native": "The biggest"}]}},
            {"id": "ex_sup_3", "type": "translateThis", "question": "Het is het meest interessante boek ter wereld", "options": [], "correctAnswer": "It's the most interesting book in the world"},
            {"id": "ex_sup_4", "type": "fillInBlank", "question": "Dit is het duurste restaurant ___ de stad", "options": ["van", "in", "naar", "met"], "correctAnswer": "van"},
            {"id": "ex_sup_5", "type": "speakThis", "question": "Mijn zus is de slimste van de familie", "options": [], "correctAnswer": "Mijn zus is de slimste van de familie"}
        ]},
        {"id": "health_body", "name": "Health & Body", "desc": "Learn body parts and health vocabulary", "level": 16, "section": "intermediate", "exercises": [
            {"id": "ex_hb_1", "type": "matchPairs", "question": "Match body parts", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Het hoofd", "native": "The head"}, {"target": "De arm", "native": "The arm"}, {"target": "Het been", "native": "The leg"}, {"target": "De maag", "native": "The stomach"}, {"target": "De rug", "native": "The back"}, {"target": "Het hart", "native": "The heart"}]}},
            {"id": "ex_hb_2", "type": "translateThis", "question": "Ik heb hoofdpijn", "options": [], "correctAnswer": "My head hurts"},
            {"id": "ex_hb_3", "type": "fillInBlank", "question": "Ik heb ___ in mijn keel", "options": ["pijn", "slecht", "ziek", "koorts"], "correctAnswer": "pijn"},
            {"id": "ex_hb_4", "type": "matchPairs", "question": "Match common ailments", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Koorts", "native": "Fever"}, {"target": "Hoest", "native": "Cough"}, {"target": "Verkoudheid", "native": "Cold"}, {"target": "Griep", "native": "Flu"}, {"target": "Pijn", "native": "Pain"}]}},
            {"id": "ex_hb_5", "type": "speakThis", "question": "Ik voel me niet lekker", "options": [], "correctAnswer": "Ik voel me niet lekker"}
        ]},
        {"id": "at_the_doctor", "name": "At the Doctor", "desc": "Learn vocabulary for medical visits", "level": 16, "section": "intermediate", "exercises": [
            {"id": "ex_doc_1", "type": "matchPairs", "question": "Match medical vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De dokter", "native": "The doctor"}, {"target": "Het recept", "native": "The prescription"}, {"target": "Het medicijn", "native": "The medicine"}, {"target": "De doktersafspraak", "native": "The medical appointment"}, {"target": "De zorgverzekering", "native": "Health insurance"}]}},
            {"id": "ex_doc_2", "type": "translateThis", "question": "Welke symptomen heeft u?", "options": [], "correctAnswer": "What symptoms do you have?"},
            {"id": "ex_doc_3", "type": "fillInBlank", "question": "Ik heb een ___ nodig voor deze pillen", "options": ["recept", "afspraak", "medicijn", "apotheek"], "correctAnswer": "recept"},
            {"id": "ex_doc_4", "type": "multipleChoice", "question": "How do you say 'I'm allergic to penicillin'?", "options": ["Ik ben allergisch voor penicilline", "Ik heb allergie penicilline", "Ik hou van penicilline", "Ik wil penicilline"], "correctAnswer": "Ik ben allergisch voor penicilline"},
            {"id": "ex_doc_5", "type": "speakThis", "question": "Ik moet naar een dokter", "options": [], "correctAnswer": "Ik moet naar een dokter"}
        ]},
        {"id": "travel", "name": "Travel", "desc": "Learn essential travel vocabulary", "level": 17, "section": "advanced", "exercises": [
            {"id": "ex_trav_1", "type": "matchPairs", "question": "Match travel vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Het paspoort", "native": "Passport"}, {"target": "De bagage", "native": "Luggage"}, {"target": "De vlucht", "native": "Flight"}, {"target": "De koffer", "native": "Suitcase"}, {"target": "De luchthaven", "native": "Airport"}, {"target": "Het kaartje", "native": "Ticket"}]}},
            {"id": "ex_trav_2", "type": "translateThis", "question": "Ik ben mijn bagage kwijt", "options": [], "correctAnswer": "I have lost my luggage"},
            {"id": "ex_trav_3", "type": "fillInBlank", "question": "Waar is de ___?", "options": ["gate", "aankomst", "vertrek", "ingang"], "correctAnswer": "gate"},
            {"id": "ex_trav_4", "type": "multipleChoice", "question": "How do you ask 'Is this seat taken?'", "options": ["Is deze stoel bezet?", "Waar is de stoel?", "Hoeveel stoelen zijn er?", "Is dit mijn stoel?"], "correctAnswer": "Is deze stoel bezet?"},
            {"id": "ex_trav_5", "type": "speakThis", "question": "Ik heb hulp nodig met mijn koffers", "options": [], "correctAnswer": "Ik heb hulp nodig met mijn koffers"}
        ]},
        {"id": "hotel", "name": "At the Hotel", "desc": "Learn vocabulary for hotel stays", "level": 17, "section": "advanced", "exercises": [
            {"id": "ex_hot_1", "type": "matchPairs", "question": "Match hotel vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De kamer", "native": "The room"}, {"target": "De receptie", "native": "The reception"}, {"target": "De sleutel", "native": "The key"}, {"target": "De lift", "native": "The elevator"}, {"target": "Ontbijt inbegrepen", "native": "Breakfast included"}]}},
            {"id": "ex_hot_2", "type": "translateThis", "question": "Ik heb een reservering op naam van De Vries", "options": [], "correctAnswer": "I have a reservation under the name De Vries"},
            {"id": "ex_hot_3", "type": "fillInBlank", "question": "Ik zou graag een ___ kamer willen voor twee nachten", "options": ["tweepersoons", "twee", "paar", "grote"], "correctAnswer": "tweepersoons"},
            {"id": "ex_hot_4", "type": "multipleChoice", "question": "How do you ask 'What time is checkout?'", "options": ["Hoe laat is het uitchecken?", "Wanneer kan ik binnenkomen?", "Waar is de sleutel?", "Hoeveel kost het?"], "correctAnswer": "Hoe laat is het uitchecken?"},
            {"id": "ex_hot_5", "type": "speakThis", "question": "Heeft u kamers beschikbaar?", "options": [], "correctAnswer": "Heeft u kamers beschikbaar?"}
        ]},
        {"id": "sightseeing", "name": "Sightseeing", "desc": "Learn vocabulary for tourist activities", "level": 17, "section": "advanced", "exercises": [
            {"id": "ex_sight_1", "type": "matchPairs", "question": "Match sightseeing vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Het museum", "native": "The museum"}, {"target": "De kathedraal", "native": "The cathedral"}, {"target": "Het monument", "native": "The monument"}, {"target": "Het strand", "native": "The beach"}, {"target": "Het kasteel", "native": "The castle"}, {"target": "Het plein", "native": "The square"}]}},
            {"id": "ex_sight_2", "type": "translateThis", "question": "Waar kan ik kaartjes kopen?", "options": [], "correctAnswer": "Where can I buy tickets?"},
            {"id": "ex_sight_3", "type": "fillInBlank", "question": "Zijn er ___?", "options": ["rondleidingen", "gratis", "open", "gesloten"], "correctAnswer": "rondleidingen"},
            {"id": "ex_sight_4", "type": "multipleChoice", "question": "How do you ask 'What is the opening time?'", "options": ["Hoe laat gaat het open?", "Waar is het?", "Hoeveel kost het?", "Wat is het?"], "correctAnswer": "Hoe laat gaat het open?"},
            {"id": "ex_sight_5", "type": "speakThis", "question": "Ik zou graag het historische centrum willen bezoeken", "options": [], "correctAnswer": "Ik zou graag het historische centrum willen bezoeken"}
        ]},
        {"id": "hobbies", "name": "Hobbies", "desc": "Learn to talk about hobbies and free time activities", "level": 18, "section": "advanced", "exercises": [
            {"id": "ex_hob_1", "type": "multipleChoice", "question": "How do you ask 'What are your hobbies?'", "options": ["Wat zijn je hobby's?", "Wat werk je?", "Waar woon je?", "Hoe gaat het?"], "correctAnswer": "Wat zijn je hobby's?"},
            {"id": "ex_hob_2", "type": "matchPairs", "question": "Match hobbies", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Lezen", "native": "Reading"}, {"target": "Koken", "native": "Cooking"}, {"target": "Schilderen", "native": "Painting"}, {"target": "Dansen", "native": "Dancing"}, {"target": "Reizen", "native": "Traveling"}, {"target": "Fotografie", "native": "Photography"}]}},
            {"id": "ex_hob_3", "type": "translateThis", "question": "In mijn vrije tijd lees ik graag", "options": [], "correctAnswer": "In my free time I like to read"},
            {"id": "ex_hob_4", "type": "fillInBlank", "question": "Ik ___ graag gitaar spelen", "options": ["wil", "wilt", "willen", "wilde"], "correctAnswer": "wil"},
            {"id": "ex_hob_5", "type": "speakThis", "question": "Mijn favoriete hobby is videogames spelen", "options": [], "correctAnswer": "Mijn favoriete hobby is videogames spelen"}
        ]},
        {"id": "sports", "name": "Sports", "desc": "Learn vocabulary for sports and exercise", "level": 18, "section": "advanced", "exercises": [
            {"id": "ex_sp_1", "type": "matchPairs", "question": "Match sports", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Voetbal", "native": "Soccer/Football"}, {"target": "Basketbal", "native": "Basketball"}, {"target": "Tennis", "native": "Tennis"}, {"target": "Zwemmen", "native": "Swimming"}, {"target": "Fietsen", "native": "Cycling"}, {"target": "Yoga", "native": "Yoga"}]}},
            {"id": "ex_sp_2", "type": "translateThis", "question": "Ik voetbal op zaterdag", "options": [], "correctAnswer": "I play soccer on Saturdays"},
            {"id": "ex_sp_3", "type": "fillInBlank", "question": "Ik ga drie keer per week naar de ___", "options": ["sportschool", "bioscoop", "restaurant", "bank"], "correctAnswer": "sportschool"},
            {"id": "ex_sp_4", "type": "multipleChoice", "question": "How do you say 'to win'?", "options": ["Winnen", "Verliezen", "Spelen", "Rennen"], "correctAnswer": "Winnen"},
            {"id": "ex_sp_5", "type": "speakThis", "question": "Mijn favoriete team is Ajax", "options": [], "correctAnswer": "Mijn favoriete team is Ajax"}
        ]},
        {"id": "music_movies", "name": "Music & Movies", "desc": "Learn vocabulary for entertainment", "level": 18, "section": "advanced", "exercises": [
            {"id": "ex_mm_1", "type": "matchPairs", "question": "Match entertainment vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De film", "native": "The movie"}, {"target": "Het lied", "native": "The song"}, {"target": "Het concert", "native": "The concert"}, {"target": "De acteur", "native": "The actor"}, {"target": "De zanger", "native": "The singer"}, {"target": "De band", "native": "The band"}]}},
            {"id": "ex_mm_2", "type": "translateThis", "question": "Wat voor muziek vind je leuk?", "options": [], "correctAnswer": "What type of music do you like?"},
            {"id": "ex_mm_3", "type": "fillInBlank", "question": "Mijn favoriete ___ is komedie", "options": ["genre", "film", "acteur", "muziek"], "correctAnswer": "genre"},
            {"id": "ex_mm_4", "type": "matchPairs", "question": "Match movie genres", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Komedie", "native": "Comedy"}, {"target": "Drama", "native": "Drama"}, {"target": "Horror", "native": "Horror"}, {"target": "Sciencefiction", "native": "Science fiction"}, {"target": "Romantisch", "native": "Romance"}]}},
            {"id": "ex_mm_5", "type": "speakThis", "question": "Heb je de laatste film van die regisseur gezien?", "options": [], "correctAnswer": "Heb je de laatste film van die regisseur gezien?"}
        ]},
        {"id": "work", "name": "Work & Profession", "desc": "Learn vocabulary for jobs and careers", "level": 19, "section": "advanced", "exercises": [
            {"id": "ex_wk_1", "type": "multipleChoice", "question": "How do you ask 'What do you do for work?'", "options": ["Wat doe je voor werk?", "Waar woon je?", "Hoe gaat het?", "Wat eet je?"], "correctAnswer": "Wat doe je voor werk?"},
            {"id": "ex_wk_2", "type": "matchPairs", "question": "Match professions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Advocaat", "native": "Lawyer"}, {"target": "Dokter", "native": "Doctor"}, {"target": "Ingenieur", "native": "Engineer"}, {"target": "Leraar/Lerares", "native": "Teacher"}, {"target": "Verpleegkundige", "native": "Nurse"}, {"target": "Accountant", "native": "Accountant"}]}},
            {"id": "ex_wk_3", "type": "translateThis", "question": "Ik werk bij een technologiebedrijf", "options": [], "correctAnswer": "I work at a technology company"},
            {"id": "ex_wk_4", "type": "fillInBlank", "question": "Ik ben op zoek naar een nieuwe ___", "options": ["baan", "werken", "werkend", "werkt"], "correctAnswer": "baan"},
            {"id": "ex_wk_5", "type": "speakThis", "question": "Ik ben programmeur en ik werk vanuit huis", "options": [], "correctAnswer": "Ik ben programmeur en ik werk vanuit huis"}
        ]},
        {"id": "office", "name": "Office Vocabulary", "desc": "Learn vocabulary for the workplace", "level": 19, "section": "advanced", "exercises": [
            {"id": "ex_off_1", "type": "matchPairs", "question": "Match office vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Het kantoor", "native": "The office"}, {"target": "De baas", "native": "The boss"}, {"target": "De collega", "native": "The colleague"}, {"target": "De vergadering", "native": "The meeting"}, {"target": "Het salaris", "native": "The salary"}, {"target": "De vakantie", "native": "The vacation"}]}},
            {"id": "ex_off_2", "type": "translateThis", "question": "We hebben een vergadering om tien uur", "options": [], "correctAnswer": "We have a meeting at ten"},
            {"id": "ex_off_3", "type": "fillInBlank", "question": "Ik moet dit ___ per e-mail versturen", "options": ["document", "kantoor", "vergadering", "baas"], "correctAnswer": "document"},
            {"id": "ex_off_4", "type": "matchPairs", "question": "Match more office terms", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Het bureau", "native": "The desk"}, {"target": "De computer", "native": "The computer"}, {"target": "De printer", "native": "The printer"}, {"target": "Het bestand", "native": "The file"}, {"target": "Het wachtwoord", "native": "The password"}]}},
            {"id": "ex_off_5", "type": "speakThis", "question": "Mag ik morgen thuiswerken?", "options": [], "correctAnswer": "Mag ik morgen thuiswerken?"}
        ]},
        {"id": "technology", "name": "Technology", "desc": "Learn vocabulary for technology and devices", "level": 20, "section": "advanced", "exercises": [
            {"id": "ex_tech_1", "type": "matchPairs", "question": "Match technology vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De mobiele telefoon", "native": "Cell phone"}, {"target": "De computer", "native": "Computer"}, {"target": "De tablet", "native": "Tablet"}, {"target": "Het scherm", "native": "Screen"}, {"target": "Het toetsenbord", "native": "Keyboard"}, {"target": "De muis", "native": "Mouse"}]}},
            {"id": "ex_tech_2", "type": "translateThis", "question": "Mijn telefoon heeft geen batterij meer", "options": [], "correctAnswer": "My phone has no battery"},
            {"id": "ex_tech_3", "type": "fillInBlank", "question": "Ik moet de app ___", "options": ["downloaden", "eten", "drinken", "lezen"], "correctAnswer": "downloaden"},
            {"id": "ex_tech_4", "type": "multipleChoice", "question": "How do you say 'to turn on'?", "options": ["Aanzetten", "Uitzetten", "Opladen", "Downloaden"], "correctAnswer": "Aanzetten"},
            {"id": "ex_tech_5", "type": "speakThis", "question": "Wat is het wifi-wachtwoord?", "options": [], "correctAnswer": "Wat is het wifi-wachtwoord?"}
        ]},
        {"id": "internet", "name": "Internet & Social Media", "desc": "Learn vocabulary for online communication", "level": 20, "section": "advanced", "exercises": [
            {"id": "ex_int_1", "type": "matchPairs", "question": "Match internet vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De e-mail", "native": "Email"}, {"target": "Het sociale netwerk", "native": "Social network"}, {"target": "De website", "native": "Website"}, {"target": "Zoeken", "native": "To search"}, {"target": "Plaatsen", "native": "To post"}, {"target": "Delen", "native": "To share"}]}},
            {"id": "ex_int_2", "type": "translateThis", "question": "Kun je me een bericht sturen?", "options": [], "correctAnswer": "Can you send me a message?"},
            {"id": "ex_int_3", "type": "fillInBlank", "question": "Ik ga deze foto op Instagram ___", "options": ["plaatsen", "eten", "drinken", "gaan"], "correctAnswer": "plaatsen"},
            {"id": "ex_int_4", "type": "matchPairs", "question": "Match social media terms", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Volgen", "native": "To follow"}, {"target": "Vind ik leuk", "native": "Like"}, {"target": "Reactie", "native": "Comment"}, {"target": "Profiel", "native": "Profile"}, {"target": "Live", "native": "Live"}]}},
            {"id": "ex_int_5", "type": "speakThis", "question": "Ik heb je een bericht gestuurd via WhatsApp", "options": [], "correctAnswer": "Ik heb je een bericht gestuurd via WhatsApp"}
        ]},
        {"id": "emotions", "name": "Feelings & Emotions", "desc": "Learn to express nuanced emotions", "level": 21, "section": "advanced", "exercises": [
            {"id": "ex_em_1", "type": "matchPairs", "question": "Match emotions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Blij", "native": "Happy"}, {"target": "Verdrietig", "native": "Sad"}, {"target": "Boos", "native": "Angry"}, {"target": "Opgewonden", "native": "Excited"}, {"target": "Bezorgd", "native": "Worried"}, {"target": "Verrast", "native": "Surprised"}]}},
            {"id": "ex_em_2", "type": "translateThis", "question": "Ik ben heel enthousiast over de reis", "options": [], "correctAnswer": "I am very excited about the trip"},
            {"id": "ex_em_3", "type": "fillInBlank", "question": "Ik voel me ___ door de situatie", "options": ["gefrustreerd", "frustrerend", "frustreren", "frustreer"], "correctAnswer": "gefrustreerd"},
            {"id": "ex_em_4", "type": "matchPairs", "question": "Match more emotions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Nerveus", "native": "Nervous"}, {"target": "Verveeld", "native": "Bored"}, {"target": "Verward", "native": "Confused"}, {"target": "Dankbaar", "native": "Grateful"}, {"target": "Trots", "native": "Proud"}]}},
            {"id": "ex_em_5", "type": "speakThis", "question": "Ik ben een beetje teleurgesteld over het resultaat", "options": [], "correctAnswer": "Ik ben een beetje teleurgesteld over het resultaat"}
        ]},
        {"id": "opinions", "name": "Giving Opinions", "desc": "Learn to express and ask for opinions", "level": 21, "section": "advanced", "exercises": [
            {"id": "ex_op_1", "type": "matchPairs", "question": "Match opinion phrases", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik geloof dat...", "native": "I believe that..."}, {"target": "Naar mijn mening...", "native": "In my opinion..."}, {"target": "Het lijkt me dat...", "native": "It seems to me that..."}, {"target": "Ik denk dat...", "native": "I think that..."}, {"target": "Vanuit mijn standpunt...", "native": "From my point of view..."}]}},
            {"id": "ex_op_2", "type": "translateThis", "question": "Wat vind je van dit idee?", "options": [], "correctAnswer": "What do you think of this idea?"},
            {"id": "ex_op_3", "type": "fillInBlank", "question": "Naar mijn ___ is het een goede beslissing", "options": ["mening", "menen", "meen", "menend"], "correctAnswer": "mening"},
            {"id": "ex_op_4", "type": "multipleChoice", "question": "How do you say 'I agree'?", "options": ["Ik ben het ermee eens", "Ik ben het er niet mee eens", "Ik weet het niet", "Misschien"], "correctAnswer": "Ik ben het ermee eens"},
            {"id": "ex_op_5", "type": "speakThis", "question": "Persoonlijk denk ik dat je gelijk hebt", "options": [], "correctAnswer": "Persoonlijk denk ik dat je gelijk hebt"}
        ]},
        {"id": "debating", "name": "Debating", "desc": "Learn to agree, disagree, and debate politely", "level": 21, "section": "advanced", "exercises": [
            {"id": "ex_deb_1", "type": "matchPairs", "question": "Match agreement/disagreement phrases", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik ben het ermee eens", "native": "I agree"}, {"target": "Ik ben het er niet mee eens", "native": "I disagree"}, {"target": "Je hebt gelijk", "native": "You're right"}, {"target": "Ik denk het niet", "native": "I don't think so"}, {"target": "Dat hangt ervan af", "native": "It depends"}]}},
            {"id": "ex_deb_2", "type": "translateThis", "question": "Ik respecteer je mening, maar ik ben het er niet mee eens", "options": [], "correctAnswer": "I respect your opinion, but I disagree"},
            {"id": "ex_deb_3", "type": "fillInBlank", "question": "Aan de ene kant... aan de ___ kant...", "options": ["andere", "een", "de", "deze"], "correctAnswer": "andere"},
            {"id": "ex_deb_4", "type": "matchPairs", "question": "Match debate connectors", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Echter", "native": "However"}, {"target": "Hoewel", "native": "Although"}, {"target": "Daarom", "native": "Therefore"}, {"target": "Daarentegen", "native": "On the other hand"}, {"target": "Desondanks", "native": "Nevertheless"}]}},
            {"id": "ex_deb_5", "type": "speakThis", "question": "Ik begrijp je standpunt, echter...", "options": [], "correctAnswer": "Ik begrijp je standpunt, echter..."}
        ]},
        {"id": "conditional", "name": "Conditional Tense", "desc": "Learn to express hypothetical situations", "level": 22, "section": "advanced", "exercises": [
            {"id": "ex_cond_1", "type": "multipleChoice", "question": "When do we use the conditional tense?", "options": ["For hypothetical situations and polite requests", "For past events", "For future facts", "For commands"], "correctAnswer": "For hypothetical situations and polite requests"},
            {"id": "ex_cond_2", "type": "matchPairs", "question": "Match conditional forms (zou + infinitive)", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik zou spreken", "native": "I would speak"}, {"target": "Jij zou spreken", "native": "You would speak"}, {"target": "Hij zou spreken", "native": "He would speak"}, {"target": "Wij zouden spreken", "native": "We would speak"}, {"target": "Zij zouden spreken", "native": "They would speak"}]}},
            {"id": "ex_cond_3", "type": "translateThis", "question": "Als ik geld had, zou ik de wereld rondreizen", "options": [], "correctAnswer": "If I had money, I would travel the world"},
            {"id": "ex_cond_4", "type": "fillInBlank", "question": "___ je me hiermee kunnen helpen?", "options": ["Zou", "Kan", "Kon", "Zal"], "correctAnswer": "Zou"},
            {"id": "ex_cond_5", "type": "speakThis", "question": "Ik zou graag een tafel voor vier reserveren", "options": [], "correctAnswer": "Ik zou graag een tafel voor vier reserveren"}
        ]},
        {"id": "subjunctive", "name": "Subjunctive Mood", "desc": "Learn the subjunctive for formal and archaic expressions", "level": 22, "section": "advanced", "exercises": [
            {"id": "ex_subj_1", "type": "multipleChoice", "question": "When is the subjunctive used in Dutch?", "options": ["In formal expressions and fixed phrases", "For everyday speech", "For past events", "For giving orders"], "correctAnswer": "In formal expressions and fixed phrases"},
            {"id": "ex_subj_2", "type": "matchPairs", "question": "Match subjunctive expressions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Ik hoop dat...", "native": "I hope that..."}, {"target": "Ik wil dat...", "native": "I want (you) to..."}, {"target": "Ik betwijfel of...", "native": "I doubt that..."}, {"target": "Het is belangrijk dat...", "native": "It's important that..."}, {"target": "Moge het zo zijn", "native": "May it be so"}]}},
            {"id": "ex_subj_3", "type": "translateThis", "question": "Ik hoop dat je een fijne dag hebt", "options": [], "correctAnswer": "I hope you have a good day"},
            {"id": "ex_subj_4", "type": "fillInBlank", "question": "Ik wil dat je de waarheid ___", "options": ["weet", "kent", "weten", "kennend"], "correctAnswer": "weet"},
            {"id": "ex_subj_5", "type": "multipleChoice", "question": "Which is a fixed subjunctive expression?", "options": ["Leve de koning!", "Ik ben blij", "Hij werkt hard", "Wij gaan"], "correctAnswer": "Leve de koning!"}
        ]},
        {"id": "passive_voice", "name": "Passive Voice", "desc": "Learn to form and use passive constructions", "level": 23, "section": "advanced", "exercises": [
            {"id": "ex_pass_1", "type": "multipleChoice", "question": "How do you form the passive voice in Dutch?", "options": ["worden + past participle", "zijn + aan het + infinitive", "hebben + infinitive", "gaan + bijvoeglijk"], "correctAnswer": "worden + past participle"},
            {"id": "ex_pass_2", "type": "translateThis", "question": "Het boek werd geschreven door Mulisch", "options": [], "correctAnswer": "The book was written by Mulisch"},
            {"id": "ex_pass_3", "type": "fillInBlank", "question": "Het huis werd vorig jaar ___", "options": ["gebouwd", "bouwen", "bouwend", "bouwt"], "correctAnswer": "gebouwd"},
            {"id": "ex_pass_4", "type": "multipleChoice", "question": "Which construction is often preferred over passive in Dutch?", "options": ["Er wordt + past participle", "Zijn + deelwoord", "Hebben + infinitive", "Gaan + werkwoord"], "correctAnswer": "Er wordt + past participle"},
            {"id": "ex_pass_5", "type": "translateThis", "question": "Er wordt hier Nederlands gesproken", "options": [], "correctAnswer": "Dutch is spoken here"}
        ]},
        {"id": "phrasal_expressions", "name": "Phrasal Expressions", "desc": "Learn common verb + preposition combinations", "level": 23, "section": "advanced", "exercises": [
            {"id": "ex_phr_1", "type": "matchPairs", "question": "Match phrasal expressions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Net...hebben", "native": "To have just"}, {"target": "Stoppen met", "native": "To stop (doing)"}, {"target": "Beginnen met", "native": "To start (doing)"}, {"target": "Proberen te", "native": "To try to"}, {"target": "Denken aan", "native": "To think about"}]}},
            {"id": "ex_phr_2", "type": "translateThis", "question": "Ik ben net aangekomen", "options": [], "correctAnswer": "I have just arrived"},
            {"id": "ex_phr_3", "type": "fillInBlank", "question": "Ik moet stoppen ___ roken", "options": ["met", "te", "aan", "van"], "correctAnswer": "met"},
            {"id": "ex_phr_4", "type": "matchPairs", "question": "Match more phrasal expressions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Dromen van", "native": "To dream about"}, {"target": "Rekenen op", "native": "To count on"}, {"target": "Letten op", "native": "To notice"}, {"target": "Zich herinneren", "native": "To remember"}, {"target": "Vergeten", "native": "To forget"}]}},
            {"id": "ex_phr_5", "type": "speakThis", "question": "Ik herinner me toen we kinderen waren", "options": [], "correctAnswer": "Ik herinner me toen we kinderen waren"}
        ]},
        {"id": "idioms", "name": "Idioms", "desc": "Learn common Dutch idiomatic expressions", "level": 24, "section": "advanced", "exercises": [
            {"id": "ex_id_1", "type": "matchPairs", "question": "Match idioms with meanings", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Met je hoofd in de wolken lopen", "native": "To be daydreaming"}, {"target": "Een arm en een been kosten", "native": "To cost an arm and a leg"}, {"target": "In de fout gaan", "native": "To put your foot in it"}, {"target": "Iemand in de maling nemen", "native": "To pull someone's leg"}, {"target": "Een fluitje van een cent", "native": "To be a piece of cake"}]}},
            {"id": "ex_id_2", "type": "translateThis", "question": "Dat is niet mijn kopje thee", "options": [], "correctAnswer": "It's not my cup of tea"},
            {"id": "ex_id_3", "type": "multipleChoice", "question": "What does 'Een ongeluk komt nooit alleen' mean?", "options": ["It never rains but it pours", "It's raining cats and dogs", "After the storm comes the calm", "Every cloud has a silver lining"], "correctAnswer": "It never rains but it pours"},
            {"id": "ex_id_4", "type": "matchPairs", "question": "Match more idioms", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "De handdoek in de ring gooien", "native": "To throw in the towel"}, {"target": "Er genoeg van hebben", "native": "To be fed up"}, {"target": "Een blackout hebben", "native": "To go blank"}, {"target": "Geen blad voor de mond nemen", "native": "To be outspoken"}, {"target": "De spijker op de kop slaan", "native": "To hit the nail on the head"}]}},
            {"id": "ex_id_5", "type": "speakThis", "question": "Dat is Chinees voor mij", "options": [], "correctAnswer": "Dat is Chinees voor mij"}
        ]},
        {"id": "slang", "name": "Slang & Colloquialisms", "desc": "Learn informal Dutch expressions", "level": 24, "section": "advanced", "exercises": [
            {"id": "ex_sl_1", "type": "matchPairs", "question": "Match Dutch slang expressions", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Gaaf", "native": "Cool/Awesome"}, {"target": "Gozer", "native": "Dude/Buddy"}, {"target": "Tof", "native": "Cool"}, {"target": "Sjansen", "native": "To flirt"}, {"target": "Balen", "native": "To be bummed out"}]}},
            {"id": "ex_sl_2", "type": "translateThis", "question": "Wat vet!", "options": [], "correctAnswer": "How awesome!/Wow!"},
            {"id": "ex_sl_3", "type": "matchPairs", "question": "Match more Dutch slang", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Lachen", "native": "Fun/Funny"}, {"target": "Chill", "native": "Relaxed/Cool"}, {"target": "Poen", "native": "Money"}, {"target": "Baantje", "native": "Job/Gig"}, {"target": "Gezellig", "native": "Cozy/Fun atmosphere"}]}},
            {"id": "ex_sl_4", "type": "multipleChoice", "question": "What does 'Gezellig' mean?", "options": ["A uniquely Dutch concept of coziness and good company", "Being alone", "Feeling sad", "Being in a hurry"], "correctAnswer": "A uniquely Dutch concept of coziness and good company"},
            {"id": "ex_sl_5", "type": "speakThis", "question": "Dat was echt super gezellig!", "options": [], "correctAnswer": "Dat was echt super gezellig!"}
        ]},
        {"id": "culture", "name": "Culture & Traditions", "desc": "Learn about Dutch culture and traditions", "level": 25, "section": "advanced", "exercises": [
            {"id": "ex_cult_1", "type": "matchPairs", "question": "Match cultural celebrations", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Koningsdag", "native": "King's Day (April 27)"}, {"target": "Sinterklaas", "native": "St. Nicholas Day (December 5)"}, {"target": "Bevrijdingsdag", "native": "Liberation Day (May 5)"}, {"target": "Carnaval", "native": "Carnival (February)"}, {"target": "Elfstedentocht", "native": "Eleven Cities Ice Skating Tour"}]}},
            {"id": "ex_cult_2", "type": "translateThis", "question": "Fietsen is een Nederlandse traditie", "options": [], "correctAnswer": "Cycling is a Dutch tradition"},
            {"id": "ex_cult_3", "type": "multipleChoice", "question": "What is 'gezelligheid'?", "options": ["A Dutch concept of coziness, togetherness and fun", "A type of food", "A Dutch dance", "A greeting"], "correctAnswer": "A Dutch concept of coziness, togetherness and fun"},
            {"id": "ex_cult_4", "type": "matchPairs", "question": "Match cultural elements", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Klompen", "native": "Wooden clogs"}, {"target": "Stroopwafels", "native": "Syrup waffles"}, {"target": "Tulpen", "native": "Tulips"}, {"target": "Windmolens", "native": "Windmills"}, {"target": "Hagelslag", "native": "Chocolate sprinkles on bread"}]}},
            {"id": "ex_cult_5", "type": "speakThis", "question": "Ik hou van de Nederlandse cultuur", "options": [], "correctAnswer": "Ik hou van de Nederlandse cultuur"}
        ]},
        {"id": "current_events", "name": "Current Events", "desc": "Learn vocabulary for discussing news and society", "level": 25, "section": "advanced", "exercises": [
            {"id": "ex_ce_1", "type": "matchPairs", "question": "Match news vocabulary", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Het nieuws", "native": "The news"}, {"target": "De journalist", "native": "The journalist"}, {"target": "De krant", "native": "The newspaper"}, {"target": "Het interview", "native": "The interview"}, {"target": "De kop", "native": "The headline"}]}},
            {"id": "ex_ce_2", "type": "translateThis", "question": "Heb je het laatste nieuws gezien?", "options": [], "correctAnswer": "Have you seen the latest news?"},
            {"id": "ex_ce_3", "type": "matchPairs", "question": "Match social topics", "options": [], "correctAnswer": "", "metadata": {"pairs": [{"target": "Het milieu", "native": "The environment"}, {"target": "De klimaatverandering", "native": "Climate change"}, {"target": "De economie", "native": "The economy"}, {"target": "De politiek", "native": "Politics"}, {"target": "De mensenrechten", "native": "Human rights"}]}},
            {"id": "ex_ce_4", "type": "fillInBlank", "question": "De regering kondigde nieuwe economische ___ aan", "options": ["maatregelen", "kranten", "nieuws", "interviews"], "correctAnswer": "maatregelen"},
            {"id": "ex_ce_5", "type": "speakThis", "question": "Het is belangrijk om op de hoogte te blijven van wat er in de wereld gebeurt", "options": [], "correctAnswer": "Het is belangrijk om op de hoogte te blijven van wat er in de wereld gebeurt"}
        ]},
    ]

    for r in remaining:
        skill_data = {
            "id": r["id"],
            "name": r["name"],
            "description": r["desc"],
            "level": r["level"],
            "exercises": r["exercises"]
        }
        skills.append(skill_data)

    print(f"Generating {len(skills)} Dutch skill files...")
    for s in skills:
        write_skill(s)
    print(f"\nDone! {len(skills)} files written to {SKILLS_DIR}")


if __name__ == '__main__':
    main()
