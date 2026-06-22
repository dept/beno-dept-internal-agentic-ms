# AI Project Discovery — Tool-Agnostic Logic

> This file defines the Discovery Agent's workflow independently of any specific AI tool.
> Tool-specific wrappers (Copilot, Claude, Hermes) reference this logic.

## Purpose

Generate a complete `.ai/` folder for any repository using evidence from code, configuration, infrastructure, and operations artifacts.

## Input Requirements

- Access to the full repository filesystem
- Network access (for registry queries in Step 10)
- Optionally: Confluence access (for Step 9)

## Workflow (10 Steps)

### Step 1: Agentic Setup Inventory

Scan for existing AI/agent configurations before generating new files.

**Scan locations:**
- `.github/agents/`, `.agents/`, `.claude/agents/`, `AGENTS.md`
- `.github/copilot-instructions.md`, `.github/instructions/`, `CLAUDE.md`, `.cursor/rules/`
- `.github/prompts/`, `.github/skills/`, `.claude/skills/`
- `.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`

**Output:** Inventory list (file path, name, tool, scope, purpose)

### Step 2: Repository Analysis

Understand the project structure:
- Identify if monorepo (check `turbo.json`, `pnpm-workspace.yaml`, root `package.json#workspaces`)
- Map all packages/services
- Identify primary language(s) and framework(s)
- Identify deployment targets

**Exclude:** `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/`, `.git/`, `coverage/`

### Step 3: Architecture Discovery

Map the system topology:
- Service boundaries and communication patterns
- External system integrations
- Data flow between components
- Runtime environment (cloud services, containers, serverless)

**Output:** Mermaid diagram + prose description

### Step 4: Dependency Discovery

Inventory all dependencies:
- Read all manifest files (package.json, *.csproj, pyproject.toml, go.mod, etc.)
- Classify: runtime vs dev vs platform
- Assess risk (lock-in, EOL, security)
- Note upgrade paths

### Step 5: Deployment & Operations Discovery

Map the deployment pipeline:
- CI/CD configuration (GitHub Actions, Azure Pipelines, etc.)
- Environments (dev, staging, production)
- Promotion flow and rollback strategy
- Monitoring and alerting setup

### Step 6: CMS Discovery

If CMS is detected:
- CMS platform and SDK versions
- Content models and types
- Webhooks and publishing flow
- Caching strategy
- Preview/draft handling

### Step 7: Coding Standards Discovery

Extract conventions from config:
- Linting and formatting rules
- Testing framework and coverage requirements
- Git workflow (branching, PR process)
- Type checking and build configuration

### Step 8: .ai/ Folder Generation

Generate all 9 required files + .meta.yml:

| File | Content Source |
|------|--------------|
| `project-context.md` | Steps 2 + onboarding links |
| `architecture.md` | Step 3 |
| `runbooks.md` | Step 5 + incident patterns |
| `dependencies.md` | Step 4 |
| `cms.md` | Step 6 |
| `operational-context.md` | Step 5 |
| `coding-standards.md` | Step 7 |
| `agent-registry.md` | Step 1 |
| `onboarding.md` | Collected links + setup steps |
| `.meta.yml` | Standard version + timestamp |

**Quality requirements per file:**
- Evidence-first: cite source files for all claims
- Mark assumptions with `Assumption:` tag
- Rate confidence per section: `Confidence: <0-100>%`
- Add `Validation Questions` for gaps
- No empty sections — explicit unknowns instead

### Step 9: AI Context Wiring + Confluence

Wire IDE tools to load `.ai/` context:
- `.github/copilot-instructions.md` (create or append)
- `CLAUDE.md` (create or append)
- `.github/instructions/ai-context.instructions.md` (create)

Optionally create Confluence pages under `MS/Projects` using a consistent layout:
- Main page: `[Project Name]`
- Subpages: `Overview`, `Architecture & Package Map`, `Environments & Access`, `Onboarding & Handover`
- Sanitize titles so encoded entities like `&amp;` or `@amp;` never appear in page names
- Include package / feature / campaign inventory when the project has multiple areas
- For monorepos or multi-area projects, include both a quick table and a short plain-language summary for each package/feature/campaign so a new developer understands purpose, not just names
- Prefer `doc/` or `docs/` as primary context for Confluence wording and onboarding details when those folders exist

### Step 10: Stack-Aware Developer Setup

For each detected technology:
1. Search with `gh skill search <technology-name> --owner <vendor-org>` and install the selected vendor-owned skill with `gh skill install <owner>/<repo> <skill-name> --dir .github/skills`
2. If no authoritative result exists, generate a local fallback skill so each detected core technology still ends with a `.github/skills/<technology-name>/SKILL.md`
3. Check DEPT MCP registry for servers
4. Fallback to public MCP registry
5. Write MCP config to all three IDE files
6. Generate support-agent with detected tools

## Quality Gates

Before declaring complete:
- [ ] 9 `.ai/` files generated (no stubs)
- [ ] `.meta.yml` created with standard version
- [ ] AI wiring files created/updated
- [ ] Skill file exists for every detected core technology (or explicit skip reason recorded)
- [ ] MCP servers installed where available
- [ ] Support agent created
- [ ] No secrets in any generated file
