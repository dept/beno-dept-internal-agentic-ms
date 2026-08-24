---
description: "Phase 2: Analyze the repository and generate complete .ai/ context files."
agent: discovery
---

# Phase 2: Discovery & Analysis

> Self-contained phase. Requires Phase 1 (agents installed). Idempotent.

**Execution mode:** run this prompt with the installed **Discovery Agent** from `.github/agents/discovery.agent.md`. If your tool ignores the prompt frontmatter, explicitly select or invoke that agent before continuing. Copilot addresses an agent by its file name (`agent: discovery`, `@agent discovery`); Claude Code addresses it by the `name:` in its frontmatter (`Discovery Agent`). Both point at the same file. The agent must receive the local repository, any `graphify-out/` artifacts, and the installed `.agents/skills/` context.

**Claude Code — real subagent vs. main-thread fallback (timing matters):** Claude Code registers subagents from `.claude/agents/*.md` **at session start**, not mid-session.
- **Bootstrap path (recommended):** if the migration was set up with `scripts/install.sh` in a terminal *before* launching Claude Code, `.claude/agents/discovery.md` already exists at session start → dispatch a **real Discovery subagent** for this phase (`Agent` with `subagent_type: Discovery Agent`, the `name:` from the agent's frontmatter), sandboxed with its own context.
- **In-session path:** if `.claude/agents/discovery.md` was only written during Phase 1 of *this same session*, it is **not** yet a registered subagent (no reload happened). Do not fail — run Phase 2 in the **main thread** by reading `.claude/agents/discovery.md` and following it as the Discovery Agent persona. Real subagent dispatch becomes available on the next session. This is the same reload gap as the Datadog MCP (see `migrate.prompt.md` Preflight).

## Prerequisites

- Phase 1 completed (agents and skills installed)
- Repository has source code to analyze

## Critical Disciplines

**Follow superpowers:writing-skills discipline:**
- Evidence first: only cite what you find in code, config, and infrastructure
- No hallucination: mark unknowns explicitly with `Assumption:` tags
- All claims traceable to source files
- Rate `Confidence: <0-100>%` per major section
- `standards/writing-rules.md` governs every `.ai/` file you write. Read it before writing. §1 says what never goes in, §2 is the single-source rule and §4b is the topic-to-file ownership map, §3 says which tool-enforced rules get written down at all. It is not restated here
- The `context-ownership` skill in `.agents/skills/context-ownership/` is the working procedure for §2 and §4b: use it for every section you are about to write

**Exclude from analysis:** `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/`, `.git/`, `coverage/`, `.cache/`, `.pnpm-store/`

**For monorepos:** Read `turbo.json`, `pnpm-workspace.yaml`, or root `package.json#workspaces` first. Map all packages before per-package analysis.

**Documentation-first rule:** If the repository contains a `doc/` or `docs/` folder, read it early and treat it as primary context for onboarding, architecture explanations, package/campaign descriptions, and Confluence handover content — while still verifying important claims against code/config.

## Graphify Input (Expected When Available)

If the repository contains a `graphify-out/` directory, use it as the **first structural input** before broad raw-source scanning.

**Read in this order:**
1. `graphify-out/GRAPH_REPORT.md`
2. `graphify-out/graph.json` (for detailed structural verification only)

**Use Graphify specifically for:**
- probable service boundaries
- cross-file call paths
- import/dependency clusters
- hotspots / highly connected nodes
- prioritizing which raw files to inspect next
- package/app/campaign boundaries in monorepos or multi-brand repositories

**How to use it in practice:**
- Treat `GRAPH_REPORT.md` as short-term structural working context for this discovery run
- Use it to decide which packages, features, apps, campaigns, and docs to inspect first
- Convert the useful findings into durable `.ai/` memory/context files (`project-context.md`, `architecture.md`, `dependencies.md`, `agent-registry.md`) after verifying them against primary repository evidence
- When Graphify highlights packages or feature areas, make sure the generated `.ai/` files explain what each one is for in plain language — not just its path or name

**Verification rule:**
- Treat Graphify output as **supplemental evidence**, not the source of truth
- Any important claim written into `.ai/` must still be verified against actual repository files, config, CI/CD, infra, or other primary evidence
- Do **not** replace operational discovery with Graphify — environments, escalation paths, runbooks, SLAs, ownership, and support constraints still come from project docs, CI/CD, infra, and human-provided evidence

**If `graphify-out/` is absent:** continue normally with raw-repository discovery. Do not fail the phase.

## Step 3: Scan Existing Agentic Configuration

Before generating new files, identify what already exists:

**Scan these locations:**
- **Agents**: `.github/agents/*.agent.md`, `.agents/`, `.claude/agents/`, `AGENTS.md`
- **Instructions**: `CLAUDE.md`, and, where a project already has them, `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `.cursor/rules/`
- **Prompts / Skills**: `.github/prompts/*.prompt.md`, `.agents/skills/` (source), `.claude/skills/` (mirror), and `.github/skills/` where a project migrated under standard 1.x still has it (move those skills to `.agents/skills/`, re-mirror, delete the old directory)
- **MCP**: `.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`, VS Code `mcpServers` settings

**Record findings** (file path, name, tool, scope, purpose). This informs `agent-registry.md` and prevents overwriting.

## Step 4: Collect Required Onboarding Links

Gather these 5 base links from repository evidence (config files, CI/CD, README, GitHub):
- **GitHub URL** (repository location)
- **Test environment URL** (where features are tested)
- **Acceptance environment URL** (where client validates)
- **Production environment URL** (live service)
- **Keeper URL** (or equivalent secret-management reference)

**Platform admin links (conditional — include only for platforms the repo actually uses):** when discovery detects a CMS or a cloud/hosting platform, add a dashboard/console link for each so newcomers can reach it. Detect from dependencies, SDK usage, config, and CI/CD; do **not** add a link for a platform the project does not use.
- **CMS admin URL** — when a CMS is detected (e.g. Contentful → `https://app.contentful.com/spaces/<space>`, Sanity → `https://<project>.sanity.studio`, Storyblok, Strapi admin, etc.). One per CMS if several.
- **Cloud / hosting platform URL** — when a cloud or hosting provider is detected (e.g. Azure Portal → `https://portal.azure.com`, ideally deep-linked to the resource group/subscription; AWS Console, GCP Console, Vercel, Netlify). One per provider if several.
- **Figma URL** — when there are clues Figma is used: `figma.com/file/` or `figma.com/design/` links in README/docs/comments, `@figma/*` or `figma-*` dependencies, a Storybook Figma addon (`@storybook/addon-designs`), or design-token config exported from Figma. Link the project's Figma file/project.
- Add any other first-class platform console the project clearly depends on (feature flags, payment dashboard, etc.) under the same rule.

**Action:** Verify each link from codebase evidence. If a **base** link cannot be verified, prompt the user for it. For a **detected platform** link that cannot be verified from evidence, write the resolved section with a `[Fill in]` placeholder (same convention as the other unknowns) rather than dropping the platform or inventing a URL — the platform is real, only its exact console URL is unconfirmed. Do not emit `[Fill in]` slots for platforms the repo does not use.

**Note:** Do NOT ask for Confluence URL. All pages are created under: `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

## Step 4b: Fetch Client Key Features (Datadog Synthetics)

The project's **key features** are the Datadog Synthetic tests that monitor its critical user flows (browser tests) and availability (API/uptime tests). Fetch them so they land in `.ai/` and, from there, on the Confluence **Overview** page.

**Fetch via the Datadog MCP** (`datadog` server, browser OAuth — **no API keys**). The connector URL must enable the synthetics toolset: `?toolsets=core,synthetics` (default is `core` only — without it there are no Synthetics tools).

1. **Determine the client tag.** Tests are tagged `client:<name>` (e.g. `client:unicef`). Infer `<name>` from the repository/project name; if the exact tag is unknown, fetch the live configs and infer the project tag from the returned test tags. If ambiguous, ask the user.
2. **Is the Datadog MCP callable in this session?** It is configured in Phase 4, but a freshly-added MCP is not callable until the tool/IDE reloads — and OAuth must be completed. So:
   - **If the `datadog` MCP is present and authed** (a re-run in an already-reloaded session, or a repo set up earlier): call **`get_synthetics_tests`** with `mode: "configs"`, `test_state: "live"`, `summary: false` (full config, active tests only — not event aggregation). Filter to the project by its `client:<name>` tag; add `type:browser` / `type:api` or a domain/path filter only when needed to disambiguate. Keep both Browser and API tests; drop inactive tests and unrelated domains/projects even if they share the org. Verify the final list by its public IDs and names.
   - **If it is not yet callable** (first migration run, not reloaded, or not authed): do **not** block. Write the Key Features section with a single `[To fill in — fetch via the Datadog MCP after IDE reload + OAuth]` line so the structure exists; the developer (or the Maintainer on its next run) backfills it. This matches the non-blocking Confluence/Graphify pattern (see Preflight in `migrate.prompt.md`).
3. **If the MCP is callable but no tests are found**: record `No Synthetic tests tagged client:<name>` — the tag convention may differ; note it as a Validation Question rather than inventing tests (evidence-first).

**Table schema** (used in `project-context.md` and on the Confluence Overview page), sorted **Browser tests first, API tests second**:

| Column | Value |
|---|---|
| Public ID | markdown link → `https://app.datadoghq.<region>/synthetics/details/<public_id>` (use the org's region, e.g. `eu`) |
| Type | `Browser` or `API` |
| Name | exact Datadog test name |
| Description | short, factual summary of what the test verifies — derived from the visible config (steps, URL, assertions). **Do not invent details.** |

Feed any fetched tests into `project-context.md` in Step 5 (see file 1 below).

## Step 5: Generate `.ai/` Context Files

Generate all 9 context files and write to `.ai/` directory in repository root.

**Files to create:**
1. `project-context.md`: what the system is, business capabilities, client and team, and a `## Key Features (Monitored)` section built from the Step 4b Datadog fetch. Structure stays out of this file: the repository tree and the technology stack table live in `architecture.md`, referenced from here by pointer, and environments live in `operational-context.md`. Use the Step 4b table schema: **Public ID** (link), **Type** (Browser/API), **Name**, **Description**, sorted Browser first, API second, with a one-line note on the split (for example "5 browser + 2 API uptime"). This is the single home for key features and it syncs to the Confluence Overview page via `sync_map`. Monitoring *tooling* (that Datadog is the monitor) belongs in `operational-context.md`; point at it, don't duplicate.
2. `architecture.md` — the structural file, and the only home for the repository tree and the technology stack table. Also service boundaries, runtime topology, data flows, external systems, plus two required tables an agent uses to act rather than just describe (see `templates/architecture.template.md`):
   - **High-fan-in symbols (who owns what):** the shared functions/hooks everything depends on, with file path, consumer count, and a one-line role. Take counts from `graphify-out/graph.json` when Graphify ran, else `grep -rc`, and say which.
   - **Placement conventions:** where each kind of new code goes, with a real existing file per row to follow as the pattern.
3. `runbooks.md` — procedures someone executes, written as steps: incident triage, **rollback**, scheduled operations, known failure signatures, escalation. It describes no pipeline, no environment table, no image and no monitoring wiring: those are `operational-context.md`, referenced by pointer
4. `dependencies.md` — direct dependency inventory, critical vendors, lock-in risks, upgrade paths, and the single home for **toolchain version floors** (language runtime, package manager, SDK) and for **framework version constraints** with the reason for each. No other file states a version floor
5. `cms.md` — CMS SDKs, content models, webhooks, publishing and preview flow, and the single home for **the cache layers a published change has to pass and how each is purged or revalidated**. CMS environment variables are `operational-context.md`, by pointer
6. `operational-context.md` — environments and what each is for, the branch to variable group to environment mapping, deploy pipeline stages, container image details, the environment-variable and secret model with the variable tables, monitoring and alerting wiring including the sampling ratio per environment, hosting model. This is the single home for all of those. **Rollback goes in `runbooks.md` as steps, not here**; what belongs here is the pipeline fact it follows from (for example that the pipeline has no rollback stage)
7. `coding-standards.md` — what each quality gate enforces and which command runs it, config file locations by path, commit message and branch naming convention, accessibility target, testing and PR expectations. It carries **no command cheatsheet** (that is `onboarding.md`) and **no branch-to-environment table** (that is `operational-context.md`)
8. `agent-registry.md` — existing agents, instructions, skills, MCP servers found in Step 3
9. `onboarding.md` — GitHub, environment, and Keeper references collected in Step 4, the **command cheatsheet** (every command a developer or an agent runs, one row each with what it does, in one table and nowhere else), plus a **Platform Access Links** section listing the detected CMS admin and cloud/hosting console URLs (or `[Fill in]` for a detected platform whose URL is unconfirmed). This is the single home for platform access links; `cms.md` and `operational-context.md` cross-reference it rather than restating URLs.

**For each file:**
- Extract evidence from code, config, CI/CD, and infrastructure files
- Include `Assumption:` tags on inferred content
- Rate `Confidence: <0-100>%` per major section
- Add `Validation Questions` for unresolved gaps
- Cite source evidence (file paths, config names)
- Redact secrets and privileged credentials

**One fact, one home. This is the rule this phase breaks most often.**

Every fact you are about to write has exactly one owning file. `standards/writing-rules.md` §4b is
the topic-to-file map: look the topic up there **before** writing the section, not after. §4 gives
each file's full remit, and each file opens with its ownership header.

Work in this order so there is always something to point at:

1. Write each owning section in its owning file first, complete, with the evidence.
2. Then go through the other files and write the pointers, one line each.

**A `.ai/` file is not self-contained and must not be made so.** Writing each file complete for its
own audience is what produced, in a real migrated repository, the same eight build steps under two
headings, one container image described across six files, one toolchain version floor in seven, and
three drifted copies of one command list. The reader follows the pointer.

Three shapes, and only the first is allowed between two `.ai/` files (§2 has the full rule):

- **Pointer**, zero facts: ``Environments: `operational-context.md` -> *Environments*.`` Always allowed.
- **Constraint line**, one fact with the owning file named in the same line. Allowed in `AGENTS.md`
  and skill bodies only, never between two `.ai/` files.
- **Restatement**, two or more facts, or one with no owner named: a filtered copy of the owner's
  table, a "short summary", "see also" plus three sentences of content. Never allowed. Delete it.

Two tests, both must pass: *if the owning file changed tomorrow, would this text become wrong?* and
*could a reader answer the question from this file alone, without opening the owner?* A yes to
either, in a file that is not the owner, means you wrote a restatement.

**A `## ` heading claims its topic.** Before adding one, check that no other `.ai/` file already
carries that exact heading. The only heading that legitimately repeats is `## Validation Questions`.

**Do not do these**, each one is a duplication a previous migration shipped:

| Do not write | Where it goes instead |
|---|---|
| A second environments or branch-to-variable-group table anywhere outside `operational-context.md` | pointer to `operational-context.md` |
| Rollback steps in `operational-context.md` | `runbooks.md` |
| The build or pipeline stages in `runbooks.md` under a different heading | pointer to `operational-context.md` |
| The container image (base image, prune command, run user, port, entrypoint) in `project-context.md`, `architecture.md`, `dependencies.md` or a skill | pointer to `operational-context.md` |
| A CMS-filtered copy of the environment variable table in `cms.md` | pointer to `operational-context.md` |
| The Node, package manager or SDK version floor in any file other than `dependencies.md` | pointer to `dependencies.md` |
| A command list in `coding-standards.md`, `AGENTS.md` or a skill | `onboarding.md` owns the one cheatsheet |
| The commit prefix rule, the accessibility target or a framework version constraint written out twice | `coding-standards.md` for the first two, `dependencies.md` for the third; elsewhere a pointer, or in `AGENTS.md` one constraint line naming the owner |
| Monitoring sampling ratios in `runbooks.md` | pointer to `operational-context.md` |

**Check yourself before finishing this phase:** run `bash scripts/validate.sh .` and resolve every
Single-Source Integrity failure. It fails on a `## ` heading claimed by two `.ai/` files and warns
on a command line repeated across files.

**Quality check:** No empty sections, no placeholders. Every section has content or an explicit unknown statement.

## Step 5b: Generate `.ai/.meta.yml`

After generating all 9 files, create `.ai/.meta.yml` from the meta template:
- `standard_version`: read the `standard.version` value from `config/standard-version.yml` (Phase 1 installs this file into the target repo). If the file is missing for any reason, default to `"1.0.0"` — do not block.
- `generated_by`: `discovery@2.0`
- `generated_at`: current ISO 8601 timestamp
- `project_name`: repository name

## Verification

Before proceeding to Phase 3, confirm:
- [ ] `.ai/` directory contains all 9 required files
- [ ] Each file has content (not just template stubs)
- [ ] `.ai/.meta.yml` exists with correct metadata
- [ ] Confidence scores are present in each file
- [ ] No secrets or credentials in any file
- [ ] `bash scripts/validate.sh .` reports no Single-Source Integrity failure, and every warning it prints is either fixed or is a deliberate owner-naming block in `AGENTS.md` or a skill

## Completion Signal

```
✓ Phase 2 complete: .ai/ folder generated with 9 context files.
  Next: Run Phase 3 (03-integrate.prompt.md) to wire AI tools and create Confluence docs.
```
