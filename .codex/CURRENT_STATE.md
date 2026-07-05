# Current State

Current goal:
- Generate one review-only Obsidian Markdown packet from a selected day's flomo memos.

Done condition:
- A manual command reads flomo through MCP and writes exactly one file under `AI_Review/`, without changing Raw or Wiki files.

Last verified:
- Vault backup pushed to `origin/codex/backup-pre-flomo-20260705` at commit `aaa0c91`.
- flomo MCP token configured through `FLOMO_MCP_TOKEN`.

Next step:
- Add the prompt contract and PowerShell runner, then test against a selected date.

Known risks:
- flomo OAuth currently fails across its login domains; token authentication is used instead.
- The Vault currently follows a strict Raw → Wiki schema, so promotion must remain a separate reviewed action.

Useful commands:
- `codex mcp get flomo`
- `pwsh -File scripts/run-daily.ps1 -Date 2026-07-05`
