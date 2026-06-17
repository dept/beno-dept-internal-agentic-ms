---
description: "Migrate any project into DEPT Managed Services standards. Orchestrates 4 phases: install, discover, integrate, stack-tooling. Each phase is self-contained and idempotent."
---

# Migrate Project to DEPT Managed Services Standards

You are running the **DEPT Managed Services Migration** workflow. This orchestrates 4 phases to transform any repository into an AI-ready Managed Services project.

## What You'll Get

After this workflow completes:
- ✓ Complete `.ai/` documentation (9 files covering architecture, operations, standards, and onboarding)
- ✓ AI agents installed and ready to use (discovery and maintainer agents)
- ✓ Superpowers skills available (evidence-first discipline, systematic debugging, verification, TDD)
- ✓ All AI tools wired (Copilot, Claude, Cursor auto-load `.ai/` context)
- ✓ Confluence handover pages created
- ✓ Stack-specific skills and MCP servers installed
- ✓ Project developer agent configured

**Time estimate:** 15-30 minutes depending on repository complexity.

## Critical Disciplines

**Write all output as actual files to the repository on disk.** Do not write to session files or summarize in chat only.

**Follow superpowers:writing-skills discipline:**
- Evidence first: only cite what you find in code, config, and infrastructure
- No hallucination: mark unknowns explicitly
- All claims traceable to source files

**Exclude from analysis:** `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/`, `.git/`, `coverage/`, `.cache/`, `.pnpm-store/`

**For monorepos:** Read `turbo.json`, `pnpm-workspace.yaml`, or root `package.json#workspaces` first.

## How to Start This Migration

**You need a local copy of this prompt to run it.** AI tools read prompt files from the local workspace — they cannot fetch and execute a remote URL directly. Phase 1 will download this file into the project's `.github/prompts/` folder so future runs can use the local copy.

### If you don't have it locally yet

**Option A — One-liner bootstrap (any terminal):**
```bash
curl -sL "https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate.prompt.md" \
  -o ".github/prompts/migrate.prompt.md" && mkdir -p .github/prompts
```
Then invoke it in your AI tool:
```
# VS Code Copilot / Cursor
@workspace /migrate

# Claude Code
claude --prompt .github/prompts/migrate.prompt.md

# Any tool with file access
Read .github/prompts/migrate.prompt.md and follow the instructions.
```

**Option B — Claude Code or any tool with web access (fetch directly):**
```
Fetch https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate.prompt.md and follow the instructions in it.
```
Claude Code and web-enabled agents can read a raw URL directly. The result is the same — the agent reads the prompt content and executes it.

**Option C — Copilot Chat in browser (github.com/copilot):**
Paste the raw URL into the chat and ask Copilot to read and follow it.

---

## Phase Execution

Execute each phase in order. Each phase is self-contained — if interrupted, restart from the last incomplete phase.

**Base URL for GitHub-hosted prompts:**
```
https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/
```

### Phase 1: Installation
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/01-install.prompt.md`
**Does:** Fetches agents, installs superpowers skills
**Verify before continuing:** `.github/agents/` has 2 files, `.github/skills/` has 4 directories

### Phase 2: Discovery & Analysis
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/02-discover.prompt.md`
**Does:** Scans agentic config, collects onboarding links, generates 9 `.ai/` files + `.meta.yml`
**Verify before continuing:** `.ai/` has 9 files + `.meta.yml`, no placeholder markers

### Phase 3: Integration
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/03-integrate.prompt.md`
**Does:** Wires AI tools (Copilot, Claude, Cursor), creates Confluence documentation
**Verify before continuing:** Wiring files reference `.ai/`, Confluence pages exist

### Phase 4: Stack-Aware Tooling
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/04-stack-tooling.prompt.md`
**Does:** Detects tech stack, installs skills + MCP servers, creates project dev agent
**Verify before continuing:** MCP config in all 3 IDEs, project-dev-agent exists

---

## Completion Summary

After all phases complete, output:

```
## Migration Complete ✓

### Phase 1: Installation
- Agents: [installed / already present]
- Skills: [installed / already present]

### Phase 2: Discovery
- .ai/ files: 9/9 generated
- .meta.yml: created (standard v1.0.0)
- Confidence: [average % across files]

### Phase 3: Integration
- Copilot wiring: [created / appended / present]
- Claude wiring: [created / appended / present]
- VS Code wiring: [created / present]
- Confluence: [created / skipped]

### Phase 4: Stack-Aware Tooling
- Technologies detected: [count]
- Skills installed: [list or "None matched"]
- MCP servers added: [list or "None"]
- Project developer agent: [created / present]

### Validation
Run: scripts/validate.sh .
Result: [COMPLIANT / WARNINGS / NOT COMPLIANT]

### Next Steps
1. Review .ai/ files and resolve Validation Questions
2. Commit changes to a feature branch
3. Open a pull request for team review
4. After merging, run AI Project Maintainer Agent after each sprint
```

---

## Troubleshooting

| Issue | Resolution |
|-------|-----------|
| Phase fails partway through | Re-run that phase only — each is idempotent |
| Network error fetching agents | Check GitHub access; try manual download |
| Confluence access denied | Skip Phase 3 Step 7; create pages manually later |
| No skills found for stack | Expected for niche tech; MCP registry is the primary value |
| validate.sh reports warnings | Run Maintainer Agent to address quality issues |
