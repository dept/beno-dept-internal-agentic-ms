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

## Critical Output Rule

Always write output files directly to `.ai/` in the repository root as actual files on disk. Never write to session files, temporary files, or chat output only. If `.ai/` does not exist, create it.

## Analysis Scope

**Always exclude** from analysis:
- `node_modules/`, `.pnpm-store/`, `.yarn/`, `bun.lockb`
- `.git/`, `.next/`, `.turbo/`, `dist/`, `build/`, `out/`, `.cache/`
- `coverage/`, `.nyc_output/`, `storybook-static/`

**For monorepos**, identify the workspace root first:
- Look for `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, or `workspaces` field in root `package.json`
- List all workspace packages before beginning per-package analysis
- Treat each package as a named service boundary in `architecture.md`
- Record the monorepo tool and task runner in `project-context.md`

## Operating Procedure

### 0) Agentic Setup Inventory

Before any other analysis, scan the repository for existing agentic configuration. Record findings in `agent-registry.md` under **Existing Agentic Setup**.

Scan these locations:

**Agents**: `.github/agents/*.agent.md`, `.agents/`, `.claude/agents/`, `AGENTS.md`

**Instructions**: `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `CLAUDE.md`, `.cursor/rules/`

**Prompts / Skills**: `.github/prompts/*.prompt.md`, `.github/skills/`, `.claude/skills/`

**MCP configuration**: `.github/mcp.json`, `.mcp.json`, `mcp.json`, any `mcpServers` block in VS Code workspace settings

For each file found, record: file path, name/description, target tool, scope, and purpose.

When creating wiring files later: check these findings first. Never overwrite existing content — append only.

### 1) Repository Analysis

- Start from the repository root. Read `package.json`, `turbo.json`, `nx.json`, `pnpm-workspace.yaml` first.
- Identify languages, frameworks, package managers, and service boundaries.
- Detect monorepo vs single-service layout. For monorepos, enumerate all packages explicitly.
- Locate API, frontend, worker, shared library, database, and email components.

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

### 9) AI Context Wiring

Create or update wiring files so every AI tool automatically reads `.ai/`. Check each file first — append if present, create if not.

- **`.github/copilot-instructions.md`**: Instruct Copilot to read `.ai/` every session. Append if already exists.
- **`CLAUDE.md`** (root): Same for Claude Code. Append if already exists.
- **`.github/instructions/ai-context.instructions.md`**: `applyTo: "**"` file that loads `.ai/` for every Copilot file interaction. Skip if already present.

## Quality Gates

Before finalizing output, verify:
1. No required `.ai` files are missing.
2. Every major claim has a source reference.
3. Unknowns are listed as questions, not silent omissions.
4. Security-sensitive details are redacted.
5. All three AI wiring files are created or updated.
6. Existing agentic configuration is documented in `agent-registry.md`.

## Output Style Requirements

- Use concise, implementation-focused language.
- Avoid generic AI buzzwords.
- Prefer bullet lists and short tables.
- Use Mermaid diagrams for architecture or flow where useful.
