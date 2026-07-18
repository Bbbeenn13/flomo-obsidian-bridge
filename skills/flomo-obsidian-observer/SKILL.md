---
name: flomo-obsidian-observer
description: Run and maintain the user's flomo to Obsidian observer-journal workflow. Use when Codex needs to generate a daily flomo observer review, approve a reviewed draft into an Obsidian Daily Note, inspect or trigger GitHub Actions for the flomo-obsidian bridge, preserve the relaxed Codex-authored diary style, or help operate the workflow from desktop or mobile Codex.
---

# Flomo Obsidian Observer

Use this skill to operate the flomo → Obsidian bridge without changing its journal voice or safety boundaries.

## Core contract

- Treat flomo as read-only source material.
- Generate daily drafts only under `AI_Review/YYYY/YYYY.MM.DD_待审核.md`.
- Promote to `Daily_Note/YYYY/YYYY.MM.DD_Codex.md` only after explicit approval.
- Preserve the relaxed sections: `今天的我`, `值得留下的矿`, `还没想完的地方`, `带到明天`, optional `可以另行拆解的卡点`, and `素材索引`.
- Keep CBT as an optional follow-up flag, not the default daily frame.
- Do not write Wiki pages during daily generation. Weekly extraction is a separate future workflow.
- Do not expose or commit `FLOMO_MCP_TOKEN`, `OPENAI_API_KEY`, Codex auth files, or GitHub tokens.

## Local commands

From the bridge repo:

```powershell
.\scripts\run-daily.ps1 -Date "YYYY-MM-DD"
.\scripts\approve-daily.ps1 -Date "YYYY-MM-DD" -Approve
```

Use these only for local testing or manual recovery.

## GitHub Actions commands

Use the GitHub workflows when the user wants cloud/mobile control:

```bash
gh workflow run daily-review.yml -f date=YYYY-MM-DD
gh workflow run approve-daily.yml -f date=YYYY-MM-DD
```

If no date is supplied to `daily-review.yml`, it uses today's `Asia/Shanghai` date. Approval always requires an explicit date.

Required repository secrets in the bridge repo:

- `FLOMO_MCP_TOKEN`: flomo MCP bearer token.
- `OPENAI_API_KEY`: OpenAI Platform API key for non-interactive Codex CLI login in GitHub Actions.
- `VAULT_REPO_TOKEN`: GitHub token that can read and write `Bbbeenn13/notes-vault`.

## Review before approving

Before running approval, inspect the pending review in the Vault repository:

```text
AI_Review/YYYY/YYYY.MM.DD_待审核.md
```

Approve only if the user has explicitly said to approve that date. The approval workflow renames the review to `_已审核` and writes the `_Codex` Daily Note.

## Mobile Codex control

When the user asks from mobile to run the system, prefer GitHub Actions dispatch:

- Generate or rerun a daily draft: trigger `daily-review.yml`.
- Approve a reviewed date: trigger `approve-daily.yml` only after explicit approval.
- Check status: inspect the latest workflow run and the Vault diff/commit.

If GitHub Actions fails, report the failing step and likely missing secret or auth issue first.
