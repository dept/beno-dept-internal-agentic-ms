# Architecture Template

## Purpose
Document system structure, runtime boundaries, and integration flows for safe AI-assisted changes.

## Required Sections
- Component inventory
- Runtime architecture diagram
- Data flow and trust boundaries
- External integrations
- Failure domains

## Example Content
- Components: Next.js web app, API routes, Azure Functions, Redis cache
- Integration: Contentful GraphQL API and webhook callbacks

## Validation
- Does every component map to real code or infra definitions?
- Are trust boundaries and external calls clearly identified?

## Missing Information
- Unknown internal network constraints
- Undocumented batch workers
