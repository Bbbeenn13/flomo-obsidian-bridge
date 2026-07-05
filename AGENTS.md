# Flomo → Obsidian Bridge

## Safety boundary

- Treat the configured Obsidian vault as read-only except for `AI_Review/`.
- Never modify `Daily_Note/`, `Thinking_Lab/`, `0_System_initial/`, `Wiki/`, `.obsidian/`, or `.git/` during a daily bridge run.
- Never create, update, or delete flomo memos. flomo is a read-only source for this project.
- If the date, vault path, source memo range, or intended output is unclear, stop with an explicit error instead of guessing.
- Never bulk-delete files or directories. A file may only be deleted when its exact path is explicitly approved.

## Output contract

- A daily run may create or replace exactly one Markdown file:
  `AI_Review/YYYY/YYYY.MM.DD.md` inside the configured vault.
- Preserve original memo text and timestamps in the review packet.
- Clearly distinguish observation, inference, and uncertainty.
- Wiki suggestions are proposals only. Do not apply them to `Wiki/`.

## Development workflow

- Complete each independently usable feature in its own Git commit.
- Keep `.codex/BUILD_LOG.md` concise and append-only.
- Keep `.codex/CURRENT_STATE.md` updated with the current goal, verification, next step, and risks.
- Run the smallest relevant verification after each meaningful change.

