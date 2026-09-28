#!/usr/bin/env bash
# random_wallpaper.sh — Pick a random wallpaper and apply it via switchwall.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec bash "${SCRIPT_DIR}/switchwall.sh" --random
