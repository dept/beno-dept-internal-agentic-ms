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
  Codex reads only that path), `.claude/skills/` is the mirror (Claude Code reads only that path).
  `.github/skills/` is the standard 1.x layout and appears only as something to migrate away from.
- **Wiring layout:** `AGENTS.md` is the one authored wiring file and every harness reads it, Claude
  Code through the `@AGENTS.md` import that is the whole of `CLAUDE.md`. The standard generates no
  `.github/copilot-instructions.md`, no `.github/instructions/*.instructions.md` and no
  `.cursor/rules/*.mdc`.
- **A file-layout change is a breaking change.** Bump `config/standard-version.yml` and add a
  changelog entry naming what moved, so a repository migrated under an older version can be told
  what to do.
- **Every standard-content change bumps the version.** `.github/workflows/version-bump.yml` fails a
  PR that touches standard content without changing the `version` field. See the Versioning section
  of `README.md` for what counts as standard content and how a project reports its version.
- **Every script runs under `set -euo pipefail`.** A `grep ... | head | sed` reader that finds
  nothing exits non-zero, and inside `$(...)` that kills the whole script with no message, skipping
  every later check. End such pipelines with `|| true` when a no-match is a legitimate result.
- **`scripts/validate.sh` runs against target repositories, not this one.** Check it with
  `bash -n scripts/validate.sh` and then run it against a locally migrated clone.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
