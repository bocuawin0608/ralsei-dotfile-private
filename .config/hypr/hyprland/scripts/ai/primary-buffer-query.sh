#!/usr/bin/env bash
# primary-buffer-query.sh — AI summary for selected text (primary clipboard)
# Bound to: SUPER + SHIFT + ALT + RightClick
# Runs entirely in background — never blocks the compositor
set -euo pipefail

# ── Get selected text ──────────────────────────────────────────────────────────
TEXT=""
if command -v wl-paste >/dev/null 2>&1; then
    TEXT="$(wl-paste --primary --no-newline 2>/dev/null)" || TEXT=""
elif command -v xclip >/dev/null 2>&1; then
    TEXT="$(xclip -selection primary -o 2>/dev/null)" || TEXT=""
elif command -v xsel >/dev/null 2>&1; then
    TEXT="$(xsel --primary --output 2>/dev/null)" || TEXT=""
fi

TEXT="$(printf '%s' "$TEXT" | head -c 4000 | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"

if [[ -z "$TEXT" ]]; then
    notify-send "AI Query" "Nothing selected in primary clipboard." \
        -a "ai-query" -t 3000 -u low 2>/dev/null || true
    exit 0
fi

notify-send "AI Query" "Querying AI…" -a "ai-query" -t 2000 -u low 2>/dev/null || true

PROMPT="Briefly summarize or explain the following text in 2-3 sentences:\n\n${TEXT}"
RESULT=""

# ── Query Ollama (local) ───────────────────────────────────────────────────────
query_ollama() {
    local base_url="${OLLAMA_HOST:-http://localhost:11434}"
    local model="${OLLAMA_MODEL:-llama3}"

    if ! command -v curl >/dev/null 2>&1; then return 1; fi

    # Check if ollama is reachable
    curl -sf --max-time 2 "${base_url}/api/tags" >/dev/null 2>&1 || return 1

    local payload
    payload="$(printf '{"model":"%s","prompt":"%s","stream":false}' \
        "$model" \
        "$(printf '%s' "$PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')")"

    local response
    response="$(curl -sf --max-time 30 \
        -X POST "${base_url}/api/generate" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>/dev/null)" || return 1

    printf '%s' "$response" | grep -o '"response":"[^"]*"' | head -1 \
        | sed 's/"response":"//; s/"$//' \
        | sed 's/\\n/\n/g; s/\\t/\t/g'
}

# ── Query Gemini API ───────────────────────────────────────────────────────────
query_gemini() {
    if [[ -z "${GEMINI_API_KEY:-}" ]]; then return 1; fi
    if ! command -v curl >/dev/null 2>&1; then return 1; fi

    local model="${GEMINI_MODEL:-gemini-1.5-flash-latest}"
    local url="https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}"

    local escaped_prompt
    escaped_prompt="$(printf '%s' "$PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')"
    local payload="{\"contents\":[{\"parts\":[{\"text\":\"${escaped_prompt}\"}]}]}"

    local response
    response="$(curl -sf --max-time 30 \
        -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>/dev/null)" || return 1

    printf '%s' "$response" | grep -o '"text":"[^"]*"' | head -1 \
        | sed 's/"text":"//; s/"$//' \
        | sed 's/\\n/\n/g; s/\\t/\t/g'
}

# ── Try backends ───────────────────────────────────────────────────────────────
if command -v ollama >/dev/null 2>&1 || curl -sf --max-time 1 "${OLLAMA_HOST:-http://localhost:11434}/api/tags" >/dev/null 2>&1; then
    RESULT="$(query_ollama)" || RESULT=""
fi

if [[ -z "$RESULT" ]] && [[ -n "${GEMINI_API_KEY:-}" ]]; then
    RESULT="$(query_gemini)" || RESULT=""
fi

if [[ -z "$RESULT" ]]; then
    notify-send "AI Query" "No AI backend available.\nSet GEMINI_API_KEY or run ollama." \
        -a "ai-query" -t 5000 -u normal 2>/dev/null || true
    exit 0
fi

# ── Show result ────────────────────────────────────────────────────────────────
# Truncate for notification (notify-send has body length limits)
DISPLAY_RESULT="$(printf '%s' "$RESULT" | head -c 600)"
[[ ${#RESULT} -gt 600 ]] && DISPLAY_RESULT="${DISPLAY_RESULT}…"

notify-send "AI Summary" "$DISPLAY_RESULT" \
    -a "ai-query" -t 12000 -u normal 2>/dev/null || true

# Copy full result to clipboard
if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$RESULT" | wl-copy 2>/dev/null || true
fi
