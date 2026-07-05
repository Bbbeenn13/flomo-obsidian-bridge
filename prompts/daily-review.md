# 任务：生成 {{DATE}} 的 flomo 日状态报告

你正在执行一个严格受限的 flomo → Obsidian 待审核流程。

## 本次参数

- 日期：`{{DATE}}`
- 时区：`{{TIMEZONE}}`
- flomo 检索起点：`{{START_TIME}}`
- flomo 检索终点：`{{END_TIME}}`（不包含）
- Obsidian Vault：`{{VAULT_PATH}}`
- Codex 唯一允许写入的临时文件：`{{TEMP_OUTPUT_PATH}}`
- 审核区最终目标（仅供说明，由外层脚本复制）：`{{REVIEW_DESTINATION}}`
- 参考近期日记数量：`{{RECENT_DAILY_NOTES}}`
- Wiki 建议上限：`{{MAX_WIKI_SUGGESTIONS}}`

## 强制边界

1. flomo 只读：只允许调用 `memo_search` 和 `memo_batch_get`，不得创建、更新或删除 memo，不得修改标签。
2. Vault 完全只读。你只能写入项目内部的 `{{TEMP_OUTPUT_PATH}}`。
3. 不得修改 `Daily_Note/`、`Thinking_Lab/`、`0_System_initial/`、`Wiki/`、`.obsidian/` 或 `.git/`。
4. 输出是待审核草稿，不得把推断写成事实，不得进行医学或心理诊断。
5. 只链接确实存在的 Obsidian 页面，不得虚构 `[[Wiki Link]]`。
6. 如果信息不足，明确写“信息不足”，不要补全用户未表达的动机。

## 执行步骤

1. 用 flomo MCP 检索 `[{{START_TIME}}, {{END_TIME}})` 内的全部 memo；如有分页，继续读取直到该时间段没有遗漏。
2. 对搜索结果调用 `memo_batch_get`，取得完整正文、创建时间、标签和 memo ID。
3. 只读检查以下 Vault 上下文：
   - `CLAUDE.md`
   - `Wiki/index.md`
   - 最近 `{{RECENT_DAILY_NOTES}}` 篇 `Daily_Note` 日记
   - 与当日内容直接相关的少量现有 Wiki 页面
4. 先依据当日内容自然聚类，最多 4 类。不要机械地按“工作/生活”分割，也不要为了完整而制造类别。
5. 形成状态报表：描述当日显性状态、触发场景、反复行为、可能原因、反证或不确定性。
6. 识别与历史记录的连续、变化或矛盾，只在有原文证据时建立连接。
7. 给出最多 `{{MAX_WIKI_SUGGESTIONS}}` 条 Wiki 建议，标明 `强化 / 挑战 / 新候选 / 暂不沉淀` 与置信度。单日单源原则上不得高于 0.6。
8. 将完整结果写入 `{{TEMP_OUTPUT_PATH}}`。如果当天没有 memo，仍生成一份简短文件，只说明“当日无 flomo 素材”，不要分析状态。
9. 写入后重新读取临时文件，确认格式完整。不得尝试写入 `{{REVIEW_DESTINATION}}`；外层脚本会在校验后复制。

## 输出结构

```markdown
---
type: ai_daily_review
date: {{DATE}}
source: flomo
review_status: pending
memo_count: 0
memo_ids: []
generated_by: codex
---

# {{DATE}} 状态报告（待审核）

> 本文由 AI 根据当日 flomo 闪念和既有 Vault 上下文生成。观察与推断已分开，审核前不会进入正式日记或 Wiki。

## 今日状态总览

## 闪念脉络
<!-- 最多 4 个自然形成的类别 -->

## 状态复盘
<!-- 场景 → 可观察反应 → 可能影响 -->

## 背后原因假设
<!-- 每条包含：证据、假设、置信度、反证或不确定性 -->

## 与历史轨迹的连接
<!-- 只链接真实存在的日记或 Wiki 页面 -->

## Wiki 沉淀建议
<!-- 强化 / 挑战 / 新候选 / 暂不沉淀；不直接修改 Wiki -->

## 可继续追问的问题

## 原始闪念
<!-- 按时间完整保留：时间、memo ID、标签、正文 -->

## 人工审核

- [ ] 原始闪念完整
- [ ] 状态描述符合当天感受
- [ ] 原因推断有证据且不过度解释
- [ ] 接受日记草稿
- [ ] 接受 Wiki 建议
```

完成后仅用一句话报告临时文件路径、memo 数量和 Wiki 建议数量。
