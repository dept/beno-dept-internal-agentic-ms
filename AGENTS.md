# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

## What this repository is

The DEPT Agentic Project Standard: the definition of the `.ai/` context folder, the two agents that
generate and maintain it, the phase prompts that drive a migration, and the scripts that install and
validate it in a target repository. It produces artifacts for other repositories; it has no runtime
of its own. `standards/agentic-project-standard.md` is the formal definition.

## Sharp edges

- **The writing rules live in exactly one file.** `standards/writing-rules.md` holds every rule about
  what may be written into `.ai/`, wiring files and skills. Templates, agents, prompts and logic
  files carry a pointer to it and never a copy. Restating a rule there is the failure the rules
  exist to prevent, and a reviewer will treat a second copy as a defect.
- **Every agent is defined twice.** `agents/<name>.agent.md` is the harness-facing wrapper and
  `agents/<name>/logic.md` is the tool-agnostic workflow. A behaviour change lands in both or the
  two drift.
- **Skill layout:** `.agents/skills/` is the source (Copilot, VS Code, Codex and Cursor read it;
  Codex reads only that path), `.claude/skills` is a relative symlink to it (Claude Code reads only
  that path). `.github/skills/` is the standard 1.x layout and appears only as something to migrate
  away from.
- **Nothing under `.claude/` is a file.** Both Claude mirrors are relative symlinks:
  `.claude/skills` -> `.agents/skills`, and `.claude/agents/<role>.md` ->
  `.github/agents/<role>.agent.md`. `scripts/mirror-claude.sh` creates and repairs them, and
  `scripts/install.sh` runs it on install and on every `--update`. Agent frontmatter is
  `description` and `name` only: `tools:` is optional in both harnesses and omitting it means all
  tools, so no harness-specific field remains and one file serves both. The rule is stated once in
  `standards/agentic-project-standard.md` -> Claude Code mirrors.
- **An agent is named by its role alone.** `.github/agents/<role>.agent.md` and
  `.claude/agents/<role>.md`: discovery, maintainer, support, with `name:` the same role in
  lowercase. No `-agent` suffix on either side, and `.github/agents/` stays the source because it
  is the only repository-level location the GitHub cloud coding agent reads.
  `scripts/mirror-claude.sh` renames legacy sources and removes the stale mirror, so an old name
  never survives as a second registered agent.
- **Wiring layout:** `AGENTS.md` is the one authored wiring file and every harness reads it, Claude
  Code through the `@AGENTS.md` import that is the whole of `CLAUDE.md`. The standard generates no
  `.github/copilot-instructions.md`, no `.github/instructions/*.instructions.md` and no
  `.cursor/rules/*.mdc`. `CLAUDE.md` is a real file, in this repository too, never a symlink: a
  write aimed at it follows the link and overwrites `AGENTS.md`, and a Windows checkout without
  symlink support turns the link into a one-line file holding the path. The `.claude/skills/`
  mirror is the separate case, and it is a symlink.
- **`scripts/install.sh` classifies artifacts.** `ARTIFACTS` is the install list and
  `BOOTSTRAP_ONLY` names the subset that exists only to bootstrap an unmigrated project (the migrate
  prompt and its `ms-migration` command, the discovery agent, phase prompts `01`-`04`,
  `graphify-bootstrap.sh`). A project with a `.ai/.meta.yml` never gets those installed or
  refreshed, so a version refresh does not undo the migrate prompt's Phase 5 cleanup. The installer never deletes: that stays the operator's choice.
- **A file-layout change is a breaking change.** Bump `config/standard-version.yml` and add a
  changelog entry naming what moved, so a repository migrated under an older version can be told
  what to do.
- **Every standard-content change bumps the version.** `.github/workflows/version-bump.yml` fails a
  PR that touches standard content without changing the `version` field. See the Versioning section
  of `README.md` for what counts as standard content and how a project reports its version.
- **One bump per PR, not per commit.** While a PR is open, later commits amend its changelog entry
  for the version being released; only a PR without an unreleased bump introduces a new version.
- **Every script runs under `set -euo pipefail`.** A `grep ... | head | sed` reader that finds
  nothing exits non-zero, and inside `$(...)` that kills the whole script with no message, skipping
  every later check. End such pipelines with `|| true` when a no-match is a legitimate result.
- **`scripts/validate.sh` has two modes.** Against a target repository it runs every section.
  Against this repository (no `.ai/`, but `standards/` and `config/standard-version.yml` present)
  it runs the reference-integrity section alone, over this repo's own layout, and fails on a path
  that does not resolve. Check it with `bash -n scripts/validate.sh`, run `bash scripts/validate.sh .`
  here, and run it against a locally migrated clone for the rest.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
