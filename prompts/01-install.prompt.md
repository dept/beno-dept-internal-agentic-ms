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

**Note on skills:** No skills are installed in Phase 1. Superpowers disciplines
(evidence-first, systematic-debugging, verification) are referenced by the
agents as *background guidance* — they do not require local files. Stack-specific
skills are installed later in **Phase 4** (vendor-fetched via `gh skill` or
generated from `.ai/` evidence). `.github/skills/` is therefore created in
Phase 4, not here.

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

**Action:** Create `.github/agents/`, `.github/prompts/`, and `scripts/` directories. Write each file. Skip if already exists. Ensure `scripts/graphify-bootstrap.sh` and `scripts/validate.sh` are executable.

**Do NOT install testing or TDD skills anywhere in this workflow.** Testing discipline is stack-specific and only handled in Phase 4 when evidence of existing tests is found. Installing a generic TDD skill on a project that doesn't practice TDD introduces guidance that conflicts with the project's actual workflow.

## Verification

Before proceeding to Phase 2, confirm:
- [ ] `.github/agents/` contains 2 agent files
- [ ] `.github/prompts/` contains `migrate.prompt.md` and `01-04` phase prompts
- [ ] `scripts/graphify-bootstrap.sh` exists and is executable
- [ ] `scripts/validate.sh` exists and is executable
- [ ] `.github/skills/` is NOT expected yet — it is created in Phase 4

## Completion Signal

```
✓ Phase 1 complete: Agents, prompts, and helper scripts installed.
  Next: Run Phase 2 (02-discover.prompt.md) to analyze the repository.
```
