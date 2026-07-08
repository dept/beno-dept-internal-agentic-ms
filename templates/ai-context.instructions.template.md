---
applyTo: "**"
---

This project has a `.ai/` folder with structured context. Before answering questions about this codebase, read:

- `.ai/project-context.md` — project overview, environments, ownership
- `.ai/architecture.md` — system topology, services, integrations
- `.ai/coding-standards.md` — conventions, linting, testing, PR policy

Load additionally only when the task requires it:
- `.ai/dependencies.md` — dependency, upgrade, or security questions
- `.ai/operational-context.md` — deployment, monitoring, or SLO questions
- `.ai/runbooks.md` — incident procedures and recovery steps

**Evidence discipline (superpowers:writing-skills):** Only infer facts from source code, config, CI/CD, and `.ai/` files. Never invent project-specific details. If information is missing, say so explicitly and recommend running the Maintainer Agent to refresh context.
