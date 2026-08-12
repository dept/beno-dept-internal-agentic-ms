# Architecture Template

## Purpose
Document system structure, runtime boundaries, and integration flows for safe AI-assisted changes.

## Required Sections
- Component inventory
- Repository layout: the annotated tree of apps/packages/services (this file is its only home)
- Technology stack table: runtime, framework, package manager, monorepo tool, hosting (this file is its only home)
- Package / feature / campaign summaries when the project has multiple areas
- Mermaid architecture overview (`flowchart LR` or `flowchart TD`) for quick orientation
- Runtime architecture diagram
- Data flow and trust boundaries
- External integrations
- Failure domains
- **High-fan-in symbols**: who owns what (see below)
- **Placement conventions** (see below)
- Structural discovery notes when Graphify materially helped identify boundaries or hotspots

## Boundary with `project-context.md`

`architecture.md` is the structural file: layout, stack, boundaries, and the two tables below.
`project-context.md` is the business file: what the system is for, key features, ownership.
Never restate the repository tree or the technology stack table there; point at this file instead.

## Writing rules

**Describe the codebase as it is today. Never narrate change.** This file is agent-read context, not
a changelog. Do not write what changed, when it changed, or what moved where: no commit references,
no dates of previous versions, no notes about a prior state of the repository or of this file. These
lines are all wrong here:

- "inherited unchanged from the 2026-07-14 version of this file"
- "this section was rewritten on 2026-07-31"
- "commit X deleted this file, it is now restored"
- "three sections previously carried here have moved to `project-context.md`"

The change history lives in git and in the PR that made the change, which is where a human reads it.
An agent reading this file mid-task needs the current truth and nothing else.

Evidence and confidence notes are the one exception, in one direction only: cite the source files a
claim was derived from and the date that evidence was gathered, because that is a fact about the
evidence. `Confidence: 85% (source: turbo.json, pnpm-workspace.yaml, verified 2026-08-12)` is
correct. A note that names an earlier version of this file, a commit, or a prior repository state is
not, however it is phrased.

## High-fan-in symbols (who owns what)

The shared functions, hooks, and helpers that the rest of the codebase depends on. An agent reads
this table to reuse what exists instead of writing a second version of it, and to know which
symbols cannot be changed casually.

| Symbol | File | Consumers | Role |
|---|---|---|---|
| `classNames()` | `packages/ui/src/class-names.ts` | 159 | Merges Tailwind class strings; every component uses it |
| `sendGTMEvent()` | `packages/analytics/src/gtm.ts` | 38 | Single entry point for GTM dataLayer pushes |

- List the symbols with the highest fan-in, not every export. Roughly 10 rows is the useful size.
- `Consumers` is the fan-in count. Take it from `graphify-out/graph.json` when Graphify ran; otherwise from `grep -rc`, and say which. Leave it blank rather than guessing. The number is what marks a symbol as load-bearing.
- One line per role, describing what it does and why everything depends on it.
- Verify every symbol and path exists before writing the row.

## Placement conventions

Where each kind of new code goes. An agent reads this before creating a file, so it lands in the
same place a team member would have put it.

| Kind of new code | Goes in | Follow the pattern in |
|---|---|---|
| Shared React component | `packages/ui/src/components/<name>/` | `packages/ui/src/components/button/` |
| Route / page | `apps/web/src/app/<segment>/page.tsx` | `apps/web/src/app/campaigns/page.tsx` |
| CMS content type | `packages/cms/src/types/` | `packages/cms/src/types/article.ts` |

- Cover the kinds of change this project actually receives, not every conceivable one.
- Every path must be confirmed with `ls`/glob, and every `Follow the pattern in` example must be a real existing file.

## Diagram Guidance
- Use Mermaid, not ASCII art or pasted screenshots
- When this diagram is published to Confluence it goes in a collapsed `Diagram source` expand followed by the Mermaid Diagrams Viewer macro; see `docs/confluence-page-standard.md` → *Publishing the diagram*. This file stays the source of truth and the published code block carries a verbatim copy of the `mermaid` block
- Keep it high level: main entrypoints, major internal services/packages, and key external systems
- Optimize for quick orientation by a new engineer or client manager
- Prefer one simple overview diagram before any detailed package notes

## Example Content
- Components: Next.js web app, API routes, Azure Functions, Redis cache
- Package summary: "`apps/checkout` serves the storefront checkout flow and depends on payment, tax, and inventory services."
- Feature summary: "The loyalty feature manages points accrual and redemption across both web and CRM touchpoints."
- Integration: Contentful GraphQL API and webhook callbacks

## Validation
- Does every component map to real code or infra definitions?
- Does every major package/feature/campaign have a short human-readable purpose summary?
- Are trust boundaries and external calls clearly identified?
- Does every row of the high-fan-in table name a symbol and path that exist, with the source of its consumer count stated?
- Does the placement table cover the kinds of change this project actually receives, with a real example file per row?
- Does `project-context.md` avoid restating the repository tree and the technology stack table?
- Is the file free of change narration: no commit references, no dates of previous versions, no "moved to"/"was rewritten"/"restored" notes? (An evidence date on a confidence note is fine.)
- If Graphify highlighted service boundaries, dependency clusters, or hotspots, were those findings verified against repository evidence before being documented?

## Missing Information
- Unknown internal network constraints
- Undocumented batch workers
- Structural area identified by tooling, but its purpose is still unclear
