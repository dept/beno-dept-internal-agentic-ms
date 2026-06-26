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
│   ├── agents/                    # Copilot agent definitions
│   ├── copilot-instructions.md    # Copilot → .ai/ wiring
│   ├── instructions/              # VS Code AI context
│   ├── prompts/                   # Reusable prompts
│   └── skills/                    # Superpowers skills
├── CLAUDE.md                      # Claude → .ai/ wiring
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

2. **Wire AI tools** — Copy or symlink the relevant tool files to your IDE:
   - `CLAUDE.md` → Claude Code (`/ms-migration` step 3 handles this)
   - `.github/copilot-instructions.md` → GitHub Copilot
   - `.vscode/mcp.json` → VS Code + MCP servers
   - `.cursor/mcp.json` → Cursor + MCP servers

3. **Create Confluence docs** — Export summaries from `.ai/` files:
   - `project-context.md` → "Project Overview" page
   - `architecture.md` → "System Architecture" page
   - `onboarding.md` → "Getting Started" page
   - `runbooks.md` → "Incident Response" page

4. **Distribute to team** — Check `.ai/` into Git and point developers to `CLAUDE.md` or `CLAUDE.code` (IDE extensions auto-load these).

5. **Schedule Maintainer** — Set a monthly or quarterly reminder to run the **Maintainer Agent** (see agents below) to keep `.ai/` current as the codebase evolves.

## Validation

Verify any project's `.ai/` folder meets the standard:

```bash
./scripts/validate.sh /path/to/your/project
```

Checks: required files present, content quality, placeholder detection, staleness.

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
│   ├── scaffold.sh                # Deterministic .ai/ folder creation
│   └── validate.sh                # Quality gate for .ai/ compliance
├── standards/
│   └── agentic-project-standard.md # The formal standard definition
└── templates/                     # Templates for all generated files
    ├── meta.template.yml
    ├── project-context.template.md
    ├── architecture.template.md
    ├── ... (9 context templates)
    ├── copilot-instructions.template.md
    ├── CLAUDE.template.md
    ├── ai-context.instructions.template.md
    └── agents/
        └── support-agent.template.md
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

## Contributing

1. Clone this repo
2. Make changes to templates, agents, or config
3. Bump version in `config/standard-version.yml` if changing the standard
4. Test with `./scripts/scaffold.sh` on a sample project
5. Validate with `./scripts/validate.sh`
6. Open a PR
