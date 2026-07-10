# [PROJECT_NAME] — Codex Agent Instructions

This project uses a `.ai/` folder for structured, evidence-based AI context. Load it before starting any task.

## Context files

Read these at the start of every task:

- `.ai/project-context.md` — project overview, environments, ownership
- `.ai/architecture.md` — system topology, services, integrations
- `.ai/dependencies.md` — key dependencies, versions, risk flags
- `.ai/operational-context.md` — deployment, monitoring, SLOs
- `.ai/runbooks.md` — incident procedures
- `.ai/coding-standards.md` — conventions, linting, testing, PR rules
- `.ai/cms.md` — CMS config, content models, webhooks
- `.ai/onboarding.md` — local dev setup
- `.ai/agent-registry.md` — active agents, skills, MCP servers

Cross-reference with:
- `.github/agents/` — installed agents
- `.github/skills/` — project skills
- `.github/prompts/` — phase prompts

## Setup

[SETUP_COMMANDS]

## Behaviour rules

1. Only infer facts from source code, config files, CI/CD, and `.ai/` documentation.
2. Never invent service names, endpoints, team members, or environment details.
3. If something is not found, say: `Unknown — not found in .ai/ or repository`.
4. Use bullet points and tables. Avoid filler language.
5. If `.ai/` content contradicts the codebase, flag it — do not silently accept stale context.

## Key constraints (summary — full detail in `.ai/coding-standards.md`)

[KEY_CONSTRAINTS_ONE_LINERS]
