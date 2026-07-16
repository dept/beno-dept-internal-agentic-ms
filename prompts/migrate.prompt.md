---
name: "ms-migration"
argument-hint: "Target project or migration context to use"
description: "Migrate any project into DEPT Managed Services standards. Runs a non-blocking Graphify pre-pass plus 4 phases: install, discover, integrate, stack-tooling. Each phase is self-contained and idempotent."
---

# Migrate Project to DEPT Managed Services Standards

You are running the **DEPT Managed Services Migration** workflow. This installs the DEPT agents first, then runs a non-blocking Graphify pre-pass, then hands repository discovery to the **Discovery Agent** with the full local context it needs.

## What You'll Get

After this workflow completes:
- ✓ Complete `.ai/` documentation (9 files covering architecture, operations, standards, and onboarding)
- ✓ Discovery and Maintainer agents installed and ready to use
- ✓ Superpowers disciplines applied (evidence-first, systematic-debugging, verification) — referenced as agent guidance, not installed as files
- ✓ All AI tools wired (Copilot, Claude, Cursor, Codex auto-load `.ai/` context)
- ✓ Confluence handover pages created (or staged as drafts when Confluence access is unavailable)
- ✓ Stack-specific skills (Phase 4) and MCP servers installed
- ✓ Support agent configured
- ✓ Graphify structural pre-pass attempted before Discovery
- ✓ Discovery Agent explicitly used for the discovery phase

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
bash <(command curl -fsSL "https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/install.sh") .
```
Then invoke it in your AI tool. This installs the local prompts, agents, and Graphify helper before the migration starts:
```
# VS Code Copilot / Cursor
@workspace /ms-migration

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

## Graphify Pre-Pass (After Phase 1, Default, Non-Blocking)

After Phase 1 installs the local prompts, agents, and helper script, **attempt to run Graphify automatically** in the target repository. This keeps `/ms-migration` as the single entry point while ensuring the Discovery Agent starts with the best available structural context.

### Default behavior
1. Phase 1 installs `scripts/graphify-bootstrap.sh` into the target repo.
2. Prefer running that helper from the repository root: `bash scripts/graphify-bootstrap.sh .`
3. If the helper is missing for some reason, fall back to the direct Graphify commands below.
4. If installation or execution fails, **continue the migration anyway** — Graphify is a strong accelerator, not a hard blocker.

### Important Graphify prerequisite
Graphify now has **two supported migration modes** in this repo:

1. **No API key available** → the helper still runs Graphify in **code-only fallback mode**
   - code extraction still runs
   - docs / papers / images are excluded for that run only
   - Discovery can still use `graphify-out/graph.json` and the follow-up `GRAPH_REPORT.md`

2. **API key available** → the helper runs the full Graphify pass, including semantic extraction for docs / papers / images

If you want the full semantic pass, set one supported key before running this prompt:
- `GOOGLE_API_KEY` or `GEMINI_API_KEY`
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `MOONSHOT_API_KEY`
- `DEEPSEEK_API_KEY`

The helper script automatically attempts to load keys from these files in the target repo root before Graphify starts:
- `.env`
- `.env.local`
- `.env.graphify`
- `.env.graphify.local`

So either export the key in your shell **or** add it to one of those files.

**Example `.env` entries:**
```bash
OPENAI_API_KEY=your-openai-key
# or
GEMINI_API_KEY=your-gemini-key
```

Also install the matching Graphify backend dependency when needed:
- OpenAI backend → `uv tool install "graphifyy[openai]" --force`
- Gemini backend → `uv tool install "graphifyy[gemini]" --force`
- Claude backend → `uv tool install "graphifyy[anthropic]" --force`
- If `uv` is unavailable, prefer `pipx install "graphifyy[...]" --force`
- If both `uv` and `pipx` are unavailable, install pipx first with `python3 -m pip install --user pipx` and then use `python3 -m pipx install "graphifyy[...]" --force`

If Graphify says `the 'openai' package is required for this backend but is not installed`, it found your API key but the backend dependency is missing. Reinstall the existing Graphify tool with the matching extra instead of only rerunning the base install.

If Graphify warns that the installed slash-command skill is out of date after an upgrade or reinstall, run:
```bash
graphify install
```

That refreshes the tool integration for supported assistants while keeping the CLI available for the DEPT migration pre-pass.

### Command sequence
```bash
# from the target repository root
if [ -x scripts/graphify-bootstrap.sh ]; then
  bash scripts/graphify-bootstrap.sh . || true
elif command -v graphify >/dev/null 2>&1; then
  graphify . && graphify cluster-only .
elif command -v uv >/dev/null 2>&1; then
  uv tool install graphifyy && graphify . && graphify cluster-only . || true
elif command -v pipx >/dev/null 2>&1; then
  pipx install graphifyy && graphify . && graphify cluster-only . || true
elif command -v python3 >/dev/null 2>&1; then
  python3 -m pip install --user graphifyy && python3 -m graphify . && python3 -m graphify cluster-only . || true
else
  echo "Graphify unavailable; continuing with raw-repo discovery"
fi
```

**Why the explicit two-step run?**
Current Graphify CLI behavior writes `graphify-out/graph.json` on the initial extraction pass, then needs `graphify cluster-only .` to generate `GRAPH_REPORT.md` and `graph.html`. This is also clearer when AST reaches 100% but the terminal still appears active.

**Why is `python3 -m pip` last?**
Upstream warns plain `pip install` can create PATH/interpreter mismatches on some machines. DEPT only uses it as a fallback to keep `/ms-migration` as close as possible to a one-command workflow.

### After Graphify runs
- Read `graphify-out/GRAPH_REPORT.md` first
- Read `graphify-out/graph.json` only when needed for structural verification
- Treat `graphify-out/cache/ast/` as expected cache output, not a failure signal
- Treat `graphify-out/` as **supplemental evidence** — verify important claims against actual repo files before writing `.ai/`
- Use `graphify-out/` as the Discovery Agent's short-term structural working context for this run, then translate verified findings into durable `.ai/` files so future sessions do not depend on the generated graph artifacts alone

### Git hygiene
If `graphify-out/` was created, ensure it is ignored by default unless the team explicitly wants to commit it:
- If `.gitignore` exists and does not already contain `graphify-out/`, append it
- If `.gitignore` does not exist, create one with `graphify-out/`

### Graphify ignore hygiene
If Graphify is used, ensure a root `.graphifyignore` exists so the pre-pass skips obvious migration noise. At minimum include:
- `.history/`
- `.ai/`
- `graphify-out/`
- `node_modules/`, `dist/`, `build/`, `.next/`, `coverage/`, `.turbo/`, `.cache/`, `.vercel/`

Keep `.graphifyignore` additive: Graphify already respects `.gitignore`, and `.graphifyignore` should only add extra exclusions that reduce junk in the structural scan. 

## Phase Execution

Execute each phase in order. Each phase is self-contained — if interrupted, restart from the last incomplete phase. Try to execute all phases in one run for best results, but you can also run them individually if needed.

**Important orchestration rule:** Phase 2 must be executed with the installed **Discovery Agent** (`.github/agents/discovery.agent.md`). The migration prompt itself is the orchestrator; the Discovery Agent is the worker that performs the repository analysis and `.ai/` generation.

**Parallel execution (optional — only for tools that support subagents):** The phase dependency graph is `1 → (graphify) → 2 → {3, 4}`. Phases 3 and 4 both depend only on Phase 2's `.ai/` output and are **independent of each other**, so an orchestrator with subagent/parallel support (e.g. Claude Code) MAY run them concurrently after Phase 2 completes. Within Phase 4, per-technology skill generation is also independent and MAY be fanned out one subagent per technology. This is purely a speed optimization: **tools without parallel execution should just run the phases sequentially 1→2→3→4** — the result is identical. Do not parallelize Phase 2's file generation itself (the 9 `.ai/` files share evidence and single-source-of-truth cross-references, so they must be produced coherently by one worker).

**Base URL for GitHub-hosted prompts:**
```
https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/
```

### Phase 1: Installation
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/01-install.prompt.md`
**Does:** Fetches agents, installs local phase prompts, installs Graphify helper + validator script, and installs the fixed `confluence-cli` skill (stack-specific skills come in Phase 4)
**Verify before continuing:** `.github/agents/` has 2 files, `.github/prompts/` has `migrate` + `01-04`, `scripts/graphify-bootstrap.sh` and `scripts/validate.sh` exist, `.github/skills/confluence-cli/` exists. Other (stack) skills are added in Phase 4.

### Graphify Context Preparation
**Run after Phase 1, before Phase 2.**
**Does:** Creates or updates `.graphifyignore`, attempts Graphify, preserves `graphify-out/` for the Discovery Agent when successful
**Verify before continuing:** `.graphifyignore` exists when Graphify was attempted; if Graphify succeeded, `graphify-out/GRAPH_REPORT.md` or `graphify-out/graph.json` exists

### Phase 2: Discovery & Analysis
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/02-discover.prompt.md`
**Agent:** `.github/agents/discovery.agent.md`
**Does:** The Discovery Agent scans agentic config, consumes `graphify-out/` when available, collects onboarding links, and generates 9 `.ai/` files + `.meta.yml`
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
4. After merging, run Maintainer Agent after each sprint
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
