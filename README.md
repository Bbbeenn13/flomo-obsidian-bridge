# Flomo → Obsidian Bridge

每天通过 flomo 官方 MCP 读取指定日期的闪念，让 Codex 结合现有 Obsidian 日记与 LLM Wiki，生成一张简短的待审核 CBT 行动卡。

## 数据边界

```text
flomo（只读）
  → Codex 分析
  → Vault/AI_Review/YYYY/YYYY.MM.DD.md
  → 人工审核
  → 后续再决定是否写入 Daily_Note 与 Wiki
```

首版不会修改 Vault 的 `Daily_Note/`、`Thinking_Lab/`、`Wiki/` 或系统目录，也不会向 flomo 写入内容。

行动卡采用“情境 → 自动想法 → 情绪/行为 → 证据校准 → 行为实验”结构。它用于自助反思，不替代专业心理治疗，也不会根据单日笔记下诊断或断言深层信念。

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

定时调度和审核后正式入库属于后续阶段。
