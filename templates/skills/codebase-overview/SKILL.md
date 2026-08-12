---
name: codebase-overview
description: "Use when you need to know how [PROJECT_NAME] is structured: what lives where in the repository, which apps and packages exist and what each is for, the technology stack, which shared helpers everything depends on, and where a new file should go. Read this before exploring the tree."
---

# [PROJECT_NAME] — Codebase Overview

This skill is an index, not a copy. The structural facts live in `.ai/`, which is the single source
of truth and stays in sync via the Maintainer Agent. Read the file this table points you at.

| You need | Read | It has |
|---|---|---|
| Repository layout, technology stack, service boundaries | `.ai/architecture.md` | Annotated tree of apps/packages, stack table, topology diagram, data flows, external integrations |
| Which shared helper to reuse instead of writing a new one | `.ai/architecture.md` → *High-fan-in symbols* | The functions and hooks the rest of the codebase depends on, with paths and roles |
| Where a new file goes | `.ai/architecture.md` → *Placement conventions* | Per kind of change: the target directory and an existing file to follow as the pattern |
| What the system is for, ownership, environments, key features | `.ai/project-context.md` | Business capabilities, per-area purpose, team contacts, environment URLs |
| Conventions, linting, testing, PR policy | `.ai/coding-standards.md` | Required before any code change |
| Dependencies, deployment, incidents, CMS, local setup | `.ai/dependencies.md`, `.ai/operational-context.md`, `.ai/runbooks.md`, `.ai/cms.md`, `.ai/onboarding.md` | One area each |

## Rules

- Read the `.ai/` file rather than answering from this page. This page carries no facts of its own,
  so anything it appeared to state would be stale by definition.
- If `.ai/` contradicts the code, the code wins. Say so, and flag it for the Maintainer Agent
  instead of quietly working around it.
- Keep this file thin. The discovery trigger is the `description` above, which is what an agent
  matches on before loading anything; a longer body buys nothing and starts a second source of
  truth. Content belongs in `.ai/`.
