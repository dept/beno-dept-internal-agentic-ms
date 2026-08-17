# Project Context Template

## Purpose
Provide a concise operational and business overview of the project so AI agents can reason about scope, stakeholders, service boundaries, and the purpose of each major area.

## Required Sections
- Project summary
- Business capabilities
- Key features
- Major apps / packages / features / campaigns, one plain-language line each on what it is *for* when the project has multiple areas
- Service ownership and contacts
- Critical constraints
- Discovery inputs used (for example docs/ or Graphify artifacts) when they materially shaped the understanding

## Writing rules

`standards/writing-rules.md` governs this file. Read it before writing. It is not restated here.

The per-area lines above are one plain-language sentence each on purpose and audience. The
technical package map is a different fact and belongs to `architecture.md`.

## Ownership header

The generated file opens with this block, immediately after the H1:

> **Owned by this file:** what the system is for, business capabilities, key features and their
> monitoring, and the client, team and delivery model. This is the authoritative source.
> **Not carried here:** the repository tree, the technology stack table and per-package technical
> roles (`architecture.md`); environments (`operational-context.md`); URLs and access links
> (`onboarding.md`); anything about how code is written (`coding-standards.md`).

## Example Content
- Summary: "Global marketing platform for multi-brand campaign pages."
- Capability: "Editors launch regional campaign microsites without code changes."
- Package summary: "`packages/content-sync` keeps CMS entries and downstream search indexes aligned after publish events."
- Ownership: "Managed Services Web Platform Squad"
- Constraint: "Production changes require CAB approval."

## Validation
- Is the business purpose understandable to a new developer in a few minutes?
- Does every major package/feature/campaign have a short human-readable purpose summary instead of only a path or name?
- Is the repository tree and technology stack table absent from this file, with a pointer to `architecture.md` where one is needed?
- Does the file pass every rule in `standards/writing-rules.md`?
- Is team ownership explicit and current?
- If Graphify or docs/ were used to accelerate discovery, were the resulting claims verified against primary repository evidence before being written here?

## Missing Information
- Unknown stakeholder contacts
- Package or campaign names found, but purpose not yet verified from code/docs
