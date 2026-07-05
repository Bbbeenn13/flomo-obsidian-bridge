# Current State

Current goal:
- Generate one compact CBT action card from a selected day's flomo memos.

Done condition:
- Met: a manual command reads flomo through MCP and writes exactly one validated file under `AI_Review/`, without changing Raw or Wiki files.

Last verified:
- Vault backup pushed to `origin/codex/backup-pre-flomo-20260705` at commit `aaa0c91`.
- flomo MCP token configured through `FLOMO_MCP_TOKEN`.
- 2026-07-05 produced one-memo review report; all 9 Obsidian links resolve and rerun output is byte-identical.
- The revised 2026-07-05 report is 1,422 characters and contains one 24-hour behavioral experiment instead of a long narrative analysis.

Next step:
- Collect user feedback on CBT chain accuracy and action intensity, then implement scheduling and reviewed promotion.

Known risks:
- flomo OAuth currently fails across its login domains; token authentication is used instead.
- The Vault currently follows a strict Raw → Wiki schema, so promotion must remain a separate reviewed action.
- User-level plugin/MCP startup warnings make Codex output noisy but did not affect the verified bridge run.

Useful commands:
- `codex mcp get flomo`
- `powershell -ExecutionPolicy Bypass -File scripts/run-daily.ps1 -Date 2026-07-05`
