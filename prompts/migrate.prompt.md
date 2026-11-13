---
name: "ms-migration"
argument-hint: "Target project or migration context to use"
description: "Migrate any project into DEPT Managed Services standards. Runs a non-blocking Graphify pre-pass plus 4 phases: install, discover, integrate, stack-tooling. Each phase is self-contained and idempotent."
---

# Migrate Project to DEPT Managed Services Standards

You are running the **DEPT Managed Services Migration** workflow. This installs the DEPT agents first, then runs a non-blocking Graphify pre-pass, then hands repository discovery to the **Discovery Agent** with the full local context it needs.

## What You'll Get

The project context is written once, in this checkout, and then handed to the central context
repository `dept/beno-dept-ms-agentic-context`. The project keeps only what developers use day to day.

After this workflow completes:
- ✓ Complete `.ai/` documentation (9 files covering architecture, operations, standards, and onboarding), generated here and imported into `projects/<org>__<repo>/.ai/` of the central repository by an onboarding pull request there. `.ai/` is gitignored in the project and never committed to it
- ✓ The central repository maintains that context from then on (its *Maintain context* workflow runs the Maintainer from this standard), so the project gets no maintainer agent, no maintainer workflow and no secrets
- ✓ `AGENTS.md` from `templates/AGENTS.central.template.md`: the one file in the project that points at the context. `CLAUDE.md` imports it
- ✓ Confluence handover pages created (or staged as drafts when Confluence access is unavailable)
- ✓ Client **key features** (Datadog Synthetic tests) fetched by `client:<name>` tag and added to `.ai/project-context.md` + the Confluence Overview page (or `[To fill in]` when Datadog access is unavailable)
- ✓ Stack-specific skills and MCP servers installed. Skills state facts and never name a context file
- ✓ Optional Dependabot config, patch auto-merge and branch hygiene
- ✓ Every standard-owned file removed again in Phase 5: agents, phase prompts, `scripts/validate.sh`, `standards/`, `config/standard-version.yml` and the context skills
- ✓ Superpowers disciplines applied (evidence-first, systematic-debugging, verification), referenced as agent guidance, not installed as files
- ✓ Graphify structural pre-pass attempted before Discovery
- ✓ Discovery Agent explicitly used for the discovery phase

**Time estimate:** 15-30 minutes depending on repository complexity.

## Stop if this project is not new

This workflow is for a project with no context yet. Check before Phase 1:

```bash
grep -qs beno-dept-ms-agentic-context AGENTS.md && echo "already on the central context repository"
git ls-files .ai | head -1
```

- `AGENTS.md` already names `beno-dept-ms-agentic-context`: the project is cut over. Stop. Context
  changes are a pull request on that repository.
- `git ls-files .ai` prints a file: the project migrated under an older standard and still holds
  its own `.ai/` (dual period). Stop. Cut it over with the checklist in the central repository's
  README instead, which keeps its history.
- `dept/beno-dept-ms-agentic-context` `projects.yml` already lists this repository: stop, same reason.

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

Phase 3 publishes handover pages. The **primary path is the `confluence-axi` skill**, which drives the `confluence-axi` npm CLI (`npx`) against the Confluence Cloud REST API.

**The user logs in; the agent never does.** The preferred login is **browser OAuth** (`npx -y confluence-axi auth login`), run by the user in their own terminal before the migration starts. It needs a registered Atlassian 3LO app once — see the skill's `references/setup.md`. An API token is the fallback for CI and headless runs. The agent never mints, types, echoes, or stores a token.

Verify **before** reaching Phase 3:

```bash
npx -y confluence-axi space list   # lists spaces if authed, errors otherwise
```

- If it lists spaces (incl. `MS`) → Phase 3 can publish directly.
- If it errors (not authed) → ask the user to run `confluence-axi auth login` (see `references/setup.md`). If they cannot log in now:
  - **Atlassian MCP reachable** (already configured and reloaded, e.g. a re-run) → proceed on the MCP alone, and warn once: *"`confluence-axi` is not authenticated, so Confluence work is going through the Atlassian MCP. That reads whole page bodies rather than compact output, so expect noticeably higher token use."*
  - **Neither available** (the normal first run, where the MCP only arrives in Phase 4) → Phase 3 **stages drafts** to `.ai/confluence/` for later publishing. Non-blocking.

**Hybrid rule — `confluence-axi` first, Atlassian MCP only when it genuinely cannot do the job.** The CLI is the default for *every* Confluence operation: searching, resolving pages, reading a body, creating, updating, and verifying afterwards. Reads dominate the token cost of a migration and the CLI returns compact, truncatable output, so routing reads through the MCP is pure waste. Reach for the remote Atlassian MCP only when the CLI cannot complete the operation — in practice a page-body write the CLI refuses because a full-body replace would drop an embedded macro that cannot be reconstructed in storage format. When that happens: use the MCP for that one write, then **verify with `npx -y confluence-axi page get <id> --format storage --full`** and record in the phase notes which page went through the MCP and why. The other sanctioned MCP-only mode is the unauthenticated fallback above, which is allowed but must carry the token warning. Two MCP limits stand throughout: it is only configured in **Phase 4**, so it is unavailable during a first run's Phase 3, and an MCP added to `.mcp.json` mid-session is not callable until the tool/IDE reloads. Never block Phase 3 waiting on the MCP.

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

### If the repository already tracks `graphify-out/`
Check first: `git ls-files | grep -E '(^|/)graphify-out/'`. A **tracked** `graphify-out/` is the team's own graph — project content they committed on purpose, sometimes with a hand-written `README.md`, a query script and a `/graphify` command beside it — not this migration's scratch output. The helper detects that case, writes nothing, exits 0, and the migration continues. The raw fallback commands below have no such guard, so do not run them here.

For the rest of the migration:
- Discovery reads the committed graph as it stands and checks how old it is before leaning on it. It is still supplemental evidence, verified against the real files like any other.
- Do **not** add `graphify-out/` to `.gitignore`: the pattern matches at every depth, so one root line also hides any nested committed graph.
- Do **not** touch a tracked `.graphifyignore` — it is the team's exclude list for their own runs.
- Phase 5 removes none of it. See the cleanup section.

Refreshing a committed graph is the team's call and belongs in its own commit, not in the migration PR: `GRAPHIFY_OVERWRITE_TRACKED_OUT=1 bash scripts/graphify-bootstrap.sh .`. An **untracked** `graphify-out/` is a previous local run and is handled normally.

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
If the pre-pass **created** `graphify-out/`, ensure it is ignored:
- If `.gitignore` exists and does not already contain `graphify-out/`, append it
- If `.gitignore` does not exist, create one with `graphify-out/`

If the repository already tracked `graphify-out/`, the team has explicitly chosen to commit it: leave `.gitignore` alone.

### Graphify ignore hygiene
If Graphify is used and `.graphifyignore` is not already tracked, ensure a root `.graphifyignore` exists so the pre-pass skips obvious migration noise. At minimum include:
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
**Does:** Fetches agents, installs local phase prompts, installs Graphify helper + validator script, and installs the fixed `confluence-axi` skill (stack-specific skills come in Phase 4). Builds the Claude Code mirrors with `scripts/mirror-claude.sh` (`.claude/skills` as a symlink to `.agents/skills`, one symlink per agent in `.claude/agents/`, and the prompt mirrors in `.claude/commands/` and `.cursor/commands/` generated from `.github/prompts/`), so Copilot, Claude Code and Cursor all auto-load them.
**Verify before continuing:** `.gitignore` has a `.ai/` line, `.github/agents/` has 2 files (mirrored in `.claude/agents/`), `.github/prompts/` has `migrate` + `01-04` (mirrored in `.claude/commands/`), `scripts/graphify-bootstrap.sh`, `scripts/validate.sh` and `standards/writing-rules.md` exist, `.agents/skills/confluence-axi/` and `.agents/skills/context-ownership/` exist and resolve through the `.claude/skills` symlink, `scripts/mirror-claude.sh` exists. Other (stack) skills are added in Phase 4.

### Phase 1a: Dependabot configuration (ask first, default yes)
**Does:** Generates `.github/dependabot.yml` from the lockfiles actually present (`scripts/gen-dependabot.sh`, install-if-absent: it never overwrites a hand-tuned config). Inline (no separate prompt file). **Always ask**, defaulting to yes: most repos want it, but some already run a different update tool or have a delivery lead who wants to decide update cadence separately.

Ask, verbatim in spirit:

> Generate `.github/dependabot.yml` for the ecosystems detected (patch/minor groups split so a patch bump is auto-mergeable in Phase 4c)? Default yes. [yes / no]

If **yes**: proceed as normal: the bootstrap one-liner (`scripts/install.sh`) already runs `scripts/gen-dependabot.sh` unconditionally at the end of the install; nothing else to do. In-session (Option B, no installer run), run `scripts/gen-dependabot.sh .` yourself.

If **no**: if the bootstrap one-liner already generated `.github/dependabot.yml` before this question could be asked, delete it and note in the summary that Dependabot is not configured for this repository (it can be regenerated later with `bash scripts/gen-dependabot.sh .`). Once `.ai/.meta.yml` exists, `scripts/install.sh --update` leaves an absent `.github/dependabot.yml` absent, so the deletion holds. In-session, just skip the step.

**Which branch Dependabot targets (`target-branch`).** Decide by data, not by branch name. Set `target-branch` to a work branch (develop, support, acceptance, test) only when that branch is merged into the default branch as a whole, so everything on it reaches production with the next promotion. Measure it:

```bash
gh pr list --state merged --base <default> --limit 30 --json headRefName \
  --jq '[.[]|select(.headRefName=="<work-branch>")]|length'   # whole-branch promotion PRs
gh api repos/<owner>/<repo>/compare/<default>...<work-branch> --jq .ahead_by
```

Promotion PRs present and a small `ahead_by` means the work branch drains: target it. Zero promotion PRs (the team ships through `release/*` branches, cherry-picks, or feature branches merged straight into the default branch) means it does not: leave `target-branch` off. A patch merged into a branch that never drains never reaches production, and Dependabot deletes its branch on merge, so the only way to ship it is a cherry-pick. Targeting the default branch instead keeps the `dependabot/*` branch alive until it ships: to test a bump first, merge that branch into the test environment branch, then merge the pull request into the default branch or fold it into the release branch, exactly like a feature branch. The next back-merge of the default branch brings it onto the work branch too. Do not configure both targets for the same ecosystem: it doubles the pull requests, lets the two environments drift to different versions, and conflicts in the lockfile on the next back-merge.

Majors are not part of this decision: the generated config ignores `semver-major`, so upgrading a major stays normal feature work. Security updates ignore `target-branch` and always open against the default branch.

### Graphify Context Preparation
**Run after Phase 1, before Phase 2.**
**Does:** Creates or updates `.graphifyignore`, attempts Graphify, preserves `graphify-out/` for the Discovery Agent when successful. Writes nothing at all when the repository tracks `graphify-out/` itself.
**Verify before continuing:** `.graphifyignore` exists when Graphify was attempted; if Graphify succeeded, `graphify-out/GRAPH_REPORT.md` or `graphify-out/graph.json` exists. If the helper reported a tracked `graphify-out/`, verify instead that `git status` is clean — the pre-pass must have changed nothing.

### Phase 2: Discovery & Analysis
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/02-discover.prompt.md`
**Agent:** `.github/agents/discovery.agent.md`
**Does:** The Discovery Agent scans agentic config, consumes `graphify-out/` when available, collects onboarding links, and generates 9 `.ai/` files + `.meta.yml`
**Verify before continuing:** `.ai/` has 9 files + `.meta.yml`, no placeholder markers

### Phase 3: Integration
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/03-integrate.prompt.md`
**Does:** Writes the two wiring files (`AGENTS.md` from `templates/AGENTS.central.template.md`, and its `CLAUDE.md` import), creates Confluence documentation
**Verify before continuing:** `AGENTS.md` points at `projects/<org>__<repo>/.ai/` in the central repository with no unfilled placeholders, `CLAUDE.md` contains the `@AGENTS.md` import; Confluence pages published via the `confluence-axi` skill (or staged as `.ai/confluence/` drafts if access was unavailable, see Preflight)

### Phase 4: Stack-Aware Tooling
**Prompt URL:** `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/refs/heads/main/prompts/04-stack-tooling.prompt.md`
**Does:** Detects tech stack, installs skills + MCP servers, writes the `codebase-overview` skill for the handoff, then runs `scripts/mirror-claude.sh`. No support agent.
**Verify before continuing:** MCP config in all 3 IDEs, `.claude/skills` resolves to the installed skills, no skill names a `.ai/` file or another skill

### Phase 4b: Hand off to the central context repository

**Does:** Moves the context out of this checkout into `dept/beno-dept-ms-agentic-context` with one
pull request there. Inline (no separate prompt file). Needs `gh` logged in with write access to that
repository.

1. Run `bash scripts/validate.sh .` and resolve every FAIL. This is the last time the context is
   checked in the project; after the handoff the central workflow checks it.
2. Ask who owns the context (GitHub handles of the project's tech lead and one developer) and
   whether Confluence was published in Phase 3.
3. Run, from the project root:

   ```bash
   bash scripts/onboard-central.sh <org>/<repo> --owners "@lead @dev"
   ```

   Add `--no-confluence-sync` when Phase 3 only staged drafts. It imports `.ai/` and
   `.agents/skills/codebase-overview/`, lists the project as `state: final` in `projects.yml`, adds
   the CODEOWNERS line and prints the pull request URL. `--dry-run` shows the commit without pushing.
4. Record the URL for the completion summary and this project's pull request description. Do not
   merge it: its reviewers are the central repository's owners.

The project does not get `.github/workflows/maintainer.yml` and needs no `ANTHROPIC_API_KEY` or
`CONFLUENCE_*` secret: the central repository holds them.

### Phase 4c: Dependabot patch auto-merge (ask first, default yes)
**Does:** Installs a workflow that merges Dependabot's patch-level pull requests once every check on them is green. Minor and major bumps stay a human decision. Inline (no separate prompt file). **Always ask**, defaulting to yes, and ask the delivery lead, not only the developer running the migration: this hands a bot the right to move code into the base branch. The workflow ships dormant either way: its job only runs when the Actions variable `DEPENDABOT_AUTO_MERGE` is `true` (Settings > Secrets and variables > Actions > Variables), so the ask here decides whether the file exists at all, and the variable is the day-to-day on/off switch a team flips later without a new PR. Do not use the native `Allow auto-merge` setting for this: developers use it for their own pull requests, so it is already on in most repositories.

Ask, verbatim in spirit:

> Install Dependabot patch auto-merge (merges once checks pass, dormant until the `DEPENDABOT_AUTO_MERGE` variable is set to `true`)? Minors and majors stay manual either way. Default yes. [yes / no]

Auto-merge only makes sense where Dependabot targets a work branch that drains into the default branch (the Phase 1a measurement). Where Dependabot targets the default branch, an auto-merged patch goes straight to whatever a merge there triggers, usually production: answer no, or install it and leave the variable unset. Where it targets a work branch that does not drain, the Phase 1a rule already says not to target it; do not install auto-merge to paper over that.

When you set `target-branch`, set it on the package ecosystems only. Leave it off the `github-actions` entry unless the target branch actually carries a `.github/workflows` directory: Dependabot reads workflow files from the target branch, and on a branch without them the job aborts with `/action.yml or /.github/workflows/<anything>.yml not found`. Workflow files normally live on the default branch, so the `github-actions` entry belongs there too. Same rule for every package ecosystem: verify each configured directory exists on the target branch before pointing Dependabot at it.

If **yes**:
1. Fetch `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/templates/workflows/dependabot-auto-merge.yml` → write to `.github/workflows/dependabot-auto-merge.yml`. If that file already exists, show the diff and ask before overwriting.
2. Confirm this repo reports its pipeline back to the pull request (a check run or a commit status, e.g. an Azure DevOps build validation policy). The workflow refuses to merge when no checks report, so on a repo without pull request CI it is inert by design, not silently permissive.
3. Tell the delivery lead the workflow is installed but inert: nothing merges until the repository variable is set (`gh variable set DEPENDABOT_AUTO_MERGE --body true`), and deleting it turns auto-merge off again. It needs no secret, `GITHUB_TOKEN` is enough. The workflow file must live on the branch Dependabot targets, because `pull_request_target` runs the copy on the pull request's base branch.

If **no**: skip it entirely, do not install the file. Dependabot's patch pull requests stay in the normal review queue with no auto-merge path.

### Phase 4d: Branch hygiene (ask first, default yes)
**Does:** Installs a monthly workflow that classifies every branch into one of five tiers (delete,
promote, flag, archive, untouched) and acts on it: deletes what is merged everywhere, opens
promotion pull requests for what reached production but not every lower environment, and archives
(tags, then deletes) what has not been touched in a long time. Inline (no separate prompt file).
**Always ask**, defaulting to yes, and ask the delivery lead, not only the developer running the
migration: this hands a bot the right to delete branches and open pull requests unattended. Only
a manual `workflow_dispatch` defaults to a dry run (`dry_run: true`); the monthly `schedule` trigger
always acts for real, with no separate opt-in step, so accepting this question is accepting that
the first scheduled run (the 1st of next month by default) deletes, tags and opens pull requests,
not just reports. Run it once by hand via `workflow_dispatch` and read the report before the
schedule fires, per step 6 below.

Ask, verbatim in spirit:

> Install the monthly branch hygiene workflow? The schedule acts for real from its first run: run it once manually (dry run) and read the report before trusting it. Default yes. [yes / no]

If **yes**:
1. Fetch `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/templates/workflows/branch-hygiene.yml` → write to `.github/workflows/branch-hygiene.yml`. If that file already exists, show the diff and ask before overwriting.
2. Fetch `https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/branch-hygiene.sh` → write to `scripts/branch-hygiene.sh`. If that file already exists, show the diff and ask before overwriting.
3. Do not edit the workflow to tune it. Every threshold is a repository variable, each optional,
   each falling back to the default in the workflow's header comment. Set only what differs from
   the default, under Settings > Secrets and variables > Actions > Variables, or with
   `gh variable set <NAME> --body "<value>" --repo <owner>/<repo>`:
   `BRANCH_HYGIENE_ENV_BRANCHES` (this repo's real promotion chain, lowest to highest, last entry
   treated as production), `BRANCH_HYGIENE_STALE_DAYS` (default 60), `BRANCH_HYGIENE_ARCHIVE_DAYS`
   (default 180), `BRANCH_HYGIENE_KEEP_PATTERNS` (globs never touched). Keeping the workflow file
   byte-identical across repositories is the point: a later fix is one copy, not a merge into
   whatever each repo edited.
4. If this repo already has the `SLACK_BOT_TOKEN` secret and the `SLACK_CHANNEL` variable (the
   pair the stale pull request digest uses), every run also posts its counts and the branches
   needing a decision to that channel. Nothing to configure: the workflow passes both through
   and stays silent when either is missing. `BRANCH_HYGIENE_SLACK_MAX` (default 10) caps how
   many branches the message lists.
5. Confirm the default-branch guard names this repo's actual default branch (`main` or `master`).
6. Run it once via `workflow_dispatch` with `dry_run` left at its default `true`, and read the
   report, before trusting the monthly schedule (which always runs for real).

If **no**: skip it. Stale branches stay a manual cleanup.

### Phase 5: Remove the standard's files (required)

**Does:** Removes everything the standard installed for the migration. The context now lives in the
central repository, so these files would only be stale copies or tools pointed at a `.ai/` that is
not committed. Inline (no separate prompt file). Run it only after Phase 4b printed a pull request URL.

**Remove:**
- `.ai/` from the working tree (it is gitignored; the central pull request carries it). Keep the `.gitignore` line
- `.github/agents/` (discovery, maintainer) and `.claude/agents/`
- `.github/prompts/migrate.prompt.md`, `01` to `04`, and their mirrors in `.claude/commands/ms-*.md` and `.cursor/commands/ms-*.md`
- `scripts/validate.sh`, `scripts/mirror-claude.sh`, `scripts/graphify-bootstrap.sh`, `scripts/onboard-central.sh`, `scripts/confluence-adf.py`
- `standards/`, `config/standard-version.yml`, `config/change-impact-matrix.yml`, `docs/confluence-page-standard.md`, `docs/confluence-layout.md`
- `.agents/skills/codebase-overview/`, `.agents/skills/confluence-axi/`, `.agents/skills/context-ownership/`
- `.graphifyignore` and `graphify-out/`. **Leave the `graphify-out/` line in `.gitignore`**

**Keep:**
- `AGENTS.md` and `CLAUDE.md`
- Stack skills under `.agents/skills/` and the `.claude/skills` symlink
- MCP config (`.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`)
- `.github/dependabot.yml` and `scripts/gen-dependabot.sh`, the auto-merge workflow, `.github/workflows/branch-hygiene.yml` and `scripts/branch-hygiene.sh`, when installed in 1a, 4c, 4d. `scripts/gen-dependabot.sh` is how the repository refreshes its update targets when a package or solution moves, so it stays even though the rest of the standard's scripts go

**Delete only what this migration created.** Before removing a path, run `git ls-files -- <path>`
against the base branch: anything already tracked there is project content and stays. This is the
case the cleanup got wrong on dtnl-keter-webshop#2124, where `graphify-out/` was a committed
knowledge graph with its own tooling. Where the repository owns it, keep it and add no ignore line.

**Gates (both must print nothing):**

```bash
git ls-files | grep -E '^(\.ai/|\.github/agents/|\.claude/agents/|standards/|config/standard-version)'
git grep -n -e '\.ai/' -e 'codebase-overview' -- '*.md' ':!AGENTS.md'
```

The second gate is the rule from the central repository's cutover checklist: only `AGENTS.md`
names the context. A skill or doc that still names `.ai/...` gets the fact written into it, or the
line removed.

**`install.sh --update` will not undo this.** It sees `AGENTS.md` pointing at the central
repository and exits without writing.

---

## Completion Summary

After all phases complete, output:

```
## Migration Complete ✓

### Phase 1: Installation
- Agents: [installed / already present] (linked into .claude/agents/)
- Prompts: [installed / already present] (mirrored to .claude/commands/)
- Skills: [installed / already present] (.claude/skills symlinks to .agents/skills)

### Phase 1a: Dependabot configuration
- .github/dependabot.yml: [generated / declined / already present, hand-tuned]

### Phase 2: Discovery
- .ai/ files: 9/9 generated
- .meta.yml: created (standard v[version from config/standard-version.yml])
- Key features (Datadog Synthetics): [N tests fetched / access unavailable — staged To fill in]
- Confidence: [average % across files]

### Phase 3: Integration
- AGENTS.md (central pointer): [created / replaced]
- CLAUDE.md (@AGENTS.md import): [created / import added / present]
- Confluence: [created / staged as drafts / skipped, with the reason]

### Phase 4: Stack-Aware Tooling
- Technologies detected: [count]
- Skills installed: [list or "None matched"] (reached by Claude Code through the .claude/skills symlink)
- MCP servers added: [list or "None"]

### Phase 4b: Central handoff
- Onboarding PR: [URL on dept/beno-dept-ms-agentic-context]
- Owners: [handles], confluence_sync: [true / false, drafts only]

### Phase 4c: Dependabot patch auto-merge
- .github/workflows/dependabot-auto-merge.yml: [installed, dormant until DEPENDABOT_AUTO_MERGE=true / declined]
- Dependabot target: [default branch / <work-branch>, drains: N promotion PRs in last 30]

### Phase 4d: Branch hygiene
- .github/workflows/branch-hygiene.yml + scripts/branch-hygiene.sh: [installed, dry run only until schedule is trusted / declined]

### Validation (before the handoff)
Run: scripts/validate.sh .
Result: [COMPLIANT / WARNINGS]

### Graphify pre-pass
- Install path: [already installed / uv / pipx / unavailable]
- Graphify run: [succeeded / failed / skipped / skipped — repository tracks graphify-out/]
- `graphify-out/` available to Discovery: [yes / no]
- `graphify-out/` owned by the repository: [no / yes — left untouched, not ignored, not deleted]

### Phase 5: Standard files removed
- Removed: [list]
- Kept as project content (tracked before this branch): [list / none]
- Gates: [both empty]

### Next Steps
1. Get the central onboarding PR reviewed and merged
2. Open this project's PR, carrying the two required links (below) and the onboarding PR URL
3. After both merge, run *Maintain context* once for this project on the central repository
```

### The pull request description

The reviewers of this pull request did not ask for it, and most of them have not heard of the
standard. A description that lists only what changed reads as an unexplained drop of a hundred
files into their repository, so it opens with why, in two links, before anything else:

```markdown
Why this PR: https://dept-nl.atlassian.net/wiki/spaces/MS/pages/21504720935/Why+is+this+DEPT+standard+being+added+to+your+project

More about the standard: https://github.com/dept/beno-dept-internal-agentic-ms
```

The Confluence page is the explanation written for the receiving team: what is added, what is not
touched (no application code, no dependencies, no pipeline config), and what it costs them. The
repository link is for whoever wants the mechanics. Put both in the description itself, not in a
follow-up comment, because a comment is what a reviewer reads after already forming an opinion.

The rest of the description then links the central onboarding pull request, states what the
migration added and what Phase 5 deleted, and lists the Validation Questions the team has to answer
(they are answered on the central pull request, where the context now lives).

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
| validate.sh reports warnings | Resolve them before Phase 4b; after the handoff the central repository's workflow checks the context |
| `onboard-central.sh` says `.ai/` is tracked | The project migrated under an older standard: use the central repository's cutover checklist |
