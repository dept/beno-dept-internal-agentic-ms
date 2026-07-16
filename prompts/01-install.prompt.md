---
description: "Phase 1: Install DEPT agents, phase prompts, and helper scripts into the target repository."
---

# Phase 1: Installation

> Self-contained phase. Can be run independently. Idempotent — safe to re-run.

## Prerequisites

- Git repository initialized
- Network access to GitHub (for fetching agent files)

## What This Phase Does

Installs the DEPT agentic tooling into the target repository:
- 2 agents (Discovery + Maintainer)
- 5 prompts (bootstrap + 4 phase prompts)
- 2 helper scripts (Graphify bootstrap + validator)
- 1 fixed skill: `confluence-cli` (always installed — every DEPT project uses Confluence for handover)

**Note on skills:** Only **fixed DEPT skills** are installed in Phase 1 — currently
just `confluence-cli` (a shipped template, not stack-detected). Superpowers
disciplines (evidence-first, systematic-debugging, verification) are referenced by
the agents as *background guidance* and need no local files. **Stack-specific**
skills (React, Next.js, CMS, etc.) are installed later in **Phase 4**
(vendor-fetched via `gh skill` or generated from `.ai/` evidence).

## Step 1: Fetch and Install DEPT Agents

Fetch these files from the DEPT Agentic Standards repository:

| Artifact | Source | Write to |
|---|---|---|
| Discovery Agent | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/discovery.agent.md` | `.github/agents/discovery.agent.md` |
| Maintainer Agent | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/maintainer.agent.md` | `.github/agents/maintainer.agent.md` |
| Bootstrap Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate.prompt.md` | `.github/prompts/migrate.prompt.md` |
| Phase 1 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/01-install.prompt.md` | `.github/prompts/01-install.prompt.md` |
| Phase 2 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/02-discover.prompt.md` | `.github/prompts/02-discover.prompt.md` |
| Phase 3 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/03-integrate.prompt.md` | `.github/prompts/03-integrate.prompt.md` |
| Phase 4 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/04-stack-tooling.prompt.md` | `.github/prompts/04-stack-tooling.prompt.md` |
| Graphify Bootstrap Helper | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/graphify-bootstrap.sh` | `scripts/graphify-bootstrap.sh` |
| Validator | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/validate.sh` | `scripts/validate.sh` |
| Confluence skill | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/templates/skills/confluence-cli/SKILL.md` | `.github/skills/confluence-cli/SKILL.md` |
| Confluence skill helper | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/templates/skills/confluence-cli/confluence.sh` | `.github/skills/confluence-cli/confluence.sh` |
| Confluence skill setup | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/templates/skills/confluence-cli/references/setup.md` | `.github/skills/confluence-cli/references/setup.md` |

**Action:** Create `.github/agents/`, `.github/prompts/`, `.github/skills/confluence-cli/`, and `scripts/` directories. Write each file. Skip if already exists. Ensure `scripts/graphify-bootstrap.sh`, `scripts/validate.sh`, and `.github/skills/confluence-cli/confluence.sh` are executable.

**Mirror Discovery + Maintainer agents to Claude Code:** `.github/agents/*.agent.md` is Copilot-only — Claude Code auto-loads subagents from `.claude/agents/*.md` instead, with different frontmatter (`name`, `description`; no `tools:` list — Claude Code subagents inherit all available tools by default, so drop the Copilot `tools: [...]` line entirely). Write:
- `.claude/agents/discovery.md` — mirrors `.github/agents/discovery.agent.md`'s body verbatim
- `.claude/agents/maintainer.md` — mirrors `.github/agents/maintainer.agent.md`'s body verbatim

Body prose is tool-agnostic already (references `.ai/`, evidence rules, workflow steps) — only the frontmatter changes. `.github/agents/` stays the source; re-copy the body on any future edit.

**Mirror to Claude Code:** Copy the `confluence-cli` skill verbatim (SKILL.md unchanged — Claude Code uses the same `name`/`description` frontmatter format) to `.claude/skills/confluence-cli/`. Same files, same executable bit on `confluence.sh`. This keeps Claude Code's skill auto-discovery (`.claude/skills/`) in sync with Copilot's (`.github/skills/`) without a second source of truth — one install, two locations.

**Mirror prompts as slash commands for Claude Code + Cursor:** `.github/prompts/*.prompt.md` is Copilot's `@workspace /name` format. Claude Code auto-loads slash commands from `.claude/commands/<name>.md`, and Cursor from `.cursor/commands/<name>.md` — same trigger UX (`/ms-migration`, `/ms-install`, ...), different folder + frontmatter. For each installed prompt, write both mirrors:

| Source | Claude Code | Cursor |
|---|---|---|
| `.github/prompts/migrate.prompt.md` | `.claude/commands/ms-migration.md` | `.cursor/commands/ms-migration.md` |
| `.github/prompts/01-install.prompt.md` | `.claude/commands/ms-install.md` | `.cursor/commands/ms-install.md` |
| `.github/prompts/02-discover.prompt.md` | `.claude/commands/ms-discover.md` | `.cursor/commands/ms-discover.md` |
| `.github/prompts/03-integrate.prompt.md` | `.claude/commands/ms-integrate.md` | `.cursor/commands/ms-integrate.md` |
| `.github/prompts/04-stack-tooling.prompt.md` | `.claude/commands/ms-stack-tooling.md` | `.cursor/commands/ms-stack-tooling.md` |

Body content carries over unchanged (it's already tool-agnostic prose). Keep `description`/`argument-hint` from the source frontmatter; drop `agent:` (Copilot-only — Claude Code invokes the Discovery Agent via its own `.claude/agents/discovery.md`, referenced by name in the body instead).

**OpenAI Codex:** Codex has no project-level command/agent/skill folders — it reads `AGENTS.md` (created in Phase 3) and any file you point it at. No mirror to write here; `AGENTS.md` references the migrate prompt so Codex users run it via "read `.github/prompts/migrate.prompt.md` and follow it."

**Do NOT install testing or TDD skills anywhere in this workflow.** Testing discipline is stack-specific and only handled in Phase 4 when evidence of existing tests is found. Installing a generic TDD skill on a project that doesn't practice TDD introduces guidance that conflicts with the project's actual workflow.

## Verification

Before proceeding to Phase 2, confirm:
- [ ] `.github/agents/` contains 2 agent files
- [ ] `.claude/agents/` contains `discovery.md` + `maintainer.md` mirroring the same 2 agents
- [ ] `.github/prompts/` contains `migrate.prompt.md` and `01-04` phase prompts
- [ ] `.claude/commands/` and `.cursor/commands/` each contain the 5 mirrored slash commands (`ms-migration`, `ms-install`, `ms-discover`, `ms-integrate`, `ms-stack-tooling`)
- [ ] `scripts/graphify-bootstrap.sh` exists and is executable
- [ ] `scripts/validate.sh` exists and is executable
- [ ] `.github/skills/confluence-cli/` exists (SKILL.md + confluence.sh + references/setup.md); `confluence.sh` is executable
- [ ] `.claude/skills/confluence-cli/` mirrors the same files (Claude Code auto-load)
- [ ] No other skills yet — stack-specific skills are added in Phase 4

## Completion Signal

```
✓ Phase 1 complete: Agents, prompts, and helper scripts installed.
  Next: Run Phase 2 (02-discover.prompt.md) to analyze the repository.
```
