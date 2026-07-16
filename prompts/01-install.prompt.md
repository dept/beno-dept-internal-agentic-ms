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

**Do NOT install testing or TDD skills anywhere in this workflow.** Testing discipline is stack-specific and only handled in Phase 4 when evidence of existing tests is found. Installing a generic TDD skill on a project that doesn't practice TDD introduces guidance that conflicts with the project's actual workflow.

## Verification

Before proceeding to Phase 2, confirm:
- [ ] `.github/agents/` contains 2 agent files
- [ ] `.github/prompts/` contains `migrate.prompt.md` and `01-04` phase prompts
- [ ] `scripts/graphify-bootstrap.sh` exists and is executable
- [ ] `scripts/validate.sh` exists and is executable
- [ ] `.github/skills/confluence-cli/` exists (SKILL.md + confluence.sh + references/setup.md); `confluence.sh` is executable
- [ ] No other skills yet — stack-specific skills are added in Phase 4

## Completion Signal

```
✓ Phase 1 complete: Agents, prompts, and helper scripts installed.
  Next: Run Phase 2 (02-discover.prompt.md) to analyze the repository.
```
