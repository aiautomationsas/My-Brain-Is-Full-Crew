# Project Instructions — My Brain Is Full — Crew

## What this is

A multi-platform AI "crew" (8 agents + 14 skills) that runs as a personal
assistant for Obsidian-style vaults, distributed as a plugin for Claude
Code, Gemini CLI, OpenCode, and Codex CLI. There is **no application
code** — the entire repo is Markdown (agent/skill definitions), Bash
(adapters, hooks, scripts), and config. Do not look for a package.json,
build step, or compiled artifact; there isn't one.

## Distribution model (important — read before editing paths)

This repo is the **source**. When installed into a user's vault, the
adapter scripts (`adapters/<platform>/adapter.sh`) translate `agents/`
and `skills/` into the target platform's format, landing under
`.platform/agents/`, `.platform/skills/`, `.platform/references/` in the
consumer vault. `DISPATCHER.md` and `settings.json` reference those
`.platform/...` and `.claude/hooks/...` paths — that's the *installed*
layout, not this repo's layout. Don't "fix" those paths to match this
repo's tree; they're correct for the install target.

## Code Style

- Agent/skill files: Markdown with YAML frontmatter, English instructions,
  multilingual trigger phrases, responses always in the user's language.
- Bash scripts: `set -e`, shared helpers live in `adapters/lib.sh` and
  `scripts/lib.sh` — reuse them rather than duplicating logic per platform.
- New agent → follow the structure in `references/agent-template.md` and
  register it in `references/agents-registry.md`.
- New platform capability → add it symmetrically across all 4
  `adapters/<platform>/adapter.sh` files; check `docs/codex-cli.md` /
  `references/codex-cli-compat.md` for platform-specific caveats.

## Testing

- Run all tests: `bash tests/run.sh` (discovers `*.test.sh`, runs every
  `test_*()` function, no external test runner or dependencies).
- Test layout mirrors adapters: `tests/adapters/{claude-code,gemini-cli,
  codex-cli,opencode}/`, plus `tests/lib.test.sh` and `tests/regression/`.
- Add a test alongside the script/adapter you change, following the
  existing `test_*()` naming convention.

## Build & Run

- No build step. `scripts/build.sh` assembles/packages the plugin;
  `scripts/launchme.sh` / `scripts/updateme.sh` handle install/update
  flows into a target vault.
- `orchestra/run.sh` runs pre-declared named operations (permission-free
  agent invocations) — check `orchestra/scripts/` before writing a new
  ad-hoc script.

## Project Structure

| Dir | Purpose |
| --- | --- |
| `agents/` | 8 core agent definitions (architect, scribe, sorter, seeker, connector, librarian, transcriber, postman) |
| `skills/` | 14 conversational multi-turn skill flows, each `skills/<name>/SKILL.md` |
| `adapters/` | Per-platform translation layer (claude-code, gemini-cli, codex-cli, opencode) + shared `lib.sh` |
| `hooks/` | PreToolUse/PostToolUse/Notification hook scripts referenced by `settings.json` |
| `orchestra/` | Named, permission-free script orchestration + regression scripts |
| `scripts/` | Build/install/update scripts + CLI utilities (Hey.com email, contact/vault inspection) |
| `references/` | Agent registry, orchestration protocol, agent template, platform-compat notes |
| `docs/` | Setup guides, examples, legal/disclaimer docs |
| `tests/` | Bash test suite mirroring adapters structure |

## Conventions

- Commits: Conventional-ish (`feat:`, `feat(scope):`) with PR number
  references, e.g. `feat(codex): use gpt-5.5 models (#41)`.
- Dispatcher rule (`DISPATCHER.md`): skills are checked before agents;
  never invent an agent/skill/tool not defined in this project's files.
- Keep every new platform feature symmetric across all 4 adapters —
  asymmetry between platforms is the most common source of bugs here.
