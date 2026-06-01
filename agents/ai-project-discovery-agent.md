# AI Project Discovery Agent

## Related Agent

This agent generates the `.ai` baseline. To keep it current after the project evolves, use the **AI Project Maintainer Agent** (`agents/ai-project-maintainer-agent.md`).

Generate a complete, review-ready `.ai` folder for any repository using evidence from code, configuration, infrastructure, and operations artifacts.

## Supported Environments

This instruction set is designed for:
- GitHub Copilot
- Claude Code
- Cursor
- ChatGPT

## Inputs

- Repository root
- Access to file tree and file contents
- Optional CI/CD and cloud configuration access

## Outputs

Generate and populate the following files in `.ai/`:
- `project-context.md`
- `architecture.md`
- `runbooks.md`
- `dependencies.md`
- `cms.md`
- `operational-context.md`
- `coding-standards.md`
- `agent-registry.md`
- `onboarding.md`

Each output must include:
- assumptions;
- confidence scores per major section;
- validation questions for unknowns.

## Operating Procedure

### 1) Repository Analysis

- Identify languages, frameworks, package managers, and service boundaries.
- Detect monorepo vs single-service layout.
- Locate API, frontend, worker, and shared library components.

### 2) Architecture Discovery

- Extract runtime topology from source and infrastructure definitions.
- Identify external systems and trust boundaries.
- Document data flows and integration points.

### 3) Dependency Discovery

- Parse dependency manifests.
- Group dependencies by runtime, build, test, and platform.
- Highlight critical vendor lock-in and upgrade risks.

### 4) Deployment Discovery

- Inspect CI/CD workflows, IaC, deployment scripts, and environment files.
- Document promotion flow (dev/test/stage/prod) and rollback strategy.

### 5) CMS Discovery

- Detect CMS SDKs, content models, webhooks, preview pipelines.
- Document cache invalidation and publishing flow.

### 6) Monitoring Discovery

- Detect logging, metrics, tracing, alerting, and incident tooling.
- Capture SLO indicators and escalation pathways where found.

### 7) Coding Standards Discovery

- Infer formatting, linting, testing, branching, and PR conventions.
- Record quality gates and mandatory checks.

### 8) `.ai` Folder Generation

- Populate all required files using repository evidence.
- Mark assumptions explicitly using `Assumption:` prefix.
- Add confidence scores using `Confidence: <0-100>%`.
- Add a final section of validation questions.

## Quality Gates

Before finalizing output, verify:
1. No required `.ai` files are missing.
2. Every major claim has a source reference.
3. Unknowns are listed as questions, not silent omissions.
4. Security-sensitive details are redacted.

## Output Style Requirements

- Use concise, implementation-focused language.
- Avoid generic AI buzzwords.
- Prefer bullet lists and short tables.
- Use Mermaid diagrams for architecture or flow where useful.
