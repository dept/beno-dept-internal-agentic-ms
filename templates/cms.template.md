# CMS Template

## Purpose
Describe CMS architecture, content lifecycle, and operational dependencies.

## Required Sections
- CMS platform and spaces/environments
- Content model summary
- Delivery and preview flow
- Publishing and webhook behavior
- Cache invalidation strategy
- CMS admin/console link: pointer only, to `onboarding.md` -> Platform Access Links, which is the single home for URLs

If a package needs a note here, write only what is specific to this file's topic and to that
package. The package's purpose is in `architecture.md`.

## Writing rules

`standards/writing-rules.md` governs this file. Read it before writing. It is not restated here.

## Ownership header

The generated file opens with this block, immediately after the H1:

> **Owned by this file:** the content model and types, editorial workflow, publish and preview
> behaviour, the cache or revalidation consequences of publishing, and CMS-side integrations.
> This is the authoritative source.
> **Not carried here:** the CMS console URL (`onboarding.md`); which package renders what
> (`architecture.md`).

## Example Content
- Platform: Contentful
- Preview: separate host using preview tokens and draft content API
- Content model note: "The `campaignHero` type is published from the marketing space; checkout content uses a separate commerce-managed model with its own publish webhook."

## Validation
- Are content environments mapped to deployment environments?
- Are webhook endpoints and retry behavior documented?
- Does the file pass every rule in `standards/writing-rules.md`?

## Missing Information
- Missing model ownership matrix
- Unclear cache purge latency expectations
