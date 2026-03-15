#!/usr/bin/env python3
"""
translate_books.py

Simple CLI to translate book paragraph texts using a LibreTranslate-compatible endpoint.
Defaults to translating to Spanish ("spanish" -> "es") and only the first N chapters (default 3).

Usage examples:
  python3 scripts/translate_books.py --target spanish --chapters 3
  python3 scripts/translate_books.py --target spanish --chapters 0 --all --force

WARNING: this uses a public translation endpoint by default; respect rate limits.
"""
import argparse
import glob
import json
import os
import time
from typing import Dict

import requests


LANG_MAP = {
    "spanish": "es",
    "english": "en",
    "french": "fr",
    "german": "de",
    "portuguese": "pt",
    "chinese": "zh",
    "japanese": "ja",
}


def translate_text(text: str, source: str, target: str, api_url: str, timeout: int = 30) -> str:
    payload = {
        "q": text,
        "source": source,
        "target": target,
        "format": "text",
    }
    headers = {"Content-Type": "application/json"}
    try:
        r = requests.post(api_url, json=payload, headers=headers, timeout=timeout)
        # Give helpful debug when the endpoint returns non-JSON or error
        if r.status_code != 200:
            print(f"translate_text: non-200 response {r.status_code} from {api_url}: {r.text[:400]}")
            return ""
        try:
            data = r.json()
        except ValueError:
            print(f"translate_text: invalid JSON response from {api_url}: {r.text[:400]}")
            return ""
        # LibreTranslate returns {'translatedText': '...'} or [{'translatedText': '...'}]
        if isinstance(data, dict):
            return data.get("translatedText") or ""
        if isinstance(data, list) and data:
            first = data[0]
            if isinstance(first, dict):
                return first.get("translatedText") or ""
        return ""
    except requests.RequestException as e:
        print(f"translate_text: request failed: {e}")
        return ""


def process_file(path: str, target_code: str, chapters: int, api_url: str, dry_run: bool, force: bool):
    with open(path, "r", encoding="utf-8") as f:
        book = json.load(f)

    source_code = LANG_MAP.get(book.get("originalLanguage", "english"), "en")
    # If availableTranslations is present, check target
    available = book.get("availableTranslations", [])
    # allow processing even if availableTranslations missing
    if available and target_code not in [LANG_MAP.get(t, t) for t in available] and not force:
        print(f"Skipping {book.get('id')} — target not listed in availableTranslations")
        return False

    max_chapters = chapters if chapters > 0 else None
    translated_count = 0
    total_count = 0

    for i, ch in enumerate(book.get("chapters", [])):
        if max_chapters is not None and i >= max_chapters:
            break
        for p in ch.get("paragraphs", []):
            total_count += 1
            if p.get("translatedText") and not force:
                continue
            original = p.get("originalText", "").strip()
            if not original:
                continue
            if dry_run:
                print(f"[dry-run] Would translate paragraph {p.get('id')} in {book.get('id')}")
                translated_count += 1
                continue
            translated = translate_text(original, source_code, target_code, api_url)
            if translated:
                p["translatedText"] = translated
                translated_count += 1
                # be polite to public servers
                time.sleep(1.0)
            else:
                print(f"Warning: failed to translate paragraph {p.get('id')} in {book.get('id')}")

    # update status
    if not dry_run:
        if total_count == translated_count and total_count > 0:
            book["translationStatus"] = "done"
        elif translated_count > 0:
            book["translationStatus"] = "partial"
        else:
            book["translationStatus"] = book.get("translationStatus", "pending")

        with open(path, "w", encoding="utf-8") as f:
            json.dump(book, f, ensure_ascii=False, indent=2)
        print(f"Updated {path}: translated {translated_count}/{total_count} paragraphs")

    return True


def main():
    parser = argparse.ArgumentParser(description="Translate book JSON paragraphs to a target language.")
    parser.add_argument("--target", default="spanish", help="Target language name (e.g., spanish)")
    parser.add_argument("--chapters", type=int, default=3, help="Number of chapters per book to translate (0 for all)")
    parser.add_argument("--all", action="store_true", help="Translate all chapters")
    parser.add_argument("--dry-run", action="store_true", help="Don't write output; just show actions")
    parser.add_argument("--force", action="store_true", help="Force re-translation even if translatedText exists")
    # Public LibreTranslate instances: https://translate.argosopentech.com/translate is commonly available
    parser.add_argument("--api-url", default="https://translate.argosopentech.com/translate", help="LibreTranslate API URL")
    args = parser.parse_args()

    target_name = args.target.lower()
    target_code = LANG_MAP.get(target_name)
    if not target_code:
        print(f"Unknown target language: {target_name}")
        return

    chapters = 0 if args.all else args.chapters

    book_paths = glob.glob(os.path.join("assets", "books", "*_en.json"))
    if not book_paths:
        print("No English book JSONs found in assets/books/")
        return

    for path in book_paths:
        print(f"Processing {path}...")
        process_file(path, target_code, chapters, args.api_url, args.dry_run, args.force)


if __name__ == "__main__":
    main()
