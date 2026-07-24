# Project Context — Claude Code

This project contains a `.ai/` folder with structured context. Read it before answering questions about this codebase.

## Files to load

**Always load (start of every session):**

- `.ai/project-context.md` — project overview, environments, ownership
- `.ai/architecture.md` — system topology, services, integrations
- `.ai/coding-standards.md` — conventions, linting, testing, PR rules

**Load on demand (only when the task touches that area):**

- `.ai/dependencies.md` — key dependencies, versions, risk flags
- `.ai/operational-context.md` — deployment, monitoring, SLOs
- `.ai/runbooks.md` — incident procedures
- `.ai/cms.md` — CMS config, content models, webhooks
- `.ai/onboarding.md` — local dev setup
- `.ai/agent-registry.md` — active agents and their scopes

Don't eagerly read all nine every session; the three core files carry the shared context, the rest are task-triggered.

## Behaviour rules

**REQUIRED BACKGROUND:** These rules follow superpowers:writing-skills discipline for accuracy and operational value.

1. Only infer facts from source code, config files, CI/CD, and `.ai/` documentation.
2. Never invent service names, endpoints, team members, or environment details.
3. If something is not found, say: `Unknown — not found in .ai/ or repository`.
4. Use bullet points and tables. Avoid filler language.
5. If you detect a contradiction between `.ai/` content and the codebase, flag it and recommend running the Maintainer Agent.
