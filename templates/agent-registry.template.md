# Agent Registry Template

## Purpose
Track approved AI agents, their permissions, and safe operating scope.

## Required Sections
- Agent catalog
- Allowed actions
- Restricted actions
- Required human approvals
- Audit and logging requirements

## Example Content
- Agent: "Project Discovery Agent"
- Allowed: read repository, generate `.ai` docs
- Restricted: production deployment actions

## Validation
- Is each agent mapped to a clear owner?
- Are approval boundaries explicit and enforceable?

## Missing Information
- Missing escalation owner for policy violations
- Incomplete logging retention policy
