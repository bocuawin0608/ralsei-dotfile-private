#!/usr/bin/env bash
# snip_to_search.sh — Capture screen region and open in Google Lens
set -euo pipefail

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
TMP_IMG="/tmp/lens_${TIMESTAMP}.png"

notify_msg() {
    notify-send "Snip to Search" "$1" -a "snip_to_search" -t 3000 2>/dev/null || true
}

# ── Dependency check ───────────────────────────────────────────────────────────
for dep in slurp grim; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        notify_msg "Missing dependency: $dep"
        printf 'ERROR: %s not found\n' "$dep" >&2
        exit 1
    fi
done

# ── Capture region (exit cleanly if user cancels) ─────────────────────────────
SLURP_ARGS="${SLURP_ARGS:-}"
REGION="$(slurp $SLURP_ARGS 2>/dev/null)" || {
    # slurp exits non-zero on Escape — treat as graceful cancel
    exit 0
}

[[ -z "$REGION" ]] && exit 0

grim -g "$REGION" "$TMP_IMG" || {
    notify_msg "Screenshot failed"
    exit 1
}

# ── Upload to Google Lens ─────────────────────────────────────────────────────
open_lens() {
    local img="$1"

    # Strategy 1: POST multipart upload to Google Lens
    if command -v curl >/dev/null 2>&1; then
        local UPLOAD_URL="https://lens.google.com/upload"
        local response
        response="$(curl -sL \
            -X POST \
            -F "encoded_image=@${img};type=image/png" \
            -F "image_content=" \
            -w '\n%{url_effective}' \
            -o /dev/null \
            "$UPLOAD_URL" 2>/dev/null)" || true

        local redirect_url
        redirect_url="$(printf '%s' "$response" | tail -n1)"
        if [[ "$redirect_url" == https://lens.google.com/* ]]; then
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$redirect_url"
                return 0
            fi
        fi
    fi

    # Strategy 2: Encode as data URI and open Lens with it
    if command -v base64 >/dev/null 2>&1; then
        local b64
        b64="$(base64 -w 0 < "$img")"
        local data_uri="data:image/png;base64,${b64}"
        # Save to a temporary HTML page that auto-submits to Lens
        local html_file="/tmp/lens_submit_${TIMESTAMP}.html"
        cat > "$html_file" <<HTML
<!DOCTYPE html>
<html>
<head><title>Lens Upload</title></head>
<body>
<form id="f" method="POST" enctype="multipart/form-data"
      action="https://lens.google.com/upload">
</form>
<script>
  // Fetch the temp image and submit
  fetch("file://${img}")
    .then(r=>r.blob())
    .then(b=>{
      const fd=new FormData();
      fd.append("encoded_image",b,"screenshot.png");
      return fetch("https://lens.google.com/upload",{method:"POST",body:fd});
    })
    .then(r=>{ window.location.href=r.url; })
    .catch(()=>{ window.location.href="https://lens.google.com"; });
</script>
</body>
</html>
HTML
        xdg-open "$html_file" 2>/dev/null || true
        return 0
    fi

    # Strategy 3: Fallback — just open Google Lens homepage
    notify_msg "Could not auto-upload. Opening Google Lens…"
    xdg-open "https://lens.google.com" 2>/dev/null || true
}

open_lens "$TMP_IMG"

# ── Cleanup after browser has time to read the file ──────────────────────────
(sleep 15 && rm -f "$TMP_IMG") &
disown
