---
description: "Phase 1: Install DEPT agents and superpowers skills into the target repository."
---

# Phase 1: Installation

> Self-contained phase. Can be run independently. Idempotent — safe to re-run.

## Prerequisites

- Git repository initialized
- Network access to GitHub (for fetching agent files)

## What This Phase Does

Installs the DEPT agentic tooling into the target repository:
- 2 agents (Discovery + Maintainer)
- 6 prompts (bootstrap + 5 phase prompts)
- 1 Graphify bootstrap helper script
- 4 superpowers skills

## Step 1: Fetch and Install DEPT Agents

Fetch these files from the DEPT Agentic Standards repository:

| Artifact | Source | Write to |
|---|---|---|
| Discovery Agent | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/ai-project-discovery.agent.md` | `.github/agents/ai-project-discovery.agent.md` |
| Maintainer Agent | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/ai-project-maintainer.agent.md` | `.github/agents/ai-project-maintainer.agent.md` |
| Bootstrap Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate.prompt.md` | `.github/prompts/migrate.prompt.md` |
| Phase 1 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/01-install.prompt.md` | `.github/prompts/01-install.prompt.md` |
| Phase 2 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/02-discover.prompt.md` | `.github/prompts/02-discover.prompt.md` |
| Phase 3 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/03-integrate.prompt.md` | `.github/prompts/03-integrate.prompt.md` |
| Phase 4 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/04-stack-tooling.prompt.md` | `.github/prompts/04-stack-tooling.prompt.md` |
| Phase 5 Prompt | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/05-bmad.prompt.md` | `.github/prompts/05-bmad.prompt.md` |
| Graphify Bootstrap Helper | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/graphify-bootstrap.sh` | `scripts/graphify-bootstrap.sh` |

**Action:** Create `.github/agents/`, `.github/prompts/`, and `scripts/` directories. Write each file. Skip if already exists. Ensure `scripts/graphify-bootstrap.sh` is executable.

## Step 2: Install Superpowers Skills

Superpowers skills provide reusable discipline patterns that agents reference.

| Skill | Purpose | Source | Write to |
|---|---|---|---|
| writing-skills | Evidence-first documentation | `agents/writing-skills/SKILL.md` | `.github/skills/writing-skills/SKILL.md` |
| systematic-debugging | Root-cause analysis patterns | `agents/systematic-debugging/SKILL.md` | `.github/skills/systematic-debugging/SKILL.md` |
| verification-before-completion | Quality gates before declaring done | `agents/verification-before-completion/SKILL.md` | `.github/skills/verification-before-completion/SKILL.md` |
| test-driven-development | TDD RED-GREEN-REFACTOR cycle | `agents/test-driven-development/SKILL.md` | `.github/skills/test-driven-development/SKILL.md` |

**Action:** Create `.github/skills/` directory. Write each skill file. Skip if already exists.

## Verification

Before proceeding to Phase 2, confirm:
- [ ] `.github/agents/` contains 2 agent files
- [ ] `.github/prompts/` contains `migrate.prompt.md` and `01-05` phase prompts
- [ ] `scripts/graphify-bootstrap.sh` exists and is executable
- [ ] `.github/skills/` contains 4 skill directories

## Completion Signal

```
✓ Phase 1 complete: Agents and skills installed.
  Next: Run Phase 2 (02-discover.prompt.md) to analyze the repository.
```
