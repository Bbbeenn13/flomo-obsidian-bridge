# Flomo → Obsidian Bridge

## Safety boundary

- Treat the configured Obsidian vault as read-only from Codex. Only the trusted runner may copy one validated file into `AI_Review/`.
- Never modify `Daily_Note/`, `Thinking_Lab/`, `0_System_initial/`, `Wiki/`, `.obsidian/`, or `.git/` during a daily bridge run.
- Never create, update, or delete flomo memos. flomo is a read-only source for this project.
- If the date, vault path, source memo range, or intended output is unclear, stop with an explicit error instead of guessing.
- Never bulk-delete files or directories. A file may only be deleted when its exact path is explicitly approved.

## Output contract

- Codex may create exactly one generated Markdown file under the project's `.runs/` directory.
- The trusted runner may copy that file to exactly one Vault destination:
  `AI_Review/YYYY/YYYY.MM.DD.md`.
- Preserve source IDs, timestamps, tags, and at most two short excerpts; do not duplicate full memos.
- Clearly distinguish observation, inference, and uncertainty.
- Wiki suggestions are proposals only. Do not apply them to `Wiki/`.
- Default to a first-person observer journal: a coherent self-portrait, one to three durable “mines,” one unresolved tension, and at most one gentle sentence to carry forward.
- Do not generate daily Wiki proposals. Wiki extraction happens in a separate weekly review.
- Flag CBT only as an optional follow-up when a concrete event, automatic thought, and avoidance loop are all present.

## Development workflow

- Complete each independently usable feature in its own Git commit.
- Keep `.codex/BUILD_LOG.md` concise and append-only.
- Keep `.codex/CURRENT_STATE.md` updated with the current goal, verification, next step, and risks.
- Run the smallest relevant verification after each meaningful change.
