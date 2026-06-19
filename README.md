# DEPT Agentic Project Standards

> Making Managed Services projects AI-ready with structured context, governed agents, and automated maintenance.

## What This Is

A framework that transforms any repository into an AI-ready project by:

1. **Defining a standard** — The `.ai/` folder structure (9 context files) that any AI tool can consume
2. **Providing agents** — Discovery (bootstraps `.ai/`) and Maintainer (keeps it current)
3. **Shipping tooling** — Scaffold script, validation script, and composable migration prompts
4. **Curating registries** — Stack detection (77 technologies) and MCP server registry

## Quick Start

### Option A: Deterministic Scaffold (No LLM)

```bash
# Creates .ai/ folder structure + IDE wiring (templates only, no content)
./scripts/scaffold.sh /path/to/your/project
```

Then run the Discovery Agent to fill templates with real project data.

### Option B: Full AI Migration (LLM-powered)

**Step 1** — Bootstrap the prompt into your project (run once in terminal):
```bash
mkdir -p .github/prompts && \
  command curl -sL "https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate.prompt.md" \
  -o ".github/prompts/migrate.prompt.md"
```

**Step 2** — Run it in your AI tool:
```
# VS Code Copilot / Cursor (after step 1)
@workspace /ms-migration

# Claude Code (can fetch directly without step 1)
Fetch https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts/migrate.prompt.md and follow the instructions.

# Any tool with file access (after step 1)
Read .github/prompts/migrate.prompt.md and follow the instructions.
```

This orchestrates a Graphify pre-pass plus 4 phases:
1. **Graphify pre-pass** — attempt structural graph generation (non-blocking)
2. **Install** — agents + superpowers skills
3. **Discover** — analyze repo, generate `.ai/` context
4. **Integrate** — wire AI tools, create Confluence docs
5. **Stack Tooling** — install skills + MCP servers for detected tech

### Option C: Phase-by-Phase (Recommended for complex projects)

Bootstrap all phase prompts first:
```bash
mkdir -p .github/prompts
BASE="https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/prompts"
for f in 01-install 02-discover 03-integrate 04-stack-tooling; do
  command curl -sL "$BASE/$f.prompt.md" -o ".github/prompts/$f.prompt.md"
done
```

Then run each phase in your AI tool:
```
# VS Code Copilot / Cursor
@workspace /01-install
@workspace /02-discover
@workspace /03-integrate
@workspace /04-stack-tooling
```

### Option D: Graphify-Assisted Discovery (Default inside `/ms-migration`)

`/ms-migration` now **attempts Graphify automatically before Discovery** so you do not need two different migration habits.

Default behavior inside `/ms-migration`:
- if `graphify` is installed, run `graphify .` and then `graphify cluster-only .`
- else if `uv` is available, run `uv tool install graphifyy` and then `graphify .` and `graphify cluster-only .`
- else if `pipx` is available, run `pipx install graphifyy` and then `graphify .` and `graphify cluster-only .`
- else if `python3` is available, run `python3 -m pip install --user graphifyy` and then `python3 -m graphify .` and `python3 -m graphify cluster-only .`
- else continue migration without blocking

When Graphify is used, the bootstrap helper also ensures a root-level `.graphifyignore` exists. It starts with DEPT defaults such as:
- `.history/`
- `.ai/`
- `graphify-out/`
- `node_modules/`, `dist/`, `build/`, `.next/`, `coverage/`, `.turbo/`, `.cache/`, `.vercel/`

This works with upstream Graphify behavior: `.gitignore` is still respected, and `.graphifyignore` adds extra exclusions for migration noise.

**Important:** Graphify can run without an API key for code-only repositories, but doc-heavy repositories may fail with `error: no LLM API key found (... doc/paper/image file(s) need semantic extraction)`. In that case, set one of `GOOGLE_API_KEY`, `GEMINI_API_KEY`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `MOONSHOT_API_KEY`, or `DEEPSEEK_API_KEY` before running the migration, or let the migration continue without Graphify.

The `graphify-out/cache/ast/` JSON files are expected AST cache output, not a failure by themselves. Graphify can also look idle after AST reaches 100% because the report-generation step still needs to run.

Also install the matching Graphify backend dependency when needed:
- OpenAI backend → `uv tool install "graphifyy[openai]" --force`
- Gemini backend → `uv tool install "graphifyy[gemini]" --force`
- Claude backend → `uv tool install "graphifyy[anthropic]" --force`
- If `uv` is unavailable, prefer `pipx install "graphifyy[...]" --force`
- If both `uv` and `pipx` are unavailable, install pipx first with `python3 -m pip install --user pipx` and then use `python3 -m pipx install "graphifyy[...]" --force`

If Graphify says `the 'openai' package is required for this backend but is not installed`, it found your API key but the backend dependency is missing. If `graphify` is already on PATH, reinstall that same tool with the matching extra instead of only rerunning the base install.

**Why this shape?**
- one entry point for users (`/ms-migration`)
- better structural discovery when Graphify is available
- migration still succeeds on machines where Graphify cannot be installed

**Use Graphify as an accelerator, not a replacement for `.ai/`.**
- `graphify-out/` helps with code structure, dependency shape, and cross-file relationships
- `.ai/` still captures operational context, onboarding, environments, ownership, runbooks, and support constraints
- Discovery treats `graphify-out/` as **supplemental evidence** and verifies important claims against the source repository
- `graphify-out/` should be ignored in Git by default unless a team explicitly chooses to commit it

See [docs/graphify-integration.md](docs/graphify-integration.md) for the workflow and caveats.

## What Gets Created

After migration, your project has:

```
your-project/
├── .ai/                           # AI context (the standard)
│   ├── .meta.yml                  # Provenance & version tracking
│   ├── project-context.md         # Business context, ownership, environments
│   ├── architecture.md            # System topology, data flows, boundaries
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

## Validation

Verify any project's `.ai/` folder meets the standard:

```bash
./scripts/validate.sh /path/to/your/project
```

Checks: required files present, content quality, placeholder detection, staleness.

## Agents

| Agent | Purpose | Logic |
|-------|---------|-------|
| [Discovery Agent](agents/ai-project-discovery.agent.md) | Bootstraps `.ai/` from scratch | [logic.md](agents/ai-project-discovery/logic.md) |
| [Maintainer Agent](agents/ai-project-maintainer.agent.md) | Keeps `.ai/` current over time | [logic.md](agents/ai-project-maintainer/logic.md) |

Agent logic is separated from tool-specific wiring — see `agents/*/logic.md` for portable workflow definitions.

## Repository Structure

```
dept-agentic-standards/
├── agents/                        # Agent definitions (Copilot format)
│   ├── ai-project-discovery.agent.md
│   ├── ai-project-maintainer.agent.md
│   ├── ai-project-discovery/logic.md    # Tool-agnostic workflow
│   └── ai-project-maintainer/logic.md   # Tool-agnostic workflow
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
| 2. Agents | ✅ Complete | Discovery + Maintainer agents |
| 3. Scale | 🔄 In Progress | Roll out across Managed Services |
| 4. Specialize | Planned | Incident, Release, QA agents |
| 5. Commercial | Planned | Service proposition + pricing |

See [docs/roadmap.md](docs/roadmap.md) for details.

### Next Steps — Phase 3+ Tickets

Ready-to-implement improvement tickets for Q3 2026+:
- **MA-1:** Pilot Program — Bootstrap 5 reference projects
- **MA-2:** Jira MCP integration
- **MA-3:** Agent escalation workflows
- **MA-4:** Adoption dashboard
- **MA-5:** Troubleshooting guide
- Plus 10+ additional tickets for Phase 4, 5, 6

See [docs/phase3-plus-tickets.md](docs/phase3-plus-tickets.md) for full backlog (can be imported to Jira).

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
