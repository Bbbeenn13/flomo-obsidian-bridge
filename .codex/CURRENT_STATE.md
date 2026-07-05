# Current State

Current goal:
- Generate, review, and explicitly promote an observer-journal draft from a selected day's flomo memos.

Done condition:
- Met: generation writes only to `AI_Review/`; a separate command requires explicit approval before creating or appending `Daily_Note/`.

Last verified:
- Vault backup pushed to `origin/codex/backup-pre-flomo-20260705` at commit `aaa0c91`.
- flomo MCP token configured through `FLOMO_MCP_TOKEN`.
- 2026-07-05 produced a 1,793-character observer journal from two memos, with three mines and one optional CBT follow-up flag.
- The generated frontmatter points to `Daily_Note/2026/2026.07.05.md`, but promotion still requires explicit approval.
- Daily Wiki suggestions are disabled; durable Wiki extraction is reserved for a weekly pass.
- The 2026-07-05 review was approved and promoted with an idempotency marker; its CBT follow-up remains pending under `AI_Review/CBT/`.

Next step:
- Collect user feedback on the pending CBT card, then implement weekly Wiki extraction.

Known risks:
- flomo OAuth currently fails across its login domains; token authentication is used instead.
- Approval intentionally requires a clean Vault worktree so unrelated user changes cannot be included accidentally.
- User-level plugin/MCP startup warnings make Codex output noisy but did not affect the verified bridge run.

Useful commands:
- `codex mcp get flomo`
- `powershell -ExecutionPolicy Bypass -File scripts/run-daily.ps1 -Date 2026-07-05`
- `powershell -ExecutionPolicy Bypass -File scripts/approve-daily.ps1 -Date 2026-07-05 -Approve`
