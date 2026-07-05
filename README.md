# Flomo → Obsidian Bridge

每天通过 flomo 官方 MCP 读取指定日期的闪念，让 Codex 结合现有 Obsidian 日记与 LLM Wiki，生成一篇待审核的“旁观者日记”草稿。

## 数据边界

```text
flomo（只读）
  → Codex 分析
  → Vault/AI_Review/YYYY/YYYY.MM.DD.md
  → 人工审核
  → 显式批准后写入 Daily_Note
  → 每周再决定是否写入 Wiki
```

日常生成阶段不会修改 Vault 的 `Daily_Note/`、`Thinking_Lab/`、`Wiki/` 或系统目录，也不会向 flomo 写入内容。只有用户明确批准后，审批脚本才会创建或追加当天 `Daily_Note`，并用日期标记阻止重复写入。

日记默认回答：今天的我处在什么状态、不同闪念背后有什么共同线索、哪些内容值得作为长期复盘的“矿”。它不强制量化或布置行动；遇到明确卡点时，只提示是否值得另开一次 CBT 拆解。

审核通过后，日记目标路径记录在 frontmatter 的 `approved_destination` 中；正式写入 `Daily_Note` 仍需要显式批准。Wiki 不按日更新，改为每周集中提炼。

若日记标记了 `cbt_followup: suggested`，CBT 拆解单独存放在 `AI_Review/CBT/`，不会自动进入正式日记或 `Thinking_Lab/`。

## 技术选择

- Codex CLI：负责读取 flomo MCP、理解 Vault 上下文并生成 Markdown。
- PowerShell：负责日期、配置、安全校验、调用 Codex，并把校验后的单个草稿复制到审核区。
- Windows 任务计划程序：验证稳定后再接入。
- Mac 迁移时保留同一提示词，仅替换调度脚本。

不引入数据库、Web 服务或自建 MCP 服务。

## 认证

flomo Token 存储在用户环境变量 `FLOMO_MCP_TOKEN` 中，不写入仓库。Codex MCP 配置只记录环境变量名。

## 当前阶段

人工触发的每日待审核报告已经可用：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-daily.ps1 -Date 2026-07-05
```

先检查日期、路径和最终提示词但不调用 Codex：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-daily.ps1 -Date 2026-07-05 -DryRun
```

明确审核通过后写入当天日记：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\approve-daily.ps1 -Date 2026-07-05 -Approve
```

定时调度与每周 Wiki 提炼属于后续阶段。
