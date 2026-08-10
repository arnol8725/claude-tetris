#!/usr/bin/env bash
# One-time (re-runnable) setup for the issue-triage label taxonomy.
# Uses `gh label create --force` so it's safe to run again after edits.
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI is required" >&2
  exit 1
fi

# name|color|description
LABELS=(
  "type:bug|d73a4a|Something isn't working"
  "type:feature|a2eeef|New feature or request"
  "type:docs|0075ca|Documentation only"
  "type:refactor|cfd3d7|Code change with no behavior change"
  "type:question|d876e3|Further information is requested"

  "area:gameplay|5319e7|collide, rotate, spawn, lockPiece, clearLines, drop"
  "area:rendering|1d76db|draw, drawBlock, drawGrid, drawNext, COLORS, canvas"
  "area:controls|0e8a16|keydown handler and key bindings"
  "area:scoring|fbca04|LINE_SCORES, level, HUD"
  "area:ui|c2e0c6|index.html, style.css, overlay"
  "area:docs|bfd4f2|README.md"
  "area:ci|f9d0c4|.github/workflows"

  "priority:P1|b60205|Critical, blocks play"
  "priority:P2|d93f0b|Should fix soon"
  "priority:P3|fef2c0|Minor, low urgency"

  "needs-info|e4e669|Missing information to diagnose"
)

for entry in "${LABELS[@]}"; do
  IFS='|' read -r name color description <<< "$entry"
  gh label create "$name" --color "$color" --description "$description" --force
done

echo "Done. $(printf '%s\n' "${LABELS[@]}" | wc -l | tr -d ' ') labels created/updated."
