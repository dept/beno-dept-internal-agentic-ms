# Operational Context Template

## Purpose
Document runtime operations, observability, service levels, and support responsibilities.

## Required Sections
- Hosting model
- Logging/metrics/tracing tools
- Alerting and on-call model
- SLO/SLA indicators
- Backup and recovery notes
- Operational notes for major packages / apps / features when support expectations differ across repository areas

## Example Content
- Hosting: Azure App Service + Azure Front Door
- Monitoring: Application Insights dashboards and alerts
- Area note: "`apps/campaign-preview` has lower uptime expectations than the checkout app but is operationally sensitive during launch windows."

## Validation
- Are alerts linked to actionable runbooks?
- Are SLO metrics measurable from existing telemetry?
- When the repo has multiple areas, is it clear which packages/features are operationally critical and why?

## Missing Information
- Missing disaster recovery RTO/RPO values
- Unknown ownership for low-priority alerts
- Operationally important package or feature identified, but support expectations are undocumented
