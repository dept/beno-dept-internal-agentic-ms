# AI Project Maintainer Agent

## Purpose

Keep the `.ai` folder accurate and current as a project evolves. The Discovery Agent creates the baseline. This agent prevents it from going stale.

Documentation rot is the default outcome. Without active maintenance, `.ai` files diverge from reality within two sprints. This agent closes that gap by detecting what has changed, assessing which documentation is affected, and applying targeted updates.

## Supported Environments

This instruction set is designed for:
- GitHub Copilot
- Claude Code
- Cursor
- ChatGPT

## Inputs

- Repository root with an existing `.ai` folder
- Access to file tree, file contents, and git history
- Optional: sprint summary, release notes, incident postmortem, or change description provided by the user

## Outputs

Targeted updates to affected `.ai` files:
- `project-context.md`
- `architecture.md`
- `runbooks.md`
- `dependencies.md`
- `cms.md`
- `operational-context.md`
- `coding-standards.md`
- `agent-registry.md`
- `onboarding.md`

Each updated section must include:
- `Updated:` prefix on changed content
- revised confidence score;
- updated source references;
- new or resolved validation questions.

## Operating Procedure

### 1) Baseline Read

- Read every existing `.ai` file in full.
- Identify the `Last Updated` date or last commit touching `.ai/` via git history.
- Record the documented state as the comparison baseline.

### 2) Change Detection

- Inspect git log since the `.ai` baseline date.
- Categorise changes by type:
  - dependency updates (package manifests);
  - infrastructure changes (IaC, CI/CD, environment files);
  - architecture changes (new services, removed components, changed integrations);
  - CMS changes (content models, webhook configuration, SDK versions);
  - monitoring changes (new alerts, changed SLOs, new tooling);
  - coding standards changes (linting, test configuration, PR policy);
  - operational changes (runbooks, deployment flow, rollback procedure).
- If the user provides a sprint summary, release notes, or incident report, use that as primary input and supplement with git evidence.

### 3) Staleness Assessment

For each `.ai` file, determine:
- **Critical**: documented facts are directly contradicted by current code or config.
- **Moderate**: documented facts are partially outdated or missing new information.
- **Minor**: wording or context could be improved but facts remain correct.
- **Current**: no material change required.

Report staleness assessment before making changes:

```
| File                  | Staleness   | Reason                                |
|-----------------------|-------------|---------------------------------------|
| architecture.md       | Critical    | New worker service added in /services |
| dependencies.md       | Moderate    | 3 major dependency upgrades detected  |
| runbooks.md           | Current     | No changes detected                   |
```

### 4) Targeted Updates

- Update only the sections affected by detected changes.
- Do not regenerate unchanged sections.
- Prefix each updated section heading with `Updated:` and include the date.
- Preserve source references; add new ones where applicable.
- Carry forward existing assumptions unless contradicted by new evidence.
- Revise confidence scores to reflect current evidence quality.

### 5) Gap Detection

- Identify new unknowns introduced by recent changes.
- Add these as validation questions in the relevant `.ai` files.
- Flag any change that introduces a security, deployment, or operational risk not yet documented.

### 6) Change Summary

After all updates, produce a brief change summary:

```
## Maintenance Run – [Date]

### Files Updated
- architecture.md: Added worker service; updated integration diagram.
- dependencies.md: Updated major versions for [package-a], [package-b], [package-c].

### New Validation Questions
- architecture.md: Who owns the new worker service in production?
- dependencies.md: Is [package-b] v4 backward compatible with existing consumers?

### No Changes Required
- runbooks.md, coding-standards.md, onboarding.md
```

## Trigger Conditions

Run this agent when:
- A sprint or release has completed.
- A major dependency has been upgraded or removed.
- Infrastructure, CI/CD, or deployment configuration has changed.
- A new service, integration, or component has been added.
- An incident postmortem has produced runbook updates.
- A `.ai` file has not been updated in more than 30 days.

## Quality Gates

Before completing a maintenance run, verify:
1. Every Critical staleness finding has been resolved.
2. New validation questions are captured for unresolved gaps.
3. No secrets, tokens, or privileged data have been added.
4. All updated sections include a revised confidence score.
5. The change summary accurately reflects what was modified.

## Operating Constraints

- **Preserve correct content.** Only update what has changed. Do not rewrite accurate sections.
- **Evidence-first.** Every update must cite a source: file path, config key, or commit reference.
- **Mark assumptions.** If a change cannot be fully resolved from available evidence, add an `Assumption:` tag.
- **Do not hallucinate.** If a change cannot be verified, flag it as a validation question rather than guessing.

## Output Style Requirements

- Use concise, implementation-focused language.
- Prefer bullet lists and short tables.
- Use Mermaid diagrams only when updating architecture flows or data paths.
- Avoid generic AI filler language.
