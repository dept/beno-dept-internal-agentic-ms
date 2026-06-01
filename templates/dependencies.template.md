# Dependencies Template

## Purpose
Provide a structured inventory of technical dependencies and their operational impact.

## Required Sections
- Runtime dependencies
- Build/test dependencies
- External services
- Version policy
- Upgrade and risk notes

## Example Content
- Runtime: `next@14`, `contentful@10`
- External service: "Azure Key Vault for secret resolution"

## Validation
- Are versions sourced from manifests?
- Are high-risk dependencies flagged?

## Missing Information
- Unknown transitive dependency risks
- Missing EOL policy references
