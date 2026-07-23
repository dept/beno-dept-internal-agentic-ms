# Onboarding Template

## Purpose
Enable rapid and consistent onboarding for engineers and AI agents to project delivery and operations.

## Required Sections
- First-day setup
- Access prerequisites
- Local run/test instructions
- Deployment and release orientation
- Support and escalation orientation
- Quick orientation to the major apps / packages / features / campaigns a new developer will encounter
- **Platform Access Links** — the single home for platform console URLs: GitHub, environment URLs (test/acceptance/prod), Keeper, plus a link for each detected CMS (e.g. Contentful space), cloud/hosting platform (e.g. Azure Portal, AWS/GCP console, Vercel), and design platform (Figma file/project, when Figma clues are present). Include a row only for platforms the project actually uses; use `[Fill in]` when a used platform's exact URL is unconfirmed. `cms.md` and `operational-context.md` point here rather than repeating URLs.

## Example Content
- Setup: "Install Node LTS, authenticate Azure CLI, configure env vars from Key Vault"
- Run: "npm ci && npm run dev"
- Area summary: "`packages/design-system` provides shared UI components used by all storefront and campaign apps."

## Validation
- Can a new engineer run the project using this guide only?
- Are critical access dependencies and lead times documented?
- Does the onboarding guide explain what the major repo areas are for, not just how to start commands?

## Missing Information
- Missing least-privilege access matrix
- Unclear onboarding owner for rotating support roster
- Package or feature names listed elsewhere, but newcomer-facing explanations are missing
