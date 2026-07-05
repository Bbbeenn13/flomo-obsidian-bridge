# Build Log

## 2026-07-05 - Project boundary and recovery baseline

Context:
- Build a daily flomo-to-Obsidian workflow without allowing AI to edit established notes directly.

Change:
- Defined the staging-only architecture, tracked configuration, security boundary, and durable project instructions.
- flomo MCP uses a user-level token environment variable; no secret is stored in this repository.

Verification:
- Configuration and repository paths were inspected manually.

Next:
- Implement and verify the manual daily runner.

## 2026-07-05 - Manual daily runner

Context:
- The first usable slice needs to fetch one day's memos while preventing direct writes to Raw and Wiki.

Change:
- Added a read-only flomo MCP allowlist, deterministic daily prompt contract, and PowerShell runner.
- The runner grants Codex write access only to `AI_Review/` and verifies that no other review file changed.

Verification:
- Dry run rendered all parameters successfully.
- First real run made no Vault changes; it exposed that non-interactive MCP approvals must be explicit.

Next:
- Re-run with only the two read-only flomo tools enabled and pre-approved.

## 2026-07-05 - Two-stage Vault write isolation

Context:
- Codex could read flomo and Vault context, but the Windows sandbox rejected direct writes to the external Vault.

Change:
- Codex now writes only to the project-local `.runs/` directory.
- The trusted runner validates required Markdown markers before copying one file to `AI_Review/`.

Verification:
- The failed direct-write run created no Vault file and found one memo for 2026-07-05.
- The two-stage run generated and validated a 12 KB report, then copied only `AI_Review/2026/2026.07.05.md`.
- PowerShell syntax passed; 9 Obsidian links resolved; repeated publication produced the same SHA-256 hash.

Next:
- Review the first report with the user before implementing scheduled runs or promotion into Raw/Wiki.

## 2026-07-05 - Compact CBT action card

Context:
- The first report was too long and kept attention on interpretation instead of action.

Change:
- Replaced the narrative report with a CBT chain: situation, automatic thought, emotion/behavior, evidence check, balanced thought, and one behavioral experiment.
- Limited output to 2,000 characters, one Wiki signal, two source excerpts, and one real-world action within 24 hours.

Verification:
- Regenerated 2026-07-05 as a 1,422-character card with a 90-second imperfect presentation exercise.

Next:
- Ask the user to assess whether the CBT chain and action intensity feel accurate.

## 2026-07-05 - Observer journal draft

Context:
- The CBT card was too clinical and action-heavy for the daily artifact; the user wants a durable account of who they were that day and what may be worth revisiting.

Change:
- Replaced the default CBT card with a first-person observer journal containing a daily narrative, one to three mines, an unresolved tension, and one gentle carry-forward sentence.
- Removed daily Wiki proposals and reserved them for a future weekly extraction pass.
- Kept CBT as an optional follow-up flag only when a concrete event, automatic thought, and avoidance loop appear together.
- Added an explicit `Daily_Note` destination while preserving approval-gated promotion.

Verification:
- PowerShell syntax, JSON parsing, prompt rendering, and `git diff --check` passed.
- The 2026-07-05 run read two memos and produced a 1,793-character observer journal with three mines and `cbt_followup: suggested`.
- Only `AI_Review/2026/2026.07.05.md` changed in the Vault; no `Daily_Note` or Wiki file was written.

Next:
- Let the user review the journal voice, then implement explicit approval-based promotion and weekly Wiki extraction.
