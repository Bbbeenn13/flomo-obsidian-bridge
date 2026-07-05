# Current State

Current goal:
- Generate one review-only Obsidian Markdown packet from a selected day's flomo memos.

Done condition:
- Met: a manual command reads flomo through MCP and writes exactly one validated file under `AI_Review/`, without changing Raw or Wiki files.

Last verified:
- Vault backup pushed to `origin/codex/backup-pre-flomo-20260705` at commit `aaa0c91`.
- flomo MCP token configured through `FLOMO_MCP_TOKEN`.
- 2026-07-05 produced one-memo review report; all 9 Obsidian links resolve and rerun output is byte-identical.

Next step:
- Collect user feedback on report structure, then implement scheduling and an explicit reviewed-promotion workflow.

Known risks:
- flomo OAuth currently fails across its login domains; token authentication is used instead.
- The Vault currently follows a strict Raw → Wiki schema, so promotion must remain a separate reviewed action.
- User-level plugin/MCP startup warnings make Codex output noisy but did not affect the verified bridge run.

Useful commands:
- `codex mcp get flomo`
- `powershell -ExecutionPolicy Bypass -File scripts/run-daily.ps1 -Date 2026-07-05`
