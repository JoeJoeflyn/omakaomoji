#!/usr/bin/env python3
import json
import os
from pathlib import Path

def ensure_menu_entry():
    ext_dir = Path.home() / ".config" / "omarchy" / "extensions"
    menu_file = ext_dir / "omarchy-menu.jsonc"

    kaomoji_entry = {
        "icon": "ツ",
        "label": "Kaomoji",
        "aliases": ["kaomoji", "emoticon", "facemoji", "ascii", "face"],
        "action": "omarchy-shell shell toggle omakaomoji",
        "description": "Japanese text faces & emoticons — (◕‿◕)"
    }

    ext_dir.mkdir(parents=True, exist_ok=True)

    data = {}
    if menu_file.exists():
        try:
            content = menu_file.read_text(encoding="utf-8")
            lines = [line for line in content.splitlines() if not line.strip().startswith("//")]
            data = json.loads("\n".join(lines))
        except Exception:
            data = {}

    if "trigger.kaomoji" not in data or "kaomoji" in data:
        if "kaomoji" in data:
            del data["kaomoji"]
        data["trigger.kaomoji"] = kaomoji_entry
        menu_file.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        os.system("omarchy-menu refresh >/dev/null 2>&1 &")

if __name__ == "__main__":
    ensure_menu_entry()
