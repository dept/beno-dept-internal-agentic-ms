# Discovery Agent — Tool-Agnostic Logic

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
- Accessibility target (a11y tooling, semantic/aria patterns, contrast rules; documented WCAG level, else DEPT baseline WCAG 2.2 Level AA)

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

Optionally create Confluence pages under `MS/Projects` using a consistent layout. Titles follow the
collision-safe rule (see `docs/confluence-page-standard.md` → *Page titles*): landing = project name
(no affix); subpages **prefixed with the landing title** — `<landing title> - <subpage>`:
- Main page: `[Project Name]`
- Subpages: `[Project Name] - Overview`, `[Project Name] - Architecture & Package Map`, `[Project Name] - Environments & Access`, `[Project Name] - Onboarding & Handover`
- Sanitize titles so encoded entities like `&amp;` or `@amp;` never appear in page names
- Include package / feature / campaign inventory when the project has multiple areas
- For monorepos or multi-area projects, include both a quick table and a short plain-language summary for each package/feature/campaign so a new developer understands purpose, not just names
- Prefer `doc/` or `docs/` as primary context for Confluence wording and onboarding details when those folders exist

### Step 10: Stack-Aware Developer Setup

For each detected technology:
1. Try a vendor skill first via `gh skill search <technology-name> --owner <vendor-org>` then `gh skill install <owner>/<repo> <skill-name> --dir .github/skills --force` — `gh skill` is a real, built-in (preview) GitHub CLI feature. If `gh skill` is unavailable (older `gh`) or returns no authoritative vendor-org match, fall through to generation. Never fabricate a vendor source when the command didn't run.
2. Generate a code-verified skill so each detected core technology ends with a `.github/skills/<technology-name>/SKILL.md`. `.ai/` says which files to inspect; the skill's symbols/paths/code samples must be verified against actual source (`grep` symbols, `ls` paths, copy from real call sites) — never written from `.ai/` prose or framework convention. Mark anything unverifiable with `Assumption:`.
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
- [ ] Every symbol/path/code sample in each generated skill re-verified against real source (no invented APIs, no unchecked paths, no empty sections)
- [ ] MCP servers installed where available
- [ ] Support agent created
- [ ] No secrets in any generated file
