# Architecture Template

## Purpose
Document system structure, runtime boundaries, and integration flows for safe AI-assisted changes.

## Required Sections
- Component inventory
- Package / feature / campaign summaries when the project has multiple areas
- Runtime architecture diagram
- Data flow and trust boundaries
- External integrations
- Failure domains
- Structural discovery notes when Graphify materially helped identify boundaries or hotspots

## Example Content
- Components: Next.js web app, API routes, Azure Functions, Redis cache
- Package summary: "`apps/checkout` serves the storefront checkout flow and depends on payment, tax, and inventory services."
- Feature summary: "The loyalty feature manages points accrual and redemption across both web and CRM touchpoints."
- Integration: Contentful GraphQL API and webhook callbacks

## Validation
- Does every component map to real code or infra definitions?
- Does every major package/feature/campaign have a short human-readable purpose summary?
- Are trust boundaries and external calls clearly identified?
- If Graphify highlighted service boundaries, dependency clusters, or hotspots, were those findings verified against repository evidence before being documented?

## Missing Information
- Unknown internal network constraints
- Undocumented batch workers
- Structural area identified by tooling, but its purpose is still unclear
