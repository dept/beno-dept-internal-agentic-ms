# Dependencies Template

## Purpose
Provide a structured inventory of technical dependencies and their operational impact.

## Required Sections
- Runtime dependencies
- Build/test dependencies
- External services
- Version policy
- Upgrade and risk notes
- Dependency notes per major package / app / feature when the repository has multiple areas

## Example Content
- Runtime: `next@14`, `contentful@10`
- External service: "Azure Key Vault for secret resolution"
- Package dependency note: "`apps/marketing-site` depends on Contentful, Algolia, and Vercel edge middleware for campaign landing pages."

## Validation
- Are versions sourced from manifests?
- Are high-risk dependencies flagged?
- When packages/features differ meaningfully, is it clear which dependency groups matter to which area and why?

## Missing Information
- Unknown transitive dependency risks
- Missing EOL policy references
- Dependency found, but owning package/feature context is still unclear
