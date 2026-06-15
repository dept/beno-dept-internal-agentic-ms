---
description: "Bootstrap DEPT AI tooling into a new project — fetches discovery and maintainer agents, installs them into .github/agents/, then runs full project discovery and generates .ai/ context files."
---

You are bootstrapping DEPT Agentic Standards into this project.

**Critical:** Write all output as actual files to the repository on disk. Do not write to session files or summarise in chat only. Follow superpowers:writing-skills discipline: evidence first, no hallucination, all unknowns flagged explicitly.

**Exclude from analysis:** `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/`, `.git/`, `coverage/`, `.cache/`, `.pnpm-store/`

**For monorepos:** Read `turbo.json`, `pnpm-workspace.yaml`, or root `package.json#workspaces` first. List all packages and treat each as a named service boundary before beginning per-package analysis.

## Step 0 — Install DEPT agents into this project

Fetch the following files from the DEPT Agentic Standards repo and write them to the paths shown. **Skip any file that already exists.**

| Source URL | Write to |
|---|---|
| `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/ai-project-discovery.agent.md` | `.github/agents/ai-project-discovery.agent.md` |
| `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/ai-project-maintainer.agent.md` | `.github/agents/ai-project-maintainer.agent.md` |
| `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/bootstrap-project-context.prompt.md` | `.github/prompts/bootstrap-project-context.prompt.md` |

Create `.github/agents/` and `.github/prompts/` directories if they do not exist.

After writing all files, continue with the steps below.

## Step 0.5 — Install required superpowers skills

The agents and instructions installed in Step 0 reference superpowers skills using `/superpowers:` notation. These skills must be available locally for the agents to reference them.

Fetch the following required skills from the DEPT Agentic Standards repo and write them to `.github/skills/`:

| Skill Name | Source URL | Write to |
|---|---|---|
| writing-skills | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/writing-skills/SKILL.md` | `.github/skills/writing-skills/SKILL.md` |
| systematic-debugging | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/systematic-debugging/SKILL.md` | `.github/skills/systematic-debugging/SKILL.md` |
| verification-before-completion | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/verification-before-completion/SKILL.md` | `.github/skills/verification-before-completion/SKILL.md` |
| test-driven-development | `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/agents/test-driven-development/SKILL.md` | `.github/skills/test-driven-development/SKILL.md` |

Create `.github/skills/` directory if it does not exist. **Skip any skill that already exists.**

These skills provide discipline and patterns that the agents reference. After writing them, verify that agents can load the skills when `/superpowers:skill-name` is referenced.

## Step 1 — Agentic setup inventory

Before generating any files, scan the repository for existing agentic configuration:

- **Agents**: `.github/agents/*.agent.md`, `.agents/`, `.claude/agents/`, `AGENTS.md`
- **Instructions**: `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `CLAUDE.md`, `.cursor/rules/`
- **Prompts / Skills**: `.github/prompts/*.prompt.md`, `.github/skills/`, `.claude/skills/`
- **MCP**: `.vscode/mcp.json` (VS Code), `.cursor/mcp.json` (Cursor), `.mcp.json` (Claude Code root), any `mcpServers` block in VS Code settings

Record all findings — they will be documented in `agent-registry.md` and used to decide whether to create or append wiring files.

## Step 1.5 — Collect Handover and Onboarding Links

Collect the links needed for handover and onboarding:
- GitHub repository URL
- Test environment URL
- Acceptance (acc) environment URL
- Production (prod) environment URL
- Keeper URL (or equivalent source for `.env` values)

Do not ask the user for a Confluence URL. The Confluence location is always created under:
- `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

If any GitHub, environment, or Keeper link cannot be verified from codebase/config evidence, prompt the user for the missing values.

Store this information for `.ai/` generation and Confluence documentation creation.

## Step 2 — Generate `.ai/` context files

Generate and write all nine files to `.ai/`:
- `project-context.md`
- `architecture.md`
- `runbooks.md`
- `dependencies.md`
- `cms.md`
- `operational-context.md`
- `coding-standards.md`
- `agent-registry.md`
- `onboarding.md`

For each file:
1. Start from root config files. Map all packages/apps first.
2. Extract evidence from source code, config, CI/CD, and infrastructure files.
3. Include the onboarding links collected in Step 1.5 where relevant:
  - GitHub and Keeper references in `onboarding.md` and `project-context.md`
  - Environment URLs in `operational-context.md`
4. Populate every section — no placeholders, no empty sections.
5. Include `Assumption:` tags, `Confidence: <0-100>%`, and `Validation Questions` per major section.
6. Cite source evidence using file paths and config names.
7. Redact any secrets or privileged credentials.

## Step 3 — Wire AI context for all tools

After generating `.ai/`, create the following wiring files so every AI tool automatically loads the context. **Check each file first — append if it exists, create if not. Never overwrite existing content.**

**`.github/copilot-instructions.md`**
- Not present: create with full `.ai/` reading instructions and behaviour rules.
- Already present: append a clearly delimited `## AI Project Context (.ai/)` section at the end.

**`CLAUDE.md`** (repository root)
- Not present: create with the same `.ai/` reading instructions in Claude's expected format.
- Already present: append a `## AI Project Context (.ai/)` section at the end.

**`.github/instructions/ai-context.instructions.md`**
- Not present: create with `applyTo: "**"` frontmatter and concise `.ai/` loading instructions.
- Already present: leave unchanged — report as already present in the completion summary.

All wiring files must instruct the AI to:
1. Read `.ai/` files at the start of every session
2. Cross-reference `.ai/` with any existing agents, instructions, and prompts found in Step 0
3. Respect constraints and scopes defined in existing agentic files
4. Flag contradictions between `.ai/` and codebase rather than silently accepting stale context

## Step 3.5 — Create Confluence Project Documentation

After `.ai/` files are generated and AI wiring is complete, create project documentation in Confluence.

Target location:
- Space: `MS`
- Parent path: `Projects`
- Base URL: `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

Rules:
1. Ensure the `Projects` directory path exists. Create missing pages in that path when required.
2. Create a project page under `Projects` if it does not exist yet.
3. Create readable, role-friendly documentation for developers and client managers. Keep it practical and not overly technical.
4. Prefer a subpage structure for readability, for example:
   - Overview
   - Environments and Access
   - Onboarding and Handover
5. Include GitHub URL, environment URLs, and Keeper URL (or equivalent secrets-location reference).
6. If GitHub/environment/Keeper links are still unknown, prompt the user before finalizing pages.
7. Do not create a separate coding standards page in Confluence unless explicitly requested.

## Step 4 — Completion summary

After all files are written, output:
```
## Bootstrap Complete

### Agents installed
[list each .github/agents/*.agent.md created, or "Already present"]

### Superpowers skills installed
- writing-skills
- systematic-debugging
- verification-before-completion
- test-driven-development
[Or note if already present]

### .ai/ files created
[list each file]

### AI wiring files created/updated
[list each file with action: created / appended / already present]

### MCP servers added
[list any entries merged into .vscode/mcp.json, .cursor/mcp.json, .mcp.json — or "None"]

### Project dev agent
[created / already present]

### Existing agentic setup found
[list files found in Step 0, or "None found"]

### Handover and Access Links
[list GitHub URL, test URL, acc URL, prod URL, Keeper URL collected or "Missing: <fields>"]

### Confluence Pages
[list created/updated pages under MS/Projects, or "None"]

### Validation Questions to resolve
[list open questions from all .ai/ files]

### Next steps
- Review .ai/ files and resolve Validation Questions
- Commit to a feature branch and open a PR
- Run AI Project Maintainer Agent after each sprint
```
