# Current State

Current goal:
- Generate, review, and explicitly promote observer-journal drafts from selected flomo memo days.

Done condition:
- Met: generation writes only non-empty memo days to `AI_Review/`; a separate command requires explicit approval before creating or appending `Daily_Note/`.

Last verified:
- Vault backup pushed to `origin/codex/backup-pre-flomo-20260705` at commit `aaa0c91`.
- flomo MCP token configured through `FLOMO_MCP_TOKEN`.
- 2026-07-05 produced a 1,793-character observer journal from two memos, with three mines and one optional CBT follow-up flag.
- The generated frontmatter points to `Daily_Note/2026/2026.07.05.md`, but promotion still requires explicit approval.
- Daily Wiki suggestions are disabled; durable Wiki extraction is reserved for a weekly pass.
- The 2026-07-05 review was approved and promoted with an idempotency marker; its CBT follow-up remains pending under `AI_Review/CBT/`.
- AI-authored daily notes use the `_Codex` filename suffix, carry up to five keywords, and preserve the complete relaxed journal structure.
- Review files now expose status in the filename: `YYYY.MM.DD_待审核.md` before approval and `YYYY.MM.DD_已审核.md` after approval.
- `memo_count: 0` generated packets are skipped and are not copied to `AI_Review/`.
- Current July review files: `2026.07.05_已审核.md`, plus pending `2026.07.06_待审核.md`, `2026.07.07_待审核.md`, and `2026.07.09_待审核.md`.

Next step:
- Review and approve the remaining pending July drafts when ready; add manual weekly review and Wiki extraction before scheduling automation.

Known risks:
- flomo OAuth currently fails across its login domains; token authentication is used instead.
- Approval allows pre-existing `AI_Review/` changes so multiple pending drafts can coexist, but still refuses pre-existing non-review Vault changes.
- User-level plugin/MCP startup warnings make Codex output noisy but did not affect the verified bridge run.
- Weekly/monthly indexes are not implemented yet.

Useful commands:
- `codex mcp get flomo`
- `powershell -ExecutionPolicy Bypass -File scripts/run-daily.ps1 -Date 2026-07-05`
- `powershell -ExecutionPolicy Bypass -File scripts/approve-daily.ps1 -Date 2026-07-05 -Approve`
