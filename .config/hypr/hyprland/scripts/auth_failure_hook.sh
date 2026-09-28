#!/usr/bin/env bash
# auth_failure_hook.sh — PAM authentication failure counter
# Called by hyprlock/PAM after an authentication failure
# After 3 failures, signals Quickshell to trigger lockout UI
set -euo pipefail

COUNTER_FILE="/tmp/auth_fail_count"
MAX_FAILURES=3
QS_CONFIG="${QS_CONFIG:-default}"

# ── Read current count ─────────────────────────────────────────────────────────
if [[ -f "$COUNTER_FILE" ]]; then
    COUNT="$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)"
    # Validate it's a number
    [[ "$COUNT" =~ ^[0-9]+$ ]] || COUNT=0
else
    COUNT=0
fi

COUNT=$(( COUNT + 1 ))
printf '%d' "$COUNT" > "$COUNTER_FILE"

# ── Trigger lockout after threshold ───────────────────────────────────────────
if (( COUNT >= MAX_FAILURES )); then
    # Signal Quickshell security lockout
    qs -c "${QS_CONFIG}" ipc call "security:authFailureLockout" 2>/dev/null || true

    # Also notify via notify-send as a fallback
    notify-send "Security" \
        "Authentication failed ${COUNT} times. Lockout triggered." \
        -u critical -a "auth" 2>/dev/null || true

    # Reset counter so next login attempt cycle starts fresh
    rm -f "$COUNTER_FILE"
fi
