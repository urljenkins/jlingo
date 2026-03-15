#!/usr/bin/env python3
import os
import json
import urllib.request
import urllib.parse

ROOT = os.path.dirname(os.path.dirname(__file__))
SPANISH_DIR = os.path.join(ROOT, 'assets', 'courses', 'spanish', 'skills')
DUTCH_DIR = os.path.join(ROOT, 'assets', 'courses', 'dutch', 'skills')
API_URL = os.environ.get('TRANSLATE_API_URL', 'https://translate.argosopentech.com/translate')

def translate_text(text, source='en', target='nl'):
    if not text or text.strip() == '':
        return text
    data = json.dumps({
        'q': text,
        'source': source,
        'target': target,
        'format': 'text'
    }).encode('utf-8')
    req = urllib.request.Request(API_URL, data=data, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            res = json.load(resp)
            # LibreTranslate/Argos returns {'translatedText': '...'}
            return res.get('translatedText') or res.get('translated_text') or res.get('result') or ''
    except Exception as e:
        print('Translation failed for:', text, 'error:', e)
        return text


def process_file(fname):
    path = os.path.join(SPANISH_DIR, fname)
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # translate exercise questions from English 'correctAnswer' where available
    exercises = data.get('exercises', [])
    for ex in exercises:
        ca = ex.get('correctAnswer')
        # prefer translating English correctAnswer -> Dutch question
        if isinstance(ca, str) and ca.strip():
            translated = translate_text(ca, source='en', target='nl')
            if translated:
                ex['question'] = translated
        # handle matchPairs metadata
        meta = ex.get('metadata')
        if meta and isinstance(meta, dict):
            pairs = meta.get('pairs')
            if isinstance(pairs, list):
                for p in pairs:
                    native = p.get('native')
                    if isinstance(native, str) and native.strip():
                        p['target'] = translate_text(native, source='en', target='nl')

    # write to dutch dir
    out_path = os.path.join(DUTCH_DIR, fname)
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print('Wrote', out_path)


if __name__ == '__main__':
    os.makedirs(DUTCH_DIR, exist_ok=True)
    files = sorted([f for f in os.listdir(SPANISH_DIR) if f.endswith('.json')])
    for fn in files:
        print('Processing', fn)
        process_file(fn)
    print('Done')
