#!/usr/bin/env bash
# fuzzel-emoji.sh — Fuzzel emoji picker
# Usage: fuzzel-emoji.sh [copy|type]
#   copy  (default) — copy selected emoji to clipboard via wl-copy
#   type             — type via ydotool
set -euo pipefail

ACTION="${1:-copy}"
EMOJI_CACHE="${HOME}/.cache/emoji-list.txt"

notify_msg() {
    notify-send "Emoji" "$1" -a "fuzzel-emoji" -t 2000 2>/dev/null || true
}

# ── Build emoji list ───────────────────────────────────────────────────────────
build_emoji_list() {
    mkdir -p "$(dirname "$EMOJI_CACHE")"

    # Prefer system emoji data
    local data_paths=(
        "/usr/share/unicode/emoji/emoji-test.txt"
        "/usr/share/misc/emoji-test.txt"
    )
    for f in "${data_paths[@]}"; do
        if [[ -f "$f" ]]; then
            # Format: EMOJI  NAME
            grep -E '^[0-9A-F].*; fully-qualified' "$f" \
                | sed 's/.*# \([^ ]*\) E[0-9.]* /\1 /' \
                > "$EMOJI_CACHE"
            return
        fi
    done

    # Fallback: embed a small curated list so the picker always works
    cat > "$EMOJI_CACHE" <<'EMOJIS'
😀 Grinning Face
😂 Face with Tears of Joy
🥹 Face Holding Back Tears
😍 Smiling Face with Heart-Eyes
🤔 Thinking Face
😎 Smiling Face with Sunglasses
😭 Loudly Crying Face
🥺 Pleading Face
😅 Grinning Face with Sweat
🙃 Upside-Down Face
😡 Angry Face
🤩 Star-Struck
🥳 Partying Face
😴 Sleeping Face
🤯 Exploding Head
👍 Thumbs Up
👎 Thumbs Down
👋 Waving Hand
🤝 Handshake
🙌 Raising Hands
👀 Eyes
❤️ Red Heart
🧡 Orange Heart
💛 Yellow Heart
💚 Green Heart
💙 Blue Heart
💜 Purple Heart
🖤 Black Heart
🤍 White Heart
💔 Broken Heart
🌟 Glowing Star
⭐ Star
✨ Sparkles
🔥 Fire
💧 Droplet
🌊 Water Wave
🍀 Four Leaf Clover
🌸 Cherry Blossom
🌻 Sunflower
🦋 Butterfly
🐱 Cat Face
🐶 Dog Face
🐰 Rabbit Face
🦊 Fox
🐼 Panda
🐸 Frog
🦄 Unicorn
🐉 Dragon
🍕 Pizza
🍣 Sushi
🍜 Steaming Bowl
🎮 Video Game
🎵 Musical Note
🎶 Musical Notes
📱 Mobile Phone
💻 Laptop
🖥️ Desktop Computer
📷 Camera
🎨 Artist Palette
📚 Books
🏠 House
🚀 Rocket
✅ Check Mark Button
❌ Cross Mark
⚠️ Warning
🔔 Bell
🔕 Bell with Slash
EMOJIS
}

# ── Regenerate cache if stale (>7 days) or missing ────────────────────────────
if [[ ! -f "$EMOJI_CACHE" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$EMOJI_CACHE" 2>/dev/null || echo 0) )) -gt 604800 ]]; then
    build_emoji_list
fi

# ── Show picker ────────────────────────────────────────────────────────────────
if ! command -v fuzzel >/dev/null 2>&1; then
    notify_msg "fuzzel not found"
    exit 1
fi

SELECTED="$(fuzzel \
    --dmenu \
    --prompt='Emoji: ' \
    --match-mode=fzf \
    --lines=15 \
    --width=40 \
    --font='Noto Color Emoji:size=14' \
    < "$EMOJI_CACHE" 2>/dev/null)" || exit 0

[[ -z "$SELECTED" ]] && exit 0

# Extract just the emoji glyph (first field)
EMOJI="$(printf '%s' "$SELECTED" | awk '{print $1}')"
[[ -z "$EMOJI" ]] && exit 0

case "$ACTION" in
    type)
        if command -v ydotool >/dev/null 2>&1; then
            ydotool type "$EMOJI"
        else
            notify_msg "ydotool not found; falling back to clipboard"
            printf '%s' "$EMOJI" | wl-copy
        fi
        ;;
    copy|*)
        if command -v wl-copy >/dev/null 2>&1; then
            printf '%s' "$EMOJI" | wl-copy
            notify_msg "Copied: $EMOJI"
        else
            notify_msg "wl-copy not found"
            exit 1
        fi
        ;;
esac
