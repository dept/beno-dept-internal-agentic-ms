# BMAD-Safe Migration to DEPT Standards

When onboarding a BMAD-enabled project into MS (Managed Services), the priority is **preserving BMAD's operational integrity** while overlaying the DEPT agentic standards framework. This is a **non-destructive migration** — BMAD files are never deleted or overwritten.

---

## What is BMAD?

[BMAD (Build Me A Dream)](https://github.com/bmad-ai/bmad-method) is an AI-driven project management and development workflow. When run, it generates a `_bmad-output/` folder in the project root containing structured planning and operational artefacts:

```
_bmad-output/
├── project-brief.md          # High-level project goals and scope
├── architecture.md           # System architecture and design decisions
├── epics/                    # Epic breakdowns
│   └── epic-*.md
├── stories/                  # User stories
│   └── story-*.md
├── docs/
│   ├── prd.md                # Product requirements document
│   ├── technical-design.md   # Technical design decisions
│   └── runbooks.md           # Operational runbooks (if generated)
└── .bmad-core/               # BMAD agent definitions and config
```

> **Note:** The exact `_bmad-output/` structure depends on which BMAD agents were run and the project type. Always inspect the actual folder before starting migration.

---

## The Challenge

**BMAD projects already have:**
- Architecture and design decisions in `_bmad-output/architecture.md`
- Product requirements in `_bmad-output/docs/prd.md`
- Operational runbooks (if BMAD's ops agents were run)
- Epic and story breakdowns as active work artefacts

**DEPT standards add:**
- Standardized `.ai/` folder for AI context (project-context, architecture, runbooks, etc.)
- Agentic wiring for Copilot, Claude Code, and Cursor
- Stack-specific skills and MCP server auto-wiring
- Support agent pre-configured with all available tools

**The conflict:** Running a destructive migration (full replacement) would discard BMAD's carefully-generated content and break active BMAD workflows.

**The solution:** Overlay the DEPT scaffold, absorb `_bmad-output/` as evidence, and populate the missing `.ai/` files without touching BMAD artefacts.

---

## Migration Strategy: Non-Destructive Overlay

### Phase 0: Pre-flight Check

Before running anything, understand what BMAD generated:

```bash
# 1. Inspect _bmad-output/ to understand what exists
ls -la _bmad-output/
ls -la _bmad-output/docs/ 2>/dev/null || echo "No docs/ subfolder"

# 2. Check if .ai/ already exists (avoid conflicts)
test ! -d ./.ai && echo "✓ No existing .ai/ — safe to scaffold" || \
  echo "⚠ .ai/ already exists — back it up or skip scaffold"

# 3. Ensure working tree is clean before migrating
git status --short
```

### Phase 1: Overlay DEPT Scaffold (Non-destructive)

Run the deterministic scaffold. It is **idempotent** — it never overwrites existing files:

```bash
# From the dept-agentic-standards repo root:
./scripts/scaffold.sh /path/to/bmad-project

# What this creates (all NEW, nothing touched in _bmad-output/):
# .ai/
# ├── .meta.yml
# ├── project-context.md       ← empty template, Discovery will fill from _bmad-output/
# ├── architecture.md          ← empty template, Discovery will fill from _bmad-output/architecture.md
# ├── runbooks.md              ← empty template, Discovery will fill from _bmad-output/docs/runbooks.md
# ├── dependencies.md          ← empty template
# ├── cms.md                   ← empty template
# ├── operational-context.md   ← empty template
# ├── coding-standards.md      ← empty template
# ├── agent-registry.md        ← empty template
# └── onboarding.md            ← empty template
#
# .github/
# └── agents/
#     └── support.agent.md   ← NEW (template, Phase 4 fills placeholders)
#
# AGENTS.md                    ← NEW (the one authored wiring file)
# CLAUDE.md                    ← NEW (@AGENTS.md import)
#
# _bmad-output/                ← UNTOUCHED
```

### Phase 2: Run Discovery Agent (Absorb `_bmad-output/` Evidence)

The Discovery Agent reads **both** the empty `.ai/` templates **and** BMAD's `_bmad-output/` artefacts and uses them as evidence:

```
@workspace /02-discover
```

**What the Discovery Agent extracts from `_bmad-output/`:**

| `_bmad-output/` source | `.ai/` target | What gets extracted |
|---|---|---|
| `architecture.md` | `.ai/architecture.md` | System topology, service boundaries, design decisions |
| `docs/prd.md` | `.ai/project-context.md` | Business context, goals, key stakeholders |
| `docs/technical-design.md` | `.ai/architecture.md` | Technical decisions, patterns, constraints |
| `docs/runbooks.md` | `.ai/runbooks.md` | Operational procedures, incident response |
| `epics/*.md` + `stories/*.md` | `.ai/project-context.md` | Current work scope, feature overview |
| `.bmad-core/` | `.ai/agent-registry.md` | Existing BMAD agent definitions |
| `package.json` / `go.mod` / etc. | `.ai/dependencies.md` | Direct dependencies |
| `.github/workflows/*.yml` | `.ai/operational-context.md` | CI/CD procedures |

**Key principle:** `_bmad-output/` is the authoritative source. The Discovery Agent reads it as evidence and absorbs it into `.ai/` — it does **not** replace or delete any BMAD file.

### Phase 3: Fill Missing Runbooks

After Discovery completes, review what gaps remain in `.ai/runbooks.md`:

```bash
# Check what BMAD's runbooks cover vs what DEPT expects
cat _bmad-output/docs/runbooks.md 2>/dev/null || echo "No BMAD runbooks found — create from scratch"
cat .ai/runbooks.md
```

Supplement `.ai/runbooks.md` with anything Discovery couldn't find in `_bmad-output/`:
- Incident escalation procedures (on-call contacts, management chain)
- Maintenance windows and change freeze periods
- Disaster recovery procedures and RTO/RPO targets
- Rollback runbooks specific to the deployment pipeline

### Phase 4+: Continue Normal Migration

Once `.ai/` is populated, proceed with the standard phases:

```bash
# Phase 3: Wire AI tools, create Confluence pages
@workspace /03-integrate

# Phase 4: Detect stack, install skills and MCP servers, finalise support agent
@workspace /04-stack-tooling
```

---

## Before and After: Project Structure

**Before migration (BMAD project):**
```
my-bmad-project/
├── _bmad-output/
│   ├── project-brief.md
│   ├── architecture.md
│   ├── epics/
│   │   └── epic-01-auth.md
│   ├── stories/
│   │   └── story-01-login.md
│   ├── docs/
│   │   ├── prd.md
│   │   ├── technical-design.md
│   │   └── runbooks.md
│   └── .bmad-core/
│       └── agents/
├── src/
├── package.json
└── .github/
    └── workflows/
        └── ci.yml
```

**After BMAD-safe migration:**
```
my-bmad-project/
├── _bmad-output/              ← UNTOUCHED (BMAD continues to work normally)
│   ├── project-brief.md
│   ├── architecture.md
│   ├── epics/
│   ├── stories/
│   ├── docs/
│   └── .bmad-core/
│
├── .ai/                       ← NEW (DEPT context, absorbed from _bmad-output/)
│   ├── .meta.yml
│   ├── project-context.md     ← FROM: _bmad-output/docs/prd.md + project-brief.md
│   ├── architecture.md        ← FROM: _bmad-output/architecture.md + technical-design.md
│   ├── runbooks.md            ← FROM: _bmad-output/docs/runbooks.md
│   ├── dependencies.md        ← FROM: package.json
│   ├── cms.md
│   ├── operational-context.md ← FROM: .github/workflows/
│   ├── coding-standards.md
│   ├── agent-registry.md      ← includes .bmad-core/ agents
│   └── onboarding.md
│
├── .github/
│   ├── agents/
│   │   └── support.agent.md ← NEW (Phase 4 fills in stack + MCP tools)
│   └── workflows/             ← UNCHANGED
│       └── ci.yml
│
├── .agents/skills/            ← NEW (Phase 4 installs stack skills)
├── .claude/skills             ← NEW (symlink to .agents/skills/)
├── standards/writing-rules.md ← NEW (Phase 1)
├── .vscode/mcp.json           ← NEW (Phase 4)
├── .cursor/mcp.json           ← NEW (Phase 4)
├── .mcp.json                  ← NEW (Phase 4)
├── AGENTS.md                  ← NEW
├── CLAUDE.md                  ← NEW (@AGENTS.md import)
├── src/                       ← UNCHANGED
└── package.json               ← UNCHANGED
```

**Key point:** BMAD keeps running normally. `_bmad-output/` is intact. The `.ai/` folder is a parallel addition that gives agentic tools (Copilot, Claude, Cursor) structured context without replacing anything BMAD manages.

---

## Validation Checklist

After BMAD-safe migration:

- [ ] `_bmad-output/` is fully intact (no files deleted or modified)
- [ ] `.ai/` contains all 9 required files + `.meta.yml`
- [ ] `.ai/project-context.md` reflects content from `_bmad-output/docs/prd.md`
- [ ] `.ai/architecture.md` reflects content from `_bmad-output/architecture.md`
- [ ] `.ai/runbooks.md` covers BMAD's operational procedures (or notes gaps)
- [ ] `.ai/agent-registry.md` documents BMAD agents from `.bmad-core/`
- [ ] Validation script passes: `./scripts/validate.sh .`
- [ ] Support agent is present at `.github/agents/support.agent.md`

---

## Rollback

If something goes wrong, the rollback is safe because BMAD files were never touched:

```bash
# Remove only the DEPT additions. BMAD is untouched
rm -rf .ai/ AGENTS.md CLAUDE.md .vscode/mcp.json .cursor/mcp.json .mcp.json
rm -rf .github/agents/ .agents/skills/ .claude/skills .claude/agents/ standards/writing-rules.md

# Re-run from Phase 1 once issues are resolved
./scripts/scaffold.sh .
```

---

## Troubleshooting

### Discovery Agent doesn't find `_bmad-output/`

**Symptom:** `.ai/` files are mostly empty after Phase 2.

**Cause:** The Discovery Agent's analysis scope excluded `_bmad-output/` or the BMAD folder has a non-standard name.

**Fix:**
```bash
# Verify the folder name
ls -la | grep bmad

# If named differently, manually copy key content into .ai/
cat _bmad-output/architecture.md >> .ai/architecture.md
cat _bmad-output/docs/prd.md >> .ai/project-context.md
```

### `.ai/runbooks.md` and `_bmad-output/docs/runbooks.md` diverge over time

**Symptom:** BMAD was updated after migration but `.ai/` wasn't synced.

**Fix:** Treat `_bmad-output/` as source of truth. Re-run Discovery or manually sync:
```bash
@workspace /02-discover  # re-runs Discovery, absorbs latest _bmad-output/
```

### Support agent lacks BMAD context

**Symptom:** Support agent says "no information about current epics or architecture decisions".

**Fix:** Ensure `.ai/project-context.md` and `.ai/architecture.md` were populated from `_bmad-output/` during Phase 2. Check:
```bash
grep -l "bmad\|prd\|epic" .ai/*.md
```

---

## Related Tickets

| Ticket | Title |
|--------|-------|
| MA-16 | BMAD Project Detection — auto-detect `_bmad-output/` and route to non-destructive scaffold |
| MA-17 | BMAD Evidence Absorption — Discovery Agent reads `_bmad-output/` as primary evidence source |
| MA-18 | BMAD + DEPT Conflict Resolution — rules for when `_bmad-output/` and `.ai/` diverge |
