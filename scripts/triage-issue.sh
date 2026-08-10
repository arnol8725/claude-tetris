#!/usr/bin/env bash
# Sole write path for automated issue triage: applies labels and posts (or
# updates) a single diagnosis comment on a GitHub issue. Deterministic on
# purpose — the LLM decides *what* to write, this script decides *how* it's
# applied, so idempotency doesn't depend on model behavior.
#
# Usage:
#   ./scripts/triage-issue.sh --repo <owner/repo> --issue <n> \
#                              --labels "type:bug,area:rendering,priority:P3" \
#                              --body-file <path>
set -euo pipefail

MARKER="<!-- claude-triage -->"

repo=""
issue=""
labels=""
body_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --issue) issue="$2"; shift 2 ;;
    --labels) labels="$2"; shift 2 ;;
    --body-file) body_file="$2"; shift 2 ;;
    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$repo" || -z "$issue" || -z "$labels" || -z "$body_file" ]]; then
  echo "error: --repo, --issue, --labels, and --body-file are all required" >&2
  exit 1
fi

if [[ ! -f "$body_file" ]]; then
  echo "error: body file not found: $body_file" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI is required" >&2
  exit 1
fi

# --- Validate labels exist before applying anything -----------------------
mapfile -t existing_labels < <(gh label list --repo "$repo" --limit 200 --json name --jq '.[].name')
IFS=',' read -ra requested_labels <<< "$labels"

for label in "${requested_labels[@]}"; do
  label_trimmed="$(echo "$label" | xargs)"
  found=0
  for existing in "${existing_labels[@]}"; do
    if [[ "$existing" == "$label_trimmed" ]]; then
      found=1
      break
    fi
  done
  if [[ "$found" -eq 0 ]]; then
    echo "error: label '$label_trimmed' does not exist in $repo (run scripts/setup-labels.sh)" >&2
    exit 1
  fi
done

# --- Apply labels (additive — never removes labels set by hand) -----------
add_label_args=()
for label in "${requested_labels[@]}"; do
  add_label_args+=(--add-label "$(echo "$label" | xargs)")
done
gh issue edit "$issue" --repo "$repo" "${add_label_args[@]}"

# --- Ensure the marker is present so the comment is identifiable later ----
tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT
if head -n1 "$body_file" | grep -qF "$MARKER"; then
  cp "$body_file" "$tmp_body"
else
  { echo "$MARKER"; cat "$body_file"; } > "$tmp_body"
fi

# --- Find an existing triage comment and edit it, or create a new one -----
existing_comment_id="$(
  gh api "repos/$repo/issues/$issue/comments" --paginate \
    --jq "[.[] | select(.body | startswith(\"$MARKER\"))][-1].id // empty"
)"

if [[ -n "$existing_comment_id" ]]; then
  gh api -X PATCH "repos/$repo/issues/comments/$existing_comment_id" \
    -f "body=@$tmp_body" >/dev/null
  echo "Updated existing triage comment ($existing_comment_id) on $repo#$issue."
else
  gh issue comment "$issue" --repo "$repo" --body-file "$tmp_body" >/dev/null
  echo "Posted new triage comment on $repo#$issue."
fi

echo "Labels applied: $labels"
