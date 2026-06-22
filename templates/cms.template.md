# CMS Template

## Purpose
Describe CMS architecture, content lifecycle, and operational dependencies.

## Required Sections
- CMS platform and spaces/environments
- Content model summary
- Delivery and preview flow
- Publishing and webhook behavior
- Cache invalidation strategy
- If the repository has multiple brands, campaigns, or content surfaces, a short explanation of which CMS areas feed which package/app/feature

## Example Content
- Platform: Contentful
- Preview: separate host using preview tokens and draft content API
- Area summary: "Campaign landing pages pull hero, CTA, and localization content from the marketing space, while checkout content uses a separate commerce-managed model."

## Validation
- Are content environments mapped to deployment environments?
- Are webhook endpoints and retry behavior documented?
- Is it clear which content models or spaces matter to which user-facing package/feature/campaign?

## Missing Information
- Missing model ownership matrix
- Unclear cache purge latency expectations
- Content source identified, but consumer package/feature mapping is still unclear
