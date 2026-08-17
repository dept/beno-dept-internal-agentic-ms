# Operational Context Template

## Purpose
Document runtime operations, observability, service levels, and support responsibilities.

## Required Sections
- Hosting model
- Logging/metrics/tracing tools
- Alerting and on-call model
- SLO/SLA indicators
- Backup and recovery notes
- Environments and what each is for
- Cloud / hosting platform console link: pointer only, to `onboarding.md` -> Platform Access Links, which is the single home for URLs

If a package needs a note here, write only what is specific to this file's topic and to that
package. The package's purpose is in `architecture.md`.

## Writing rules

`standards/writing-rules.md` governs this file. Read it before writing. It is not restated here.

## Ownership header

The generated file opens with this block, immediately after the H1:

> **Owned by this file:** the environments and what each is for, deploy pipeline stages, the
> configuration and secret handling model, monitoring and alerting wiring, and the hosting model.
> This is the authoritative source.
> **Not carried here:** environment URLs and console links (`onboarding.md`); executable
> procedures (`runbooks.md`); per-package notes (`architecture.md`).

## Example Content
- Hosting: Azure App Service + Azure Front Door
- Monitoring: Application Insights dashboards and alerts
- Area note: "`apps/campaign-preview` is excluded from the production alert policy and pages nobody outside launch windows."

## Validation
- Are alerts linked to actionable runbooks?
- Are SLO metrics measurable from existing telemetry?
- Does the file pass every rule in `standards/writing-rules.md`?

## Missing Information
- Missing disaster recovery RTO/RPO values
- Unknown ownership for low-priority alerts
