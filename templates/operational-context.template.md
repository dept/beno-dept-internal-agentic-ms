# Operational Context Template

## Purpose
Document runtime operations, observability, service levels, and support responsibilities.

## Required Sections
- Hosting model
- Logging/metrics/tracing tools
- Alerting and on-call model
- SLO/SLA indicators
- Backup and recovery notes

## Example Content
- Hosting: Azure App Service + Azure Front Door
- Monitoring: Application Insights dashboards and alerts

## Validation
- Are alerts linked to actionable runbooks?
- Are SLO metrics measurable from existing telemetry?

## Missing Information
- Missing disaster recovery RTO/RPO values
- Unknown ownership for low-priority alerts
