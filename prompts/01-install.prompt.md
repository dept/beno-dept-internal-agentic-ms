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
- 3 helper scripts (Graphify bootstrap, validator, Claude mirror rebuilder)
- 1 fixed skill: `confluence-axi` (Confluence handover pages, via the `confluence-axi` npm CLI)

**Note on skills:** Only **fixed DEPT skills** are installed in Phase 1 — currently
just `confluence-axi` (a shipped template, not stack-detected). Datadog "key features"
are fetched via the **Datadog MCP** (browser OAuth), which is configured in Phase 4 —
there is no Datadog skill to install. Superpowers
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
| Claude mirror rebuilder | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/mirror-claude.sh` | `scripts/mirror-claude.sh` |
| Standard version | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/config/standard-version.yml` | `config/standard-version.yml` |
| Writing rules | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/standards/writing-rules.md` | `standards/writing-rules.md` |
| Confluence skill | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/templates/skills/confluence-axi/SKILL.md` | `.agents/skills/confluence-axi/SKILL.md` |
| Confluence skill setup | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/templates/skills/confluence-axi/references/setup.md` | `.agents/skills/confluence-axi/references/setup.md` |

**Action:** Create `.github/agents/`, `.github/prompts/`, `.agents/skills/confluence-axi/`, `standards/`, and `scripts/` directories. Write each file. Skip if already exists. Ensure `scripts/graphify-bootstrap.sh`, `scripts/validate.sh` and `scripts/mirror-claude.sh` are executable. (The `confluence-axi` skill bundles no script: it drives the `confluence-axi` npm CLI via `npx`, so nothing to chmod.)

`standards/writing-rules.md` is the file every later phase points at when it says what may be written into `.ai/`. Install it before Phase 2 runs.

**Build the Claude Code mirrors:** run

```bash
bash scripts/mirror-claude.sh
```

It points `.claude/skills` at `.agents/skills` as a relative symlink, so the `confluence-axi` skill you just installed (and every skill Phase 4 adds) is visible to Claude Code with nothing to re-copy. It also derives `.claude/agents/discovery.md` and `.claude/agents/maintainer.md` from the two `.github/agents/*.agent.md` sources: body verbatim, frontmatter rewritten to Claude Code's `name` and `description` (no `tools:` list, since Claude Code subagents inherit all available tools).

**Do not write any file under `.claude/agents/` or `.claude/skills/` by hand, and never edit one.** They are derived. An edit belongs in the `.github/agents/` or `.agents/skills/` source, and the next run of the script carries it over. The full rule is in `standards/agentic-project-standard.md` -> Claude Code mirrors.

> **Note:** if the migration was bootstrapped via `scripts/install.sh` (the one-liner), the installer already ran this script, so the step is a no-op idempotent check. It still matters when the migration is run in-session (Option B: fetch the prompt directly without running the installer first), where no installer ran.

The transform keeps `name:` identical to the source (e.g. `name: "Discovery Agent"`, not `discovery-agent`), and that matters: VS Code Copilot default-scans BOTH `.github/agents/` and `.claude/agents/`, so each agent shows **twice** in its picker; the matching `name:` makes the two rows carry the same label (clearly one agent) rather than looking like two different agents. This duplication is expected and cannot be disabled (no setting un-scans a VS Code default location); a developer can hide the extra row via the eye icon in VS Code's *Agent Customizations* editor if desired.

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
- [ ] `.claude/agents/` contains `discovery.md` + `maintainer.md`, derived from the same 2 agents
- [ ] `.github/prompts/` contains `migrate.prompt.md` and `01-04` phase prompts
- [ ] `.claude/commands/` and `.cursor/commands/` each contain the 5 mirrored slash commands (`ms-migration`, `ms-install`, `ms-discover`, `ms-integrate`, `ms-stack-tooling`)
- [ ] `scripts/graphify-bootstrap.sh` exists and is executable
- [ ] `scripts/validate.sh` and `scripts/mirror-claude.sh` exist and are executable
- [ ] `standards/writing-rules.md` exists
- [ ] `.agents/skills/confluence-axi/` exists (SKILL.md + references/setup.md; no bundled script, it wraps the `confluence-axi` npm CLI)
- [ ] `.claude/skills` is a symlink to `.agents/skills`, so `.claude/skills/confluence-axi/SKILL.md` resolves (Claude Code auto-load)
- [ ] No other skills yet; stack-specific skills are added in Phase 4

## Completion Signal

```
✓ Phase 1 complete: Agents, prompts, and helper scripts installed.
  Next: Run Phase 2 (02-discover.prompt.md) to analyze the repository.
```
