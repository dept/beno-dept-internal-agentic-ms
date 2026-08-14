# Onboarding Template

## Purpose
Enable rapid and consistent onboarding for engineers and AI agents to project delivery and operations.

## Required Sections
- First-day setup
- Access prerequisites
- Local run/test instructions
- Deployment and release orientation
- Support and escalation orientation
- **Platform Access Links**: the single home for every URL and access link in the project. GitHub, environment URLs (test/acceptance/prod), Keeper, plus a link for each detected CMS (e.g. Contentful space), cloud/hosting platform (e.g. Azure Portal, AWS/GCP console, Vercel), and design platform (Figma file/project, when Figma clues are present). Include a row only for platforms the project actually uses; use `[Fill in]` when a used platform's exact URL is unconfirmed. `cms.md` and `operational-context.md` point here rather than repeating URLs.

If a package needs a note here, write only what is specific to this file's topic and to that
package: what a newcomer has to do to run it. The package's purpose is in `architecture.md`.

## Writing rules

`standards/writing-rules.md` governs this file. Read it before writing. It is not restated here.

## Ownership header

The generated file opens with this block, immediately after the H1:

> **Owned by this file:** every URL and access link in the project (repository, environments, CMS
> console, secret store, dashboards), first-day setup, the local development workflow, and
> contacts. This is the authoritative source and the single home for URLs.
> **Not carried here:** explanations of what the systems behind those URLs do (the file that owns
> each topic); coding rules (`coding-standards.md`).

## Example Content
- Setup: "Install Node LTS, authenticate Azure CLI, configure env vars from Key Vault"
- Run: "npm ci && npm run dev"
- Local note: "`packages/design-system` must be built once (`pnpm --filter design-system build`) before the storefront apps will start."

## Validation
- Can a new engineer run the project using this guide only?
- Are critical access dependencies and lead times documented?
- Does every URL the project uses appear here, and only here?
- Does the file pass every rule in `standards/writing-rules.md`?

## Missing Information
- Missing least-privilege access matrix
- Unclear onboarding owner for rotating support roster
