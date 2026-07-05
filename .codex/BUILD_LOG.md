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
