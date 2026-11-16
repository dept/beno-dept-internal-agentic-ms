# DEPT Agentic Project Standards

> Making Managed Services projects AI-ready with structured context, governed agents, and automated maintenance.

## What This Is

A framework that transforms any repository into an AI-ready project by:

1. **Defining a standard** — The `.ai/` folder structure (9 context files) that any AI tool can consume
2. **Providing agents** — Discovery (bootstraps `.ai/`) and Maintenance (keeps it current)
3. **Shipping tooling** — Scaffold script, validation script, and composable migration prompts
4. **Curating registries** — Stack detection (77 technologies) and MCP server registry

## Quick Start

### Recommended: Full AI Migration

Install the migration toolkit and run the Discovery Agent to auto-generate `.ai/` from your repo.

Since 2.9.0 the context does not stay in the project. The migration writes `.ai/` in a gitignored
folder, hands it to the central context repository
[`dept/beno-dept-ms-agentic-context`](https://github.com/dept/beno-dept-ms-agentic-context) with an
onboarding pull request (`scripts/onboard-central.sh`), and removes the standard's own files again.
The project keeps `AGENTS.md` (the one pointer to the context), `CLAUDE.md`, its stack skills, MCP
configs and the optional Dependabot tooling. A project that already tracks `.ai/` is cut over with
the checklist in the central repository's README instead.

**Step 1** — Install the migration bundle (run once):
```bash
# If you have this repo cloned locally:
./scripts/install.sh /path/to/your/project

# Or fetch directly from GitHub:
bash <(command curl -fsSL "https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/install.sh") /path/to/your/project
```

This installs agents, prompts, and optional Graphify helper into `.github/` and `scripts/`.

**Step 2** — Run the migration in your AI tool:
```
# VS Code Copilot / Cursor
@workspace /ms-migration

# Claude Code
Fetch https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate.prompt.md and follow it

# Any tool with file access
Read .github/prompts/migrate.prompt.md and follow it
```

This runs: Install → (optional Graphify) → Discover → Integrate → Stack Tooling.

### Alternative: Deterministic Scaffold (No LLM)

If you prefer to control the process manually:

```bash
./scripts/scaffold.sh /path/to/your/project
```

Creates empty `.ai/` folder structure + IDE wiring templates. Then manually fill in content or use the Discovery Agent on this template.

### Complex Projects: Phase-by-Phase Control

For multi-team projects or staged rollouts, download and run each phase independently:

```bash
mkdir -p .github/prompts
BASE="https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts"
for f in 01-install 02-discover 03-integrate 04-stack-tooling; do
  curl -sL "$BASE/$f.prompt.md" -o ".github/prompts/$f.prompt.md"
done
```

Then run `@workspace /01-install`, `@workspace /02-discover`, etc. in your AI tool.

### Confluence Documentation Standard

Two files govern the handover pages, and both are installed into every migrated repository:

- [docs/confluence-page-standard.md](docs/confluence-page-standard.md) fixes the **structure**: the
  page tree, the default section order per page, the requirement for a Mermaid overview on the
  architecture page, the `.ai/` to page mapping, and where customization is allowed versus where
  structure should stay stable.
- [docs/confluence-layout.md](docs/confluence-layout.md) fixes the **rendering**: which block type a
  section uses (table, code block, numbered list, bullets, prose), heading depth, the column set for
  every recurring table, which panels are allowed, and the anti-patterns that make two projects'
  pages look unrelated.

The goal is: **same base structure everywhere, with only small project-specific additions when needed**.

### Optional: Graphify-Assisted Discovery

The full migration can pre-scan your repo with **Graphify** before Discovery. This generates structural context that the Discovery Agent can use to prioritize inspection.

- If no LLM API key is available, the helper still runs Graphify in **code-only fallback mode**
- If you want Graphify to include docs / papers / images, set a supported key (`OPENAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `ANTHROPIC_API_KEY`, `MOONSHOT_API_KEY`, or `DEEPSEEK_API_KEY`) in your shell or in `.env`, `.env.local`, `.env.graphify`, or `.env.graphify.local` before running the helper
- If you reinstall or upgrade Graphify for a specific backend, refresh the assistant integration with `graphify install`

See [docs/graphify-integration.md](docs/graphify-integration.md) for setup and troubleshooting.

### New MS developer: set up your Mac

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/dev-setup/macos.sh)
```

Installs the toolchain (Homebrew, git, gh, mise, corepack, VS Code, Claude Code, .NET SDKs),
then, once your GitHub access works, the ms-agentic-context skill and a browser bookmarks file
generated from every project's context.
Safe to re-run. Access requests and everything else are on the Confluence page
[MS Developer Onboarding](https://dept-nl.atlassian.net/wiki/spaces/MS/pages/21692416055).

## What Gets Created

After migration, your project has:

```
your-project/
├── .ai/                           # AI context (the standard)
│   ├── .meta.yml                  # Provenance & version tracking
│   ├── project-context.md         # Business context, ownership, environments, major area summaries
│   ├── architecture.md            # System topology, data flows, boundaries, package/feature purpose notes
│   ├── runbooks.md                # Incident procedures, rollback, escalation
│   ├── dependencies.md            # Vendor inventory, risk, upgrade paths
│   ├── cms.md                     # CMS architecture, content lifecycle
│   ├── operational-context.md     # Deployment, monitoring, SLOs
│   ├── coding-standards.md        # Conventions, quality gates, testing
│   ├── agent-registry.md          # All agentic config in one place
│   └── onboarding.md              # Setup, access, local dev
├── .github/
│   ├── agents/<role>.agent.md     # Agent definitions (one file per agent, read by every harness)
│   └── prompts/                   # Reusable prompts
├── .agents/skills/                # Skills (Copilot, VS Code, Codex, Cursor)
├── .claude/skills -> ../.agents/skills             # Symlink, so Claude Code reads the same skills
├── .claude/agents/<role>.md -> ../../.github/agents/<role>.agent.md   # Symlink, same agent
├── standards/writing-rules.md     # What may be written into .ai/
├── AGENTS.md                      # The one authored wiring file
├── CLAUDE.md                      # @AGENTS.md import (Claude Code)
├── .vscode/mcp.json               # MCP servers (VS Code)
├── .cursor/mcp.json               # MCP servers (Cursor)
└── .mcp.json                      # MCP servers (Claude Code)
```

## After Migration

The migration ends in Phase 5: the project keeps only what developers use day to day, and its context
lives in the central context repository (`dept/beno-dept-ms-agentic-context`, under
`projects/<org>__<repo>/.ai/`). Nothing is left in the project to schedule or maintain: the central
repository's maintain workflow keeps `.ai/` current.

1. **Merge both pull requests**: the onboarding pull request Phase 4b opened in the central repository,
   and the migration pull request in the project.
2. **Check the wiring**: Phase 3 writes these, check they are present:
   - `AGENTS.md` → Copilot (github.com and VS Code), Codex, Cursor. It is the only file in the project that names the context repository
   - `CLAUDE.md` → Claude Code, as an `@AGENTS.md` import
   - `.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json` → MCP servers
3. **Confluence**: the central repository publishes the project pages once the project is listed with `confluence_sync: true` in its `projects.yml`.

A project that still tracks `.ai/` from a migration before 2.9.0 is not migrated again: cut it over
with the checklist under *Cutting a project over* in the central repository's README.

### What to keep vs. remove after migration

Phase 5 of `prompts/migrate.prompt.md` holds the exact list and its two gates. In short:

| Artifact | Keep? | Why |
|---|---|---|
| `AGENTS.md` and its `CLAUDE.md` import | **Keep** | Every harness finds the central context through it. Team rules that are not context stay below the pointer |
| Stack skills under `.agents/skills/` and the `.claude/skills` symlink | **Keep** | Day-to-day development |
| MCP config (`.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`) | **Keep** | Developer sessions |
| `.github/dependabot.yml`, `scripts/gen-dependabot.sh`, auto-merge workflow | **Keep** (when installed) | `gen-dependabot.sh` refreshes the update targets when a package or solution moves |
| `.github/workflows/branch-hygiene.yml`, `scripts/branch-hygiene.sh` | **Keep** (when installed) | Ongoing branch cleanup |
| Project-owned agents, skills and docs that were tracked before the migration | **Keep** | Not the standard's. Phase 5 deletes only what this migration created |
| `.ai/` | **Remove** from the working tree | It is gitignored; the central pull request carries it |
| Discovery and maintainer agents, phase prompts and command mirrors | **Remove** | The maintainer runs in the central repository |
| `scripts/validate.sh`, `mirror-claude.sh`, `graphify-bootstrap.sh`, `onboard-central.sh`, `confluence-adf.py` | **Remove** | They work on a `.ai/` the project no longer has |
| `standards/`, `config/standard-version.yml`, `config/change-impact-matrix.yml`, the Confluence docs | **Remove** | Standard-owned copies that drift |
| `codebase-overview`, `confluence-axi`, `context-ownership` skills | **Remove** | `codebase-overview` moves to the central repository; the other two serve the maintainer |
| `.graphifyignore`, `graphify-out/` | **Remove** | Ephemeral. Keep the `graphify-out/` line in `.gitignore`, and keep both when the repository tracked them before the migration |

> **A version refresh does not bring the removed files back.** `scripts/install.sh` exits before
> writing on a project whose `AGENTS.md` names the central context repository.

## Validation

Verify any project's `.ai/` folder meets the standard:

```bash
./scripts/validate.sh /path/to/your/project
```

Checks: required files present, content quality, placeholder detection, staleness, mirror parity,
reference integrity (every standard-owned path named in `.ai/`, the wiring files and the skills
must resolve; a broken one fails the run), and single-source integrity (a `## ` heading claimed by
two `.ai/` files fails the run; a command line repeated across files warns). The ownership rule
those last checks enforce is `standards/writing-rules.md` §2, and §4b says which file owns what.

Run with no argument in this repository and it validates the standard's own references instead:

```bash
./scripts/validate.sh .
```

## Agents

| Agent | Purpose | Logic |
|-------|---------|-------|
| [Discovery Agent](agents/discovery.agent.md) | Bootstraps `.ai/` from scratch | [logic.md](agents/discovery/logic.md) |
| [Maintainer Agent](agents/maintainer.agent.md) | Keeps `.ai/` current over time | [logic.md](agents/maintainer/logic.md) |

Agent logic is separated from tool-specific wiring — see `agents/*/logic.md` for portable workflow definitions.

## Automated maintenance workflows

Three GitHub Actions workflows ship as templates under `templates/workflows/`. None of them is
installed by `scripts/install.sh`: each is opt-in and copied into a repository by hand, so a
project keeps whatever thresholds and schedule it has tuned and a later change to the template
never overwrites it. The migrate prompt offers them (Phases 4b, 4c and 4d) and asks the delivery
lead first, because each one acts on the repository unattended.

| Workflow | Cadence | What it does |
|---|---|---|
| `maintainer.yml` | Twice a month | Runs the Maintainer Agent to keep `.ai/` current, opens a PR, guarded to the default branch so it never pushes to main/master |
| `dependabot-auto-merge.yml` | On each Dependabot PR | Merges patch-level updates once every check is green; leaves minors and majors for a human |
| `branch-hygiene.yml` | Monthly (1st, 06:00 UTC) | Classifies every branch on origin into tiers and cleans up, dry run by default |

### Branch hygiene

`branch-hygiene.yml` plus `scripts/branch-hygiene.sh` clean up repositories that have
accumulated hundreds of branches with nobody deleting the merged ones. Every branch on origin is
sorted into exactly one tier, first match wins:

| Tier | Condition | Action |
|---|---|---|
| 1. delete | Merged into every configured env branch | Delete the branch |
| 2. promote | Merged into production, missing from a lower env | Open a `chore(promote): <branch> into <env>` PR per missing env (capped) |
| 3. flag | Merged into a lower env but not a higher one, stale past `STALE_DAYS` | List in a report issue for a human to promote or revert |
| 4. archive | Merged nowhere, stale past `ARCHIVE_DAYS` | Tag `archive/<branch>`, then delete (restore with `git checkout -b <branch> archive/<branch>`) |
| 5. untouched | Everything else | Counted only |

"Merged" is tested two ways: `git merge-base --is-ancestor` catches a fast-forward or true merge
commit, and a merged-PR lookup catches a squash or rebase merge, which rewrites the commits onto
the target and defeats the ancestor test on its own. Any branch with an open PR is skipped
outright, and the keep patterns and the env branches themselves are never touched.

**Safe by default.** A `workflow_dispatch` run is a dry run unless you clear the `dry_run` box: it
prints the full report and deletes, tags and opens nothing. Only the schedule runs for real. Run
one dispatch dry run and read its report before trusting the monthly schedule for a repository.

**A run reports to three places.** The job summary carries all five tiers, each row with the
branch's tip sha, which is the recovery record for a tier 1 delete (`git branch <branch> <tip>`).
A single `Branch hygiene report` issue (label `branch-hygiene`, upserted, not one per run) carries
tiers 3 and 4 only, the branches that need a human. When the repository already has a
`SLACK_BOT_TOKEN` secret and a `SLACK_CHANNEL` variable, a Slack digest posts the four counts plus
the tier 3 list; without them the run says so in the log and carries on.

**Tuning is through repository variables, never by editing the workflow**, so one identical copy
serves every repository and a team changes its own thresholds in the GitHub UI (Settings > Secrets
and variables > Actions > Variables). Each variable is optional and falls back to the default
shown:

| Variable | Default | Meaning |
|---|---|---|
| `BRANCH_HYGIENE_ENV_BRANCHES` | `develop,test,acceptance,main` | Promotion chain, lowest to highest; last entry is production; branches that do not exist are dropped; `main` falls back to `master` |
| `BRANCH_HYGIENE_STALE_DAYS` | `60` | Tier 3 age threshold, in days |
| `BRANCH_HYGIENE_ARCHIVE_DAYS` | `180` | Tier 4 age threshold, in days |
| `BRANCH_HYGIENE_KEEP_PATTERNS` | `release/*,hotfix/*,keep/*,dependabot/*,renovate/*` | Globs never deleted, archived or promoted |
| `BRANCH_HYGIENE_PROMOTE_MAX` | `5` | Most tier 2 PRs one run may open; the rest are reported and picked up next month |
| `BRANCH_HYGIENE_SLACK_MAX` | `10` | Most branches listed in the Slack digest |

## Repository Structure

```
dept-agentic-standards/
├── agents/                        # Agent definitions (Copilot format)
│   ├── discovery.agent.md
│   ├── maintainer.agent.md
│   ├── discovery/logic.md    # Tool-agnostic workflow
│   └── maintainer/logic.md   # Tool-agnostic workflow
├── config/
│   ├── change-impact-matrix.yml   # Maps code changes → .ai/ updates
│   ├── mcp-registry.yml           # Curated MCP servers (with staleness tracking)
│   ├── stack-detection.yml        # 77 technologies across 8 ecosystems
│   ├── standard-version.yml       # Current standard version (single source of truth)
│   └── validation-rules.yml       # Rules for validate.sh
├── docs/
│   ├── bmad-safe-migration.md     # Migrating a repo that already runs BMAD
│   ├── confluence-page-standard.md # Shape of the handover pages
│   ├── confluence-layout.md       # How each handover section is rendered
│   ├── graphify-integration.md    # How the structural pre-pass is used
│   ├── roadmap.md                 # 5-phase rollout plan
│   ├── success-metrics.md         # KPIs and feedback loop
│   └── vision.md                  # Strategic direction
├── examples/
│   ├── example-ai-folder.md       # Next.js + Contentful + Azure
│   ├── dotnet-api-example.md      # .NET 8 + Azure App Service
│   └── python-monorepo-example.md # FastAPI + Celery + AWS
├── prompts/
│   ├── migrate.prompt.md          # Orchestrator (chains 4 phases)
│   ├── 01-install.prompt.md       # Phase 1: Install agents + skills
│   ├── 02-discover.prompt.md      # Phase 2: Analyze + generate .ai/
│   ├── 03-integrate.prompt.md     # Phase 3: Wire tools + Confluence
│   └── 04-stack-tooling.prompt.md # Phase 4: Skills + MCP servers
├── scripts/
│   ├── install.sh                 # Installs the standard into a target repository
│   ├── graphify-bootstrap.sh      # Structural pre-pass helper
│   ├── onboard-central.sh         # Hands a new project's context to the central context repository
│   ├── mirror-claude.sh           # Creates and repairs the Claude Code mirror symlinks
│   ├── gen-dependabot.sh          # Seeds .github/dependabot.yml from tracked lockfiles
│   ├── scaffold.sh                # Deterministic .ai/ folder creation
│   ├── validate.sh                # Quality gate for .ai/ compliance
│   ├── dev-setup/macos.sh         # One-run Mac setup for a new MS developer (not installed into projects)
│   └── version-report.sh          # Which projects run an outdated standard version
├── standards/
│   ├── agentic-project-standard.md # The formal standard definition
│   └── writing-rules.md            # What may be written into .ai/, one home
└── templates/                     # Templates for all generated files
    ├── meta.template.yml
    ├── project-context.template.md
    ├── architecture.template.md
    ├── ... (9 context templates)
    ├── AGENTS.template.md
    ├── AGENTS.central.template.md  # Wiring file of a project cut over to the central context repository
    ├── CLAUDE.template.md
    ├── skills/
    │   ├── codebase-overview/SKILL.md
    │   ├── confluence-axi/SKILL.md
    │   └── context-ownership/SKILL.md
    ├── workflows/
    │   ├── maintainer.yml            # Scheduled .ai/ drift maintenance (opt-in)
    │   ├── dependabot-auto-merge.yml # Auto-merge green Dependabot patch PRs (opt-in)
    │   └── branch-hygiene.yml        # Monthly tiered stale-branch cleanup (opt-in)
    └── agents/support.template.md
```

## Configuration

### Stack Detection

`config/stack-detection.yml` covers 77 technologies across:
- Frontend (Next.js, React, Vue, Svelte, Remix, Astro)
- Backend (.NET, Python, Go, Java, PHP, Ruby, Rust)
- CMS (Contentful, Sanity, Storyblok, WordPress, Strapi)
- Infrastructure (Terraform, Bicep, Pulumi, Docker, K8s)
- CI/CD (GitHub Actions, Azure Pipelines, GitLab, Jenkins)
- Database (Prisma, Drizzle, Supabase, PostgreSQL, MongoDB)
- And more...

### MCP Registry

`config/mcp-registry.yml` — manually verified MCP servers with:
- Per-entry `last_verified` dates
- Detection hints matching stack-detection categories
- Transport type (stdio/HTTP), auth methods, and quality notes
- Staleness policy: re-verify entries older than 90 days

## Roadmap

| Phase | Status | Description |
|-------|--------|-------------|
| 1. Standard | ✅ Complete | Define `.ai/` baseline + templates |
| 2. Agents | ✅ Complete | Discovery + Maintenance agents |
| 3. Scale | 🔄 In Progress | Roll out across Managed Services |
| 4. Specialize | Planned | Incident, Release, QA agents |
| 5. Commercial | Planned | Service proposition + pricing |

See [docs/roadmap.md](docs/roadmap.md) for details.

## Measuring Success

See [docs/success-metrics.md](docs/success-metrics.md) for:
- Leading indicators (weekly): migration count, scaffold success rate, developer adoption
- Lagging indicators (monthly): staleness, MTTR improvement, developer NPS
- Red flags and automated collection methods

## Versioning

`config/standard-version.yml` is the single source of truth for the standard's version.

- **Every change to standard content is recorded in the changelog.** Standard content is everything
  the standard installs into a target repository: agents, prompts, templates, standards, scripts and
  config. Each such change adds a bullet to the changelog entry of the current unreleased version.
  The `.github/workflows/version-bump.yml` check fails a pull request whose `version` sorts below the
  base branch's current one; it does not require a new number, because a change may stack onto the
  current unreleased version rather than open a new one. Repo-only changes (`docs/`, `examples/`,
  `README.md`, `AGENTS.md`, CI) do not need a changelog entry.
- **Patch for a fix, minor for a change.** A correction inside an existing artifact (a missing rule,
  a wrong path, a clarified instruction) is a patch bump: `2.7.0` to `2.7.1`. A new artifact, a new
  installed file, a changed workflow or anything a migrated project has to act on is a minor bump.
  A file-layout change stays a major bump. Reserve minor bumps for changes worth a project's
  attention, so the changelog stays a signal.
- **The version advances per release, not per pull request.** `config/standard-version.yml`'s
  `version` is the current *unreleased* line; production tracks whatever was last deployed, which is
  usually behind it (this repo tags no releases). While that version has not shipped, every
  standard-content PR stacks its changelog bullets under it and leaves the number alone, so several
  merged PRs can share one version. The number only advances to the next patch, minor or major when
  a new release cycle starts, after the current version reaches production. So do not bump to the
  next number just because the base branch already carries the current one: stack onto it unless its
  release has shipped.
- **Every migrated project reports its version.** `.ai/.meta.yml` carries `standard_version`.
  `scripts/install.sh` refreshes the project's vendored `config/standard-version.yml` and stamps
  the current version into an existing `.ai/.meta.yml`, so a refreshed project reports what it
  actually runs. The vendored copy carries the `standard:` header only: the changelog is this
  repository's release history, nothing in a target repository reads it, and the installer trims
  it out and leaves a link back here instead.
- **`scripts/version-report.sh` answers "which projects are behind?"** Run it from this repository
  against one or more project paths. It reads each project's `.ai/.meta.yml` `standard_version`,
  compares it against the current version in this repository's `config/standard-version.yml`, and
  prints a table of project, recorded version, current version and behind yes/no. It exits 1 when
  any project is behind, so a scheduled job can gate on it.

  ```bash
  ./scripts/version-report.sh ~/work/project-a ~/work/project-b
  ./scripts/version-report.sh ~/work/*/
  ```

- **`scripts/validate.sh` is the per-project consistency check.** It compares the recorded
  `standard_version` against the project's own vendored `config/standard-version.yml` and warns
  when the two disagree, naming both versions and the refresh command
  (`bash scripts/install.sh . --update`). A missing version on either side is a warning, not a
  failure. It runs inside a project and only sees that project's vendored copy, so use
  `version-report.sh` for the comparison against the current standard.

## Contributing

1. Clone this repo
2. Make changes to templates, agents, or config
3. Bump version in `config/standard-version.yml` if changing the standard (CI enforces this, see
   [Versioning](#versioning))
4. Test with `./scripts/scaffold.sh` on a sample project
5. Validate with `./scripts/validate.sh`
6. Open a PR
