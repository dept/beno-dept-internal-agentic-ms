---
applyTo: "**"
---

This project has a `.ai/` folder with structured context.

[PROJECT_SUMMARY]
<!-- Two or three sentences from .ai/project-context.md: what the system is and the
constraints that apply to every task. The only .ai/ content restated here. -->

Do not load `.ai/` files up front. Read one when the task touches its area:

- `.ai/project-context.md` — project scope, key features, ownership, environments
- `.ai/architecture.md` — repository layout, technology stack, service boundaries, shared helpers to reuse, where new code goes
- `.ai/coding-standards.md` — conventions, linting, testing, PR policy (any code change)
- `.ai/dependencies.md` — dependency, upgrade, or security questions
- `.ai/operational-context.md` — deployment, monitoring, or SLO questions
- `.ai/runbooks.md` — incident procedures and recovery steps

**Evidence discipline (superpowers:writing-skills):** Only infer facts from source code, config, CI/CD, and `.ai/` files. Never invent project-specific details. If information is missing, say so explicitly and recommend running the Maintainer Agent to refresh context.
