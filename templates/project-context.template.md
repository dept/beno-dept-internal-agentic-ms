# Project Context Template

## Purpose
Provide a concise operational and business overview of the project so AI agents can reason about scope, stakeholders, service boundaries, and the purpose of each major area.

## Required Sections
- Project summary
- Business capabilities
- Key features
- Major apps / packages / features / campaigns, one plain-language line each on what it is *for* when the project has multiple areas
- Service ownership and contacts
- Environments and URLs
- Critical constraints
- Discovery inputs used (for example docs/ or Graphify artifacts) when they materially shaped the understanding

## Boundary with `architecture.md`

`project-context.md` is the business file: what the system is for, key features, ownership.
`architecture.md` is the structural file and the only home for the **repository tree**, the
**technology stack table**, the high-fan-in symbol table, and the placement conventions.

Do not restate any of those here. The per-area lines above are one plain-language sentence each
on purpose and audience. The technical package map belongs in `architecture.md`. If a fact is
structural, write a pointer (`See architecture.md → Repository layout`), never a copy.

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
- Are all environments listed with purpose and risk level?
- Is team ownership explicit and current?
- If Graphify or docs/ were used to accelerate discovery, were the resulting claims verified against primary repository evidence before being written here?

## Missing Information
- Unknown stakeholder contacts
- Missing environment URL mapping
- Package or campaign names found, but purpose not yet verified from code/docs
