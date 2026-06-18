---
description: "Migrate any project into DEPT Managed Services standards. Runs a non-blocking Graphify pre-pass plus 4 phases: install, discover, integrate, stack-tooling. Each phase is self-contained and idempotent."
---

# Migrate Project to DEPT Managed Services Standards

You are running the **DEPT Managed Services Migration** workflow. This runs a non-blocking Graphify pre-pass plus 4 phases to transform any repository into an AI-ready Managed Services project.

## What You'll Get

After this workflow completes:
- ✓ Complete `.ai/` documentation (9 files covering architecture, operations, standards, and onboarding)
- ✓ Discovery and Maintainer agents installed and ready to use
- ✓ Superpowers skills available (evidence-first discipline, systematic debugging, verification, TDD)
- ✓ All AI tools wired (Copilot, Claude, Cursor auto-load `.ai/` context)
- ✓ Confluence handover pages created
- ✓ Stack-specific skills and MCP servers installed
- ✓ Support agent configured
- ✓ Graphify structural pre-pass attempted before Discovery

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
mkdir -p .github/prompts && \
  curl -sL "https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate.prompt.md" \
  -o ".github/prompts/migrate.prompt.md"
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

## Graphify Pre-Pass (Default, Non-Blocking)

Before Phase 1, **attempt to run Graphify automatically** in the target repository. This keeps `/migrate` as the single entry point while improving Discovery quality on large or legacy repos.

### Default behavior
1. If `graphify` is already installed, run it first.
2. If it is not installed, prefer `uv tool install graphifyy`.
3. If `uv` is unavailable, try `pipx install graphifyy`.
4. If neither is available but Python is present, try `python3 -m pip install --user graphifyy` and run Graphify via `python3 -m graphify`.
5. If installation or execution fails, **continue the migration anyway** — Graphify is a strong accelerator, not a hard blocker.

### Command sequence
```bash
# from the target repository root
if command -v graphify >/dev/null 2>&1; then
  graphify . --wiki
elif command -v uv >/dev/null 2>&1; then
  uv tool install graphifyy && graphify . --wiki || true
elif command -v pipx >/dev/null 2>&1; then
  pipx install graphifyy && graphify . --wiki || true
elif command -v python3 >/dev/null 2>&1; then
  python3 -m pip install --user graphifyy && python3 -m graphify . --wiki || true
else
  echo "Graphify unavailable; continuing with raw-repo discovery"
fi
```

**Why `--wiki`?**
It produces `graphify-out/wiki/index.md`, which is easier for Discovery to traverse than raw JSON alone.

**Why is `python3 -m pip` last?**
Upstream warns plain `pip install` can create PATH/interpreter mismatches on some machines. DEPT only uses it as a fallback to keep `/migrate` as close as possible to a one-command workflow.

### After Graphify runs
- Read `graphify-out/GRAPH_REPORT.md` first
- Read `graphify-out/wiki/index.md` if present
- Read `graphify-out/graph.json` only when needed for structural verification
- Treat `graphify-out/` as **supplemental evidence** — verify important claims against actual repo files before writing `.ai/`

### Git hygiene
If `graphify-out/` was created, ensure it is ignored by default unless the team explicitly wants to commit it:
- If `.gitignore` exists and does not already contain `graphify-out/`, append it
- If `.gitignore` does not exist, create one with `graphify-out/`

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
**Does:** Detects tech stack, installs skills + MCP servers, creates support agent
**Verify before continuing:** MCP config in all 3 IDEs, support-agent exists

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
- Support agent: [created / present]

### Validation
Run: scripts/validate.sh .
Result: [COMPLIANT / WARNINGS / NOT COMPLIANT]

### Graphify pre-pass
- Install path: [already installed / uv / pipx / unavailable]
- Graphify run: [succeeded / failed / skipped]
- `graphify-out/` available to Discovery: [yes / no]

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
