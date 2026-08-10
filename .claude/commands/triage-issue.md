---
description: Triage a GitHub issue - apply labels and post a code-grounded diagnosis
---

You are triaging a GitHub issue for a vanilla JavaScript Tetris game (Canvas-based, no build step, no dependencies). Your job is to **analyze only** — do not write code, do not open a pull request, do not push commits.

## Arguments

The caller passes `REPO:` and `ISSUE_NUMBER:` in `$ARGUMENTS`. Parse them from there.

## Steps

1. **Read the issue.**
   `gh issue view $ISSUE_NUMBER --repo $REPO --json title,body,comments`

2. **Read the actual code before forming an opinion.** Use `Grep`/`Read` on `game.js`, `index.html`, and `style.css` to locate the exact function, variable, or line the issue is describing. Do not guess from the title alone.

3. **Choose labels** from the existing taxonomy (do not invent new ones):
   - Exactly one `type:` — `type:bug`, `type:feature`, `type:docs`, `type:refactor`, `type:question`
   - One or more `area:` — `area:gameplay`, `area:rendering`, `area:controls`, `area:scoring`, `area:ui`, `area:docs`, `area:ci`
   - Exactly one `priority:` — `priority:P1` (critical, blocks play), `priority:P2` (should fix soon), `priority:P3` (minor)
   - `needs-info` instead of a priority when the issue lacks enough detail to diagnose

   Area reference (`game.js`):
   - `area:gameplay` → `collide`, `tryRotate`, `spawn`, `lockPiece`, `clearLines`, `hardDrop`/`softDrop`
   - `area:rendering` → `draw`, `drawBlock`, `drawGrid`, `drawNext`, `COLORS`
   - `area:controls` → the `keydown` listener
   - `area:scoring` → `LINE_SCORES`, `level`, `updateHUD`
   - `area:ui` → `index.html`, `style.css`, overlay elements
   - `area:docs` / `area:ci` → `README.md`, `.github/workflows`

4. **Write the diagnosis in Spanish** (the whole project — README, UI copy, issues — is in Spanish), formatted as **GitHub-flavored Markdown** — it's posted as an issue comment and must render correctly (headings with `##`, `**bold**`, `` `inline code` `` for identifiers, fenced code blocks for snippets, `-` for lists). No raw/plain text. Structure:
   - **Síntoma**: one line restating the problem
   - **Ubicación**: file + line + function
   - **Causa probable**: grounded in the code you actually read, not speculation
   - **Enfoque sugerido**: a short pointer for the eventual fix, not a diff
   - **Riesgos**: anything the fix should be careful about

   If the issue doesn't have enough information to point to a real cause, do **not** invent one. Use the `needs-info` label instead of a priority, and list the specific open questions you'd need answered.

5. **Apply the result with the script — this is the only step that writes anything.**
   ```
   ./scripts/triage-issue.sh --repo $REPO --issue $ISSUE_NUMBER \
     --labels "type:bug,area:rendering,priority:P3" \
     --body-file <path to a temp file with your diagnosis>
   ```
   Write your diagnosis to a temp file first, then pass its path. Never call `gh issue edit` or `gh issue comment` directly — the script handles label validation and keeps the diagnosis to a single, updatable comment across repeated edits.
