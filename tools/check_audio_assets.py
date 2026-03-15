#!/usr/bin/env python3
"""
Scan `assets/courses/*/skills/*.json` for `audioPath` usages,
set `audioAvailable` and `enabled` fields depending on whether the referenced
file exists (relative to the repo root; `courses/...` paths are under `assets/`).
Write per-language `assets/courses/<lang>/audio/missing_audio_list.txt` and a
summary `assets/courses/missing_audio_report.txt`.
"""
import json
from pathlib import Path

ROOT = Path(".").resolve()
ASSETS = ROOT / "assets" / "courses"
SKILLS_GLOB = "*/skills/*.json"

missing_global = {}
modified_count = 0

for skill_json in ASSETS.glob(SKILLS_GLOB):
    try:
        data = json.loads(skill_json.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"Skipping {skill_json}: failed to parse JSON ({e})")
        continue

    exercises = data.get("exercises", [])
    changed = False

    for ex in exercises:
        audio_path = ex.get("audioPath")
        if not audio_path:
            # ensure exercises without audio keep enabled (unless explicit)
            continue

        # resolve audio file path: if starts with 'courses/', prefix 'assets/'
        audio_candidate = Path(audio_path)
        if not audio_candidate.is_absolute():
            if str(audio_candidate).startswith("courses/"):
                audio_file = ROOT / "assets" / audio_candidate
            elif str(audio_candidate).startswith("assets/"):
                audio_file = ROOT / audio_candidate
            else:
                # best-effort: check under assets/
                audio_file = ROOT / "assets" / audio_candidate
        else:
            audio_file = audio_candidate

        exists = audio_file.exists()
        # update fields
        prev_avail = ex.get("audioAvailable")
        prev_enabled = ex.get("enabled")

        if exists:
            ex["audioAvailable"] = True
            # only enable if previously not explicitly disabled
            if prev_enabled is None:
                ex["enabled"] = True
            else:
                ex["enabled"] = bool(prev_enabled)
        else:
            ex["audioAvailable"] = False
            ex["enabled"] = False
            # record missing
            lang = skill_json.parts[skill_json.parts.index('courses')+1]
            missing_global.setdefault(lang, set()).add(str(audio_candidate))

        if ex.get("audioAvailable") != prev_avail or ex.get("enabled") != prev_enabled:
            changed = True

    if changed:
        skill_json.write_text(json.dumps(data, ensure_ascii=False, indent=4), encoding="utf-8")
        modified_count += 1
        print(f"Updated {skill_json}")

# write per-language missing lists and a global report
REPORTS_DIR = ASSETS
report_lines = []
for lang, files in missing_global.items():
    audio_dir = ASSETS / lang / "audio"
    audio_dir.mkdir(parents=True, exist_ok=True)
    list_path = audio_dir / "missing_audio_list.txt"
    with list_path.open("w", encoding="utf-8") as fh:
        for p in sorted(files):
            fh.write(p + "\n")
    report_lines.append(f"{lang}: {len(files)} missing files -> {list_path}")

summary_path = ASSETS / "missing_audio_report.txt"
with summary_path.open("w", encoding="utf-8") as fh:
    fh.write("Audio check summary\n")
    fh.write("===================\n")
    fh.write(f"Modified skill JSON files: {modified_count}\n")
    for line in report_lines:
        fh.write(line + "\n")

print("Done.")
print(f"Modified: {modified_count} files")
print(f"Report: {summary_path}")
