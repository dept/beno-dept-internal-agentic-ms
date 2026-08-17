---
name: codebase-overview
description: "Use when you need to know how [PROJECT_NAME] is structured: what lives where in the repository, which apps and packages exist and what each is for, the technology stack, which shared helpers everything depends on, and where a new file should go. Read this before exploring the tree."
---

# [PROJECT_NAME] Codebase Overview

Everything below the marker is generated from `.ai/architecture.md`. Edit that file, not this one:
an edit here is overwritten the next time the Maintainer Agent runs. Anything this file does not
answer is in `.ai/`, one topic per file, indexed at the top of `AGENTS.md`.

If this file and the code disagree, the code wins. Say so and flag it for the Maintainer Agent
rather than quietly working around it.

<!-- BEGIN GENERATED FROM .ai/architecture.md -- do not edit here -->

## Repository layout

[Copy the annotated tree from `.ai/architecture.md` -> *Repository layout*, verbatim.]

## Technology stack

[Copy the technology stack table from `.ai/architecture.md` -> *Technology stack*, verbatim.]

## Placement conventions

[Copy the placement table from `.ai/architecture.md` -> *Placement conventions*, verbatim: kind of
new code, where it goes, and the existing file to follow as the pattern.]

## High-fan-in symbols

[Copy the high-fan-in table from `.ai/architecture.md` -> *High-fan-in symbols*, verbatim: the
shared helpers to reuse instead of writing a second version, with paths and consumer counts.]

<!-- END GENERATED FROM .ai/architecture.md -->

## Generation rules

- Copy these four sections verbatim from `.ai/architecture.md`. Do not summarise, reorder, or add
  a fact that is not in the source: this file must be checkable against it by eye.
- Nothing else from `.ai/` is copied here. Other topics get the one pointer line above and no more,
  because a loaded skill stays in context for the rest of the session.
- Regenerate whenever those sections of `.ai/architecture.md` change, and mirror the result to
  `.claude/skills/codebase-overview/SKILL.md`.
- Substitute `[PROJECT_NAME]` in the description. The description is what an agent matches on
  before loading anything, so it stays specific.
