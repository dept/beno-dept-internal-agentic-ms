# Project Context Template

## Purpose
Provide a concise operational and business overview of the project so AI agents can reason about scope, stakeholders, service boundaries, and the purpose of each major area.

## Required Sections
- Project summary
- Business capabilities
- Key features
- Major apps / packages / features / campaigns, one plain-language line each on what it is *for* when the project has multiple areas
- Service ownership and contacts
- `## Team` table (fixed shape, see below)
- Critical constraints

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

## Team table

The file carries one `## Team` section with exactly this table. It is the single source for the
Confluence `Key contacts` table and for the maintainer's team checks.

| Role | Name | GitHub | Contact | Last checked |
|---|---|---|---|---|
| Client manager | [Name or Unknown] | - | [email] | [YYYY-MM-DD] |
| Delivery lead | [Name or Unknown] | - | [email] | [YYYY-MM-DD] |
| Tech lead | [Name] | @[handle] | [email] | [YYYY-MM-DD] |
| Developer | [Name] | @[handle] | [email] | [YYYY-MM-DD] |
| QA | [Name] | @[handle] | [email] | [YYYY-MM-DD] |

- Roles, in this order: `Client manager`, `Delivery lead`, `Tech lead`, `Developer` (one row per
  person), `QA`. Add `Client contact` rows only when the client side is known.
- `Client manager` and `Delivery lead` come from a person (asked during migration). Never derive
  them from git activity. When nobody knows, write `Unknown` and list it under Missing Information.
- `Tech lead`, `Developer` and `QA` start from `scripts/team-activity.sh <org/repo>` (commits,
  pull requests and reviews in the last 180 days) and are confirmed by a person.
- `Last checked` is the date a person or the maintainer last confirmed the row. A row the
  maintainer finds inactive for 90+ days gets `(possibly left)` after the name; it is not deleted.

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
- Is team ownership explicit and current: a `## Team` table with a named (or `Unknown`) Client manager and at least one active developer?
- If Graphify or docs/ were used to accelerate discovery, were the resulting claims verified against primary repository evidence before being written here?

## Missing Information
- Unknown stakeholder contacts (any `Unknown` row in `## Team`, the Client manager first)
- Package or campaign names found, but purpose not yet verified from code/docs
