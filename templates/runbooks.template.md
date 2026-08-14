# Runbooks Template

## Purpose
Capture repeatable operational procedures for incidents, releases, and maintenance tasks.

## Required Sections
- Incident triage
- Rollback process
- Scheduled operations
- Common failure signatures
- Escalation matrix

## Writing rules

`standards/writing-rules.md` governs this file. Read it before writing. It is not restated here.

## Ownership header

The generated file opens with this block, immediately after the H1:

> **Owned by this file:** the procedures someone executes, written as steps: incident triage,
> rollback, scheduled operations, known failure signatures, and the escalation path. This is the
> authoritative source.
> **Not carried here:** description of the deploy pipeline itself (`operational-context.md`);
> anything not written as steps.

## Example Content
- Triage: "Check Azure App Service health and latest deployment timestamp."
- Rollback: "Redeploy previous artifact from GitHub Actions run."

## Validation
- Are commands and links executable/current?
- Are escalation contacts accurate?
- Does the file pass every rule in `standards/writing-rules.md`?

## Missing Information
- Missing after-hours escalation details
- Unclear rollback SLA per environment
