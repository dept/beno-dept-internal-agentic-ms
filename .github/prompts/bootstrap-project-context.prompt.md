---
agent: "AI Project Discovery Agent"
description: "Bootstrap a new project's .ai folder by running the AI Project Discovery Agent. Analyzes the repository and generates all nine .ai context files plus AI wiring files."
---

Run the **AI Project Discovery Agent** on this repository.

**Critical:** Write all output as actual files to the repository on disk. Do not write to session files or summarise in chat only. If `.ai/` does not exist, create it.

**Exclude from analysis:** `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/`, `.git/`, `coverage/`, `.cache/`, `.pnpm-store/`

**For monorepos:** Read `turbo.json`, `pnpm-workspace.yaml`, or root `package.json#workspaces` first. List all packages and treat each as a named service boundary before beginning per-package analysis.

## Step 0 — Agentic setup inventory

Before generating any files, scan the repository for existing agentic configuration:

- **Agents**: `.github/agents/*.agent.md`, `.agents/`, `.claude/agents/`, `AGENTS.md`
- **Instructions**: `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `CLAUDE.md`, `.cursor/rules/`
- **Prompts / Skills**: `.github/prompts/*.prompt.md`, `.github/skills/`, `.claude/skills/`
- **MCP**: `.github/mcp.json`, `.mcp.json`, `mcp.json`, any `mcpServers` block in VS Code settings

Record all findings — they will be documented in `agent-registry.md` and used to decide whether to create or append wiring files.

## Step 1 — Generate `.ai/` context files

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
3. Populate every section — no placeholders, no empty sections.
4. Include `Assumption:` tags, `Confidence: <0-100>%`, and `Validation Questions` per major section.
5. Cite source evidence using file paths and config names.
6. Redact any secrets or privileged credentials.

## Step 2 — Wire AI context for all tools

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

## Step 3 — Completion summary

After all files are written, output:
```
## Bootstrap Complete

### .ai/ files created
[list each file]

### AI wiring files created/updated
[list each file with action: created / appended / already present]

### Existing agentic setup found
[list files found in Step 0, or "None found"]

### Validation Questions to resolve
[list open questions from all .ai/ files]

### Next steps
- Review .ai/ files and resolve Validation Questions
- Commit to a feature branch and open a PR
- Run AI Project Maintainer Agent after each sprint
```
