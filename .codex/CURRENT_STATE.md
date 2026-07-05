# Current State

Current goal:
- Generate a concise observer-journal draft from a selected day's flomo memos.

Done condition:
- Met: a manual command reads flomo through MCP and writes exactly one validated observer journal under `AI_Review/`, without changing `Daily_Note` or Wiki files.

Last verified:
- Vault backup pushed to `origin/codex/backup-pre-flomo-20260705` at commit `aaa0c91`.
- flomo MCP token configured through `FLOMO_MCP_TOKEN`.
- 2026-07-05 produced a 1,793-character observer journal from two memos, with three mines and one optional CBT follow-up flag.
- The generated frontmatter points to `Daily_Note/2026/2026.07.05.md`, but promotion still requires explicit approval.
- Daily Wiki suggestions are disabled; durable Wiki extraction is reserved for a weekly pass.

Next step:
- Collect user feedback on the observer-journal voice, then implement reviewed promotion and weekly Wiki extraction.

Known risks:
- flomo OAuth currently fails across its login domains; token authentication is used instead.
- The target `Daily_Note` merge behavior is not implemented yet, so promotion must remain a separate reviewed action.
- User-level plugin/MCP startup warnings make Codex output noisy but did not affect the verified bridge run.

Useful commands:
- `codex mcp get flomo`
- `powershell -ExecutionPolicy Bypass -File scripts/run-daily.ps1 -Date 2026-07-05`
