# CMS Template

## Purpose
Describe CMS architecture, content lifecycle, and operational dependencies.

## Required Sections
- CMS platform and spaces/environments
- Content model summary
- Delivery and preview flow
- Publishing and webhook behavior
- Cache invalidation strategy

## Example Content
- Platform: Contentful
- Preview: separate host using preview tokens and draft content API

## Validation
- Are content environments mapped to deployment environments?
- Are webhook endpoints and retry behavior documented?

## Missing Information
- Missing model ownership matrix
- Unclear cache purge latency expectations
