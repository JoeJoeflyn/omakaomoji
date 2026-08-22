# 🌸 Kaomoji (`omakaomoji`)

A fast, lightweight, and native Japanese Kaomoji & Emoticon picker for **[Omarchy](https://omarchy.org)**.

`¯\_(ツ)_/¯` `(｡♥‿♥｡)` `(╯°□°）╯︵ ┻━┻` `ʕっ•ᴥ•ʔっ` `( ͡° ͜ʖ ͡°)`

---

## ✨ Features

* **⚡ 0ms In-Memory Search**: Embedded JavaScript search engine with zero process spawning overhead.
* **🔍 Fuzzy Subsequence Matching**: Type shorthand abbreviations (e.g. `tbl` $\rightarrow$ `(╯°□°）╯︵ ┻━┻` `TableFlip`, `shrg` $\rightarrow$ `¯\_(ツ)_/¯`).
* **🔠 Multi-Keyword Matching**: Narrow down expressions with space-separated terms (e.g. `bear hug` $\rightarrow$ `ʕっ•ᴥ•ʔっ`, `sad cry` $\rightarrow$ `(╥﹏╥)`).
* **🏷️ Category Quick Filters**: Interactive pill tabs for `Happy`, `Love`, `Bear`, `Cat`, `TableFlip`, `Shrug`, `Cool`, `Wave`, `Sad`, `Angry`, and `Music`.
* **↵ Auto-Paste & Copy**: Selecting a kaomoji automatically types it straight into your active application/chat via `wtype` and copies it to clipboard (`wl-copy`).
* **🎨 100% Native Omarchy Theme Integration**: Uses Omarchy's menu color tokens and surface borders — automatically matches Turbonite, Catppuccin, Nord, Everforest, Tokyo Night, and custom themes.
* **⌨️ Keyboard-First Control**: Smooth arrow navigation (`↑` `↓` `←` `→`), `PageUp`/`PageDown`, `Enter` to insert, and `Esc` to clear/dismiss.

---

## 📦 Installation

Install directly with the Omarchy plugin manager:

```bash
omarchy plugin add https://github.com/JoeJoeflyn/omakaomoji.git --enable
```

---

## ⌨️ Hyprland Keybinding

Add this to your `~/.config/hypr/hyprland.conf` to summon the kaomoji picker with a hotkey (e.g. `Super + Alt + K`):

```ini
bind = SUPER ALT, K, exec, omarchy-shell shell toggle omakaomoji
```

---

## 🚀 Omarchy Menu Integration (`Super + Space`)

To make Kaomoji searchable in your Omarchy application menu (`Super + Space`), add this to `~/.config/omarchy/extensions/omarchy-menu.jsonc`:

```jsonc
{
  "kaomoji": {
    "icon": "ツ",
    "label": "Kaomoji",
    "aliases": ["kaomoji", "emoticon", "facemoji", "ascii", "face"],
    "action": "omarchy-shell shell toggle omakaomoji",
    "description": "Japanese text faces & emoticons — (◕‿◕)"
  }
}
```

---

## 📜 License

[MIT License](LICENSE) © 2026 JoeJoeflyn
