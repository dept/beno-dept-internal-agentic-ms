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

To keep project handover pages consistent across repositories, use the canonical Confluence layout defined in [docs/confluence-page-standard.md](docs/confluence-page-standard.md).

That standard fixes:
- the page tree
- the default section order per page
- the requirement for a Mermaid overview on the architecture page
- where customization is allowed versus where structure should stay stable

The goal is: **same base structure everywhere, with only small project-specific additions when needed**.

### Optional: Graphify-Assisted Discovery

The full migration can pre-scan your repo with **Graphify** before Discovery. This generates structural context that the Discovery Agent can use to prioritize inspection.

- If no LLM API key is available, the helper still runs Graphify in **code-only fallback mode**
- If you want Graphify to include docs / papers / images, set a supported key (`OPENAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `ANTHROPIC_API_KEY`, `MOONSHOT_API_KEY`, or `DEEPSEEK_API_KEY`) in your shell or in `.env`, `.env.local`, `.env.graphify`, or `.env.graphify.local` before running the helper
- If you reinstall or upgrade Graphify for a specific backend, refresh the assistant integration with `graphify install`

See [docs/graphify-integration.md](docs/graphify-integration.md) for setup and troubleshooting.

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

Once Discovery completes, your `.ai/` folder is live. Next steps:

1. **Validate** — Run the standard check:
   ```bash
   ./scripts/validate.sh /path/to/your/project
   ```

2. **Wire AI tools**: Phase 3 writes these, check they are present:
   - `AGENTS.md` → Copilot (github.com and VS Code), Codex, Cursor
   - `CLAUDE.md` → Claude Code, as an `@AGENTS.md` import
   - `.vscode/mcp.json` → VS Code + MCP servers
   - `.cursor/mcp.json` → Cursor + MCP servers

3. **Create Confluence docs** — Export summaries from `.ai/` files:
   - `project-context.md` → "Project Overview" page
   - `architecture.md` → "System Architecture" page
   - `onboarding.md` → "Getting Started" page
   - `runbooks.md` → "Incident Response" page

4. **Distribute to team** — Check `.ai/` into Git and point developers to `CLAUDE.md` or `CLAUDE.code` (IDE extensions auto-load these).

5. **Schedule Maintainer** — Set a monthly or quarterly reminder to run the **Maintainer Agent** (see agents below) to keep `.ai/` current as the codebase evolves.

6. **Clean up (Phase 5)** — Remove one-time migration artifacts so the repo keeps only what has ongoing value. See the table below. Migrate prompt's Phase 5 automates this (asks first).

### What to keep vs. remove after migration

The migration installs **runtime** artifacts (used forever) and **install-time** artifacts (used once). After a successful, verified migration you can prune the latter.

| Artifact | Keep? | Why |
|---|---|---|
| `.ai/` (9 files + `.meta.yml`) | **Keep** | Single source of truth |
| Maintainer agent (`.github/agents/maintainer.agent.md` + `.claude/agents/maintainer.md`) | **Keep** | Ongoing drift maintenance |
| Support agent (`support.agent.md` + `.claude/agents/support.md`) | **Keep** | Day-to-day dev/support |
| Wiring (`AGENTS.md` and its `CLAUDE.md` import) | **Keep** | Every harness routes into `.ai/` through it |
| `standards/writing-rules.md` | **Keep** | The Maintainer applies it on every run |
| Stack skills (`.agents/skills/`, including `confluence-axi`) | **Keep** | Reused; Maintainer re-syncs Confluence via `confluence-axi` |
| MCP config incl. `datadog` (browser OAuth) | **Keep** | Maintainer re-fetches key features via the Datadog MCP |
| MCP config (`.vscode/mcp.json`, `.cursor/mcp.json`, `.mcp.json`) | **Keep** | Developer sessions |
| `scripts/validate.sh` | **Keep** | Maintainer/CI compliance |
| `scripts/mirror-claude.sh` | **Keep** | Creates and repairs the Claude Code mirror symlinks when an agent or skill is added or removed |
| `.ai/confluence/*.md` drafts | **Remove once published** | Maintainer syncs from `.ai/` via `sync_map`, not from drafts |
| Discovery agent (`discovery.agent.md` + `.claude/agents/discovery.md`) | **Remove** (optional) | Only for initial bootstrap; Maintainer does incremental. Keep for cheap re-bootstrap |
| Phase prompts `01`–`04` + command mirrors (`ms-install`/`ms-discover`/`ms-integrate`/`ms-stack-tooling`) | **Remove** (optional) | One-time steps; clutter the command palette |
| Migrate prompt + `ms-migration` command mirrors (`.github/prompts/migrate.prompt.md`, `.claude/commands/`, `.cursor/commands/`) | **Remove** (optional) | One-time too; a full re-run starts from the standards repo bootstrap, which installs a current copy |
| `scripts/graphify-bootstrap.sh` | **Remove** (optional) | One-time pre-pass; keep if re-graphing planned |
| `graphify-out/` | **Remove** | Ephemeral (already gitignored) |

> **A version refresh does not bring the removed artifacts back.** `scripts/install.sh` treats the
> migrate prompt, the `ms-migration` command, the discovery agent, the phase prompts `01`–`04` and
> `scripts/graphify-bootstrap.sh` as bootstrap-only: in a project that has a `.ai/.meta.yml` it
> neither creates nor refreshes them, and it lists what it skipped and why in its summary.
> Everything in the **Keep** rows above is refreshed as usual. The installer never deletes anything,
> so removing them stays your explicit choice.

> **Remove symmetrically.** `validate.sh` compares file counts between each source directory and its mirror (`.github/agents/` with `.claude/agents/`, `.github/prompts/` with the two command folders, `.agents/skills/` with `.claude/skills`). Delete an agent from `.github/agents/` **and** its `.claude/agents/` symlink (which is a broken link once the source is gone), and a prompt from `.github/prompts/` **and** both command folders, or you introduce a "mirror out of sync" warning. Skills are the exception: `.claude/skills` is one symlink to the whole `.agents/skills` directory, so deleting the skill from the source is already symmetric and the symlink itself stays. Re-run `validate.sh` after cleanup to confirm status is unchanged. Nothing about the cleanup is written into `.ai/`.

## Validation

Verify any project's `.ai/` folder meets the standard:

```bash
./scripts/validate.sh /path/to/your/project
```

Checks: required files present, content quality, placeholder detection, staleness, mirror parity,
and reference integrity (every standard-owned path named in `.ai/`, the wiring files and the skills
must resolve; a broken one fails the run).

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
│   └── 04-stack-tooling.prompt.md # Phase 4: Skills + MCP + support agent
├── scripts/
│   ├── install.sh                 # Installs the standard into a target repository
│   ├── graphify-bootstrap.sh      # Structural pre-pass helper
│   ├── mirror-claude.sh           # Creates and repairs the Claude Code mirror symlinks
│   ├── scaffold.sh                # Deterministic .ai/ folder creation
│   ├── validate.sh                # Quality gate for .ai/ compliance
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
    ├── CLAUDE.template.md
    ├── skills/
    │   ├── codebase-overview/SKILL.md
    │   └── confluence-axi/SKILL.md
    ├── workflows/maintainer.yml
    └── agents/support.template.md
        └── support.template.md
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

- **Every change to standard content bumps it.** Standard content is everything the standard
  installs into a target repository: agents, prompts, templates, standards, scripts and config.
  The `.github/workflows/version-bump.yml` check fails a pull request that changes standard
  content without changing the `version` field, so bump the field and add a changelog entry in
  the same PR. Repo-only changes (`docs/`, `examples/`, `README.md`, `AGENTS.md`, CI) do not
  need a bump.
- **One bump per pull request, not per commit.** While a PR is open and unmerged, further commits
  on that branch amend the changelog entry for the version being released; they never add another
  version. A new version number is only introduced by a PR that does not already carry an
  unreleased bump.
- **Every migrated project reports its version.** `.ai/.meta.yml` carries `standard_version`.
  `scripts/install.sh` refreshes the project's vendored `config/standard-version.yml` and stamps
  the current version into an existing `.ai/.meta.yml`, so a refreshed project reports what it
  actually runs.
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
