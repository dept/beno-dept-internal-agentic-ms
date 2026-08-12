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

## Writing rules

**Describe the project as it is today. Never narrate change.** This file is agent-read context, not
a changelog. Do not write what changed, when it changed, or what moved where: no commit references,
no dates of previous versions, no notes about a prior state of the repository or of this file. These
lines are all wrong here:

- "inherited unchanged from the 2026-07-14 version of this file"
- "this section was rewritten on 2026-07-31"
- "commit X deleted this file, it is now restored"
- "three sections previously carried here have moved to `architecture.md`"

The change history lives in git and in the PR that made the change, which is where a human reads it.
An agent reading this file mid-task needs the current truth and nothing else. This applies to the
boundary above too: point at `architecture.md` because that is where the fact lives, never because
it used to live here.

Evidence and confidence notes are the one exception, in one direction only: cite the source files a
claim was derived from and the date that evidence was gathered, because that is a fact about the
evidence. `Confidence: 70% (source: docs/onboarding.md, verified 2026-08-12)` is correct. A note
that names an earlier version of this file, a commit, or a prior repository state is not, however it
is phrased.

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
- Is the file free of change narration: no commit references, no dates of previous versions, no "moved to"/"was rewritten"/"restored" notes? (An evidence date on a confidence note is fine.)
- Are all environments listed with purpose and risk level?
- Is team ownership explicit and current?
- If Graphify or docs/ were used to accelerate discovery, were the resulting claims verified against primary repository evidence before being written here?

## Missing Information
- Unknown stakeholder contacts
- Missing environment URL mapping
- Package or campaign names found, but purpose not yet verified from code/docs
