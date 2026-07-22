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
- ✓ Discovery and Maintainer agents installed and ready to use, in both Copilot (`.github/agents/`) and Claude Code (`.claude/agents/`) formats
- ✓ Migration slash commands installed for Copilot (`@workspace /ms-migration`), Claude Code + Cursor (`/ms-migration` from `.claude/commands/` + `.cursor/commands/`); Codex runs it by reading the prompt file referenced in `AGENTS.md`
- ✓ Superpowers disciplines applied (evidence-first, systematic-debugging, verification) — referenced as agent guidance, not installed as files
- ✓ All four IDEs wired to auto-load `.ai/` context: Copilot (`.github/copilot-instructions.md`), Claude (`CLAUDE.md`), Codex (`AGENTS.md`), Cursor (`.cursor/rules/ai-context.mdc`)
- ✓ Confluence handover pages created (or staged as drafts when Confluence access is unavailable)
- ✓ Client **key features** (Datadog Synthetic tests) fetched by `client:<name>` tag and added to `.ai/project-context.md` + the Confluence Overview page (or `[To fill in]` when Datadog access is unavailable)
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
# VS Code Copilot
@workspace /ms-migration

# Claude Code (mirror: .claude/commands/ms-migration.md) and Cursor (mirror: .cursor/commands/ms-migration.md)
/ms-migration

# OpenAI Codex, or any tool with file access
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

## Preflight (do this FIRST, before Phase 1)

Two external capabilities make the migration much better but are easy to miss. **Check both up front and, if either is missing, tell the user exactly how to enable it and ask whether to proceed without it** — do not silently degrade and discover the gap three phases later.

### 1. Graphify LLM key (for the semantic code graph)

Graphify only produces its richest graph when an LLM API key is present. Without one it runs code-only (AST) and, on any repo containing docs/images, historically produced **nothing** unless the fallback is correct.

- Detect: is any of `OPENAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `ANTHROPIC_API_KEY`, `MOONSHOT_API_KEY`, `DEEPSEEK_API_KEY` exported, or present in `.env` / `.env.local` / `.env.graphify` / `.env.graphify.local`?
- If **none**: ask the user to `export OPENAI_API_KEY=...` (or add it to `.env`) for the full semantic pass, **or** confirm they want code-only. Either answer is fine — just make it a conscious choice. Code-only is a supported fallback (see below); it is not a failure.

### 2. Confluence access (for Phase 3 handover pages)

Phase 3 publishes handover pages. The **primary path is the `confluence-axi` skill**, which drives the `confluence-axi` npm CLI (`npx`) against the Confluence Cloud REST API. It needs an API-token login (`echo -n "$TOKEN" | confluence-axi auth login --token --site <site> --email <email>`, or the `ATLASSIAN_API_TOKEN` env var) or a browser-OAuth session (`confluence-axi auth login`, which needs your own registered 3LO app). Verify **before** reaching Phase 3:

```bash
npx -y confluence-axi space list   # lists spaces if authed, errors otherwise
# auth via API token (recommended) or browser OAuth — see the skill's references/setup.md
```

- If it lists spaces (incl. `MS`) → Phase 3 can publish directly.
- If it errors (not authed) → point the user at `references/setup.md` to log in or mint a token, or tell them Phase 3 will **stage drafts** to `.ai/confluence/` for later publishing.
- **Note on the Atlassian MCP:** the remote Atlassian MCP is a valid alternative to `confluence-axi`, but (a) it is only configured in **Phase 4**, so it is not available during Phase 3, and (b) an MCP added to `.mcp.json` mid-session is not callable until the tool/IDE reloads its MCP connections. For a single-run migration, prefer `confluence-axi` for publishing. Do not block Phase 3 waiting on the MCP.

### 3. Datadog access (for Phase 2 "key features")

Phase 2 fetches the project's **key features** — the Datadog Synthetic tests monitoring its critical flows — via the **Datadog MCP** (`datadog` server, browser OAuth, **no API keys**), filtered by the `client:<name>` tag.

- The Datadog MCP is configured in **Phase 4** and authenticated by browser OAuth on first connect. A freshly-added MCP is **not callable until the tool/IDE reloads**, so on a **first** migration run Phase 2 usually cannot fetch yet — it writes the Key Features section as `[To fill in — fetch via the Datadog MCP after IDE reload + OAuth]`. **Non-blocking**, same as Graphify/Confluence.
- On a **re-run in an already-reloaded, authed session** (or a repo already set up with the Datadog MCP), Phase 2 calls the MCP's Synthetics tool and writes the real table into `.ai/project-context.md` (it surfaces on the Confluence Overview page).
- The developer completes the browser OAuth once (`datadog` server in the IDE's MCP UI); the **Maintainer** backfills/refreshes the section on its next run once the MCP is reachable. No `DD_API_KEY`/`DD_APP_KEY` needed anywhere.

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
**Does:** Fetches agents, installs local phase prompts, installs Graphify helper + validator script, and installs the fixed `confluence-axi` skill (stack-specific skills come in Phase 4). Mirrors agents/prompts/skill to Claude Code (`.claude/agents/`, `.claude/commands/`, `.claude/skills/`) so both Copilot and Claude Code auto-load them.
**Verify before continuing:** `.github/agents/` has 2 files (mirrored in `.claude/agents/`), `.github/prompts/` has `migrate` + `01-04` (mirrored in `.claude/commands/`), `scripts/graphify-bootstrap.sh` and `scripts/validate.sh` exist, `.github/skills/confluence-axi/` exists (mirrored in `.claude/skills/`). Other (stack) skills are added in Phase 4.

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
**Does:** Wires all four IDEs (Copilot, Claude, Codex, Cursor) to auto-load `.ai/`, creates Confluence documentation
**Verify before continuing:** `.github/copilot-instructions.md`, `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/ai-context.mdc` all reference `.ai/`; Confluence pages published via the `confluence-axi` skill (or staged as `.ai/confluence/` drafts if access was unavailable — see Preflight)

### Phase 4: Stack-Aware Tooling
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/04-stack-tooling.prompt.md`
**Does:** Detects tech stack, installs skills + MCP servers, creates support agent. Mirrors every skill to `.claude/skills/` and the support agent to `.claude/agents/support-agent.md`.
**Verify before continuing:** MCP config in all 3 IDEs, support-agent exists (mirrored in `.claude/agents/`), skills mirrored in `.claude/skills/`

### Phase 5: Cleanup (recommended)
**Does:** Removes one-time migration artifacts so the repo keeps only what has ongoing value. This is inline (no separate prompt file). **Ask the user before deleting** — some teams prefer to keep the migration tooling in-repo for cheap re-runs.

The migration installs both **runtime** artifacts (used forever) and **install-time** artifacts (used once). After a successful, verified migration, the install-time set is dead weight.

**Keep (runtime — never remove):**
- `.ai/` (9 files + `.meta.yml`) — single source of truth
- `.github/agents/maintainer.agent.md` + `.claude/agents/maintainer.md` — ongoing drift maintenance
- `.github/agents/support-agent.agent.md` + `.claude/agents/support-agent.md`
- Wiring: `.github/copilot-instructions.md`, `.github/instructions/`, `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/ai-context.mdc`
- Stack skills under `.github/skills/` + `.claude/skills/` (incl. `confluence-axi`, used by the Maintainer to re-sync Confluence)
- Datadog MCP (in the MCP configs) — used to fetch/refresh key features via browser OAuth
- MCP config (`.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`)
- `scripts/validate.sh` — Maintainer/CI compliance check
- `.claude/commands/ms-migration.md` + `.cursor/commands/ms-migration.md` (single entry point for a future full re-run)

**Safe to remove after a successful migration (ask, then delete):**
- `.ai/confluence/*.md` drafts — **only once published** (`.meta.yml` `confluence.published: true` with real page `id`s). The Maintainer syncs Confluence from the `.ai/` files via `sync_map`, never from these drafts.
- Discovery agent (`.github/agents/discovery.agent.md`, `.claude/agents/discovery.md`) — needed only for initial bootstrap / a full re-discovery; the Maintainer handles incremental updates and does not invoke it. Keep only if you want a cheap re-bootstrap.
- Phase prompts `01`–`04` and their command mirrors (`.claude/commands/ms-install|ms-discover|ms-integrate|ms-stack-tooling.md`, same under `.cursor/commands/`) — one-time steps that otherwise clutter the slash-command palette permanently. Keep `ms-migration` only.
- `scripts/graphify-bootstrap.sh` — one-time structural pre-pass. Keep only if periodic re-graphing is planned.
- `graphify-out/` — ephemeral (already gitignored).

**Do not remove** anything if the migration reported WARNINGS/NOT COMPLIANT or Confluence was only staged — resolve those first.

**Remove symmetrically.** `scripts/validate.sh` compares *file counts* between each `.github/*` source and its `.claude/*` / `.cursor/*` mirror and warns if they diverge. So delete an artifact from **all** of source + mirrors together (e.g. discovery agent from both `.github/agents/` and `.claude/agents/`; each phase prompt from `.github/prompts/`, `.claude/commands/`, and `.cursor/commands/`). Deleting from one side only will introduce a new "mirror out of sync" warning.

**Verify before finishing:** re-run `scripts/validate.sh .` after cleanup — it must still report the same (or better) status. Removing install-time artifacts must not drop any COMPLIANT check or add a warning.

---

## Completion Summary

After all phases complete, output:

```
## Migration Complete ✓

### Phase 1: Installation
- Agents: [installed / already present] (mirrored to .claude/agents/)
- Prompts: [installed / already present] (mirrored to .claude/commands/)
- Skills: [installed / already present] (mirrored to .claude/skills/)

### Phase 2: Discovery
- .ai/ files: 9/9 generated
- .meta.yml: created (standard v1.0.0)
- Key features (Datadog Synthetics): [N tests fetched / access unavailable — staged To fill in]
- Confidence: [average % across files]

### Phase 3: Integration
- Copilot wiring (.github/copilot-instructions.md): [created / appended / present]
- Claude wiring (CLAUDE.md): [created / appended / present]
- Codex wiring (AGENTS.md): [created / appended / present]
- Cursor wiring (.cursor/rules/ai-context.mdc): [created / present]
- Confluence: [created / skipped]

### Phase 4: Stack-Aware Tooling
- Technologies detected: [count]
- Skills installed: [list or "None matched"] (each mirrored to .claude/skills/)
- MCP servers added: [list or "None"]
- Support agent: [created / present] (mirrored to .claude/agents/support-agent.md)

### Validation
Run: scripts/validate.sh .
Result: [COMPLIANT / WARNINGS / NOT COMPLIANT]

### Graphify pre-pass
- Install path: [already installed / uv / pipx / unavailable]
- Graphify run: [succeeded / failed / skipped]
- `graphify-out/` available to Discovery: [yes / no]

### Phase 5: Cleanup
- Confluence drafts removed: [yes / n/a — staged, kept]
- Discovery agent removed: [yes / kept for re-bootstrap]
- Phase prompts 01–04 removed: [yes / kept]
- graphify-bootstrap.sh removed: [yes / kept]
- Post-cleanup validate.sh: [COMPLIANT / unchanged]

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
| Confluence access denied | `confluence-axi space list` failed — Phase 3 stages `.ai/confluence/` drafts; authenticate (`confluence-axi auth login`) and publish later (do not delete drafts in Phase 5 until published) |
| Datadog MCP not callable / no key features | Expected on a first run — MCP is callable only after IDE reload + browser OAuth. Phase 2 writes Key Features as `[To fill in]`; complete OAuth on the `datadog` MCP and let the Maintainer backfill. If the MCP is reachable but returns nothing: the `client:<name>` tag differs — check Datadog's Synthetics list |
| Graphify produced no graph.json | Set an LLM key (`OPENAI_API_KEY` etc.) and rerun `scripts/graphify-bootstrap.sh .`; code-only fallback still needs the bootstrap's fixed `.graphifyignore` (bare `*.md`, not `**/*.md`) |
| MCP tools not callable after Phase 4 | MCP config loads only on tool/IDE restart; expected — it's for the next session |
| No skills found for stack | Expected for niche tech; MCP registry is the primary value |
| validate.sh reports warnings | Run Maintainer Agent to address quality issues |
