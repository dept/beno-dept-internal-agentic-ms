# Coding Standards Template

## Purpose
Capture coding conventions and quality gates that AI agents must follow when proposing changes.

## Required Sections
- Language and style conventions
- Linting and formatting rules
- Testing requirements
- Branching/PR expectations
- Security and compliance checks
- Accessibility target (WCAG level) — DEPT baseline is WCAG 2.2 Level AA

## Example Content
- Style: TypeScript strict mode enabled, ESLint + Prettier enforced
- Testing: minimum unit coverage for modified modules
- Accessibility: front-end changes meet WCAG 2.2 Level AA (semantic HTML, keyboard nav, colour contrast, focus management)

## Validation
- Are standards sourced from repository configuration?
- Are mandatory CI checks clearly listed?

## Missing Information
- Missing exception process for urgent hotfixes
- Unclear test coverage threshold by package
