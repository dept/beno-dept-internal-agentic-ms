# Project AI Instructions

This project contains a `.ai/` folder with structured context for AI assistants. Read it before answering questions about this codebase.

## What to read first

Load these files at the start of every session or when asked about the project:

| File | Contains |
|------|----------|
| `.ai/project-context.md` | Project overview, environments, team ownership |
| `.ai/architecture.md` | System topology, service boundaries, integrations |
| `.ai/dependencies.md` | Key dependencies, risk flags, upgrade notes |
| `.ai/operational-context.md` | Deployment, monitoring, alerting, SLOs |
| `.ai/runbooks.md` | Incident procedures and recovery steps |
| `.ai/coding-standards.md` | Conventions, linting, testing, PR policy |
| `.ai/cms.md` | CMS configuration, content models, webhooks |
| `.ai/onboarding.md` | How to run the project locally |
| `.ai/agent-registry.md` | Which agents are active and their scopes |

## Behaviour rules

**REQUIRED BACKGROUND:** These rules follow superpowers:writing-skills discipline for documentation accuracy and operational value.

1. **Evidence-first.** Only infer facts from source code, config files, CI/CD pipelines, and `.ai/` documentation. If something is not found, say so explicitly.
2. **Never hallucinate project facts.** No invented service names, endpoints, team members, or environment details.
3. **Prefer structured output.** Use bullet points, tables, and short sections. Avoid conversational filler.
4. **Operational focus.** Every answer should be useful for someone running, maintaining, or changing this system.
5. **Mark unknowns.** If context is missing, respond with `Unknown — not found in .ai/ or repository` and suggest where to look.

## When context may be stale

The `.ai/` folder reflects the state of the project at the time it was last updated. If you detect a contradiction between `.ai/` content and the current codebase, flag it explicitly and recommend running the Maintainer Agent.
