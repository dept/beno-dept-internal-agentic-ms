# Project AI Instructions

This project contains a `.ai/` folder with structured context for AI assistants. Read it before answering questions about this codebase.

## What this project is

[PROJECT_SUMMARY]

<!-- Two or three sentences from .ai/project-context.md: what the system is, who it
serves, and the constraints that apply to every task. This summary is the only .ai/
content restated here. Keep it short, and keep it a summary, never a copy. -->

## What to read, and when

Do not load `.ai/` files up front. Read one when the task touches its area:

| File | Load when |
|------|-----------|
| `.ai/project-context.md` | Project scope, business capabilities, key features, team ownership, environments |
| `.ai/architecture.md` | Structure questions: repository layout, technology stack, service boundaries, which shared helpers to reuse, where new code goes |
| `.ai/coding-standards.md` | Any code change: conventions, linting, testing, PR policy |
| `.ai/dependencies.md` | Dependency, upgrade, or security questions |
| `.ai/operational-context.md` | Deployment, monitoring, or SLO questions |
| `.ai/runbooks.md` | Incidents, recovery, or on-call questions |
| `.ai/cms.md` | CMS content, content models, or webhook questions |
| `.ai/onboarding.md` | Local dev setup questions |
| `.ai/agent-registry.md` | Agent orchestration or MCP tool questions |

## Behaviour rules

**REQUIRED BACKGROUND:** These rules follow superpowers:writing-skills discipline for documentation accuracy and operational value.

1. **Evidence-first.** Only infer facts from source code, config files, CI/CD pipelines, and `.ai/` documentation. If something is not found, say so explicitly.
2. **Never hallucinate project facts.** No invented service names, endpoints, team members, or environment details.
3. **Prefer structured output.** Use bullet points, tables, and short sections. Avoid conversational filler.
4. **Operational focus.** Every answer should be useful for someone running, maintaining, or changing this system.
5. **Mark unknowns.** If context is missing, respond with `Unknown — not found in .ai/ or repository` and suggest where to look.

## When context may be stale

The `.ai/` folder reflects the state of the project at the time it was last updated. If you detect a contradiction between `.ai/` content and the current codebase, flag it explicitly and recommend running the Maintainer Agent.
