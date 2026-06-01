# Project Context — Claude Code

This project contains a `.ai/` folder with structured context. Read it before answering questions about this codebase.

## Files to load

Read these files at the start of every session:

- `.ai/project-context.md` — project overview, environments, ownership
- `.ai/architecture.md` — system topology, services, integrations
- `.ai/dependencies.md` — key dependencies, versions, risk flags
- `.ai/operational-context.md` — deployment, monitoring, SLOs
- `.ai/runbooks.md` — incident procedures
- `.ai/coding-standards.md` — conventions, linting, testing, PR rules
- `.ai/cms.md` — CMS config, content models, webhooks
- `.ai/onboarding.md` — local dev setup
- `.ai/agent-registry.md` — active agents and their scopes

## Behaviour rules

1. Only infer facts from source code, config files, CI/CD, and `.ai/` documentation.
2. Never invent service names, endpoints, team members, or environment details.
3. If something is not found, say: `Unknown — not found in .ai/ or repository`.
4. Use bullet points and tables. Avoid filler language.
5. If you detect a contradiction between `.ai/` content and the codebase, flag it and recommend running the AI Project Maintainer Agent.
