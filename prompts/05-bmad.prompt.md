---
description: "Phase 5: Install BMAD with DEPT® delivery conventions on projects that don't already have it. Non-destructive, idempotent. Installs bmad-method, dept-baseline customisations, and auto-detected stack modules (dept-aem, dept-contentful, dept-ecommerce). Skip for lightweight or short-lived migrations."
---

# Phase 5: BMAD Integration

> Self-contained phase. Can be run independently. Idempotent — safe to re-run.

## Decision: Should This Project Get BMAD?

**Skip Phase 5 entirely when any of the following is true:**

- `_bmad/` directory already exists at the repository root → BMAD is already installed; log `BMAD: already installed — skipped` and stop
- Project is a standards repo, tooling repo, or infrastructure-only repo (no product delivery work)
- Migration was explicitly tagged as lightweight or short-lived

**Proceed when:**

- This is a long-lived Managed Services project
- No `_bmad/` directory exists

## Prerequisites

Before running this phase:

- Phase 4 (stack tooling) must be complete — stack detection results in `.ai/project-context.md` are used for module selection
- `npx` must be available (`node --version` and `npx --version`)
- Git working tree should be clean (recommended: commit Phase 1–4 results first)
- Network access to GitHub and npm

## Step 1: Check for Existing BMAD Installation

```bash
# Run from the repository root
if [ -d "_bmad" ]; then
  echo "✓ BMAD already installed — Phase 5 skipped"
  exit 0
fi
```

If `_bmad/` exists, output the completion block at the bottom of this prompt with status `already installed` and stop.

## Step 2: Install BMAD Core

Run the BMAD installer. It is interactive — answer the prompts using the project values from `.ai/project-context.md`:

```bash
npx bmad-method@latest install --tools claude-code
```

**When prompted by the installer, use these answers:**

| Prompt | Answer |
|---|---|
| Project name | Use the name from `.ai/project-context.md` (or `package.json#name` if no `.ai/`) |
| Output folder | `_bmad-output` (accept default) |
| Primary tool | `claude-code` (already set via flag) |
| Modules to enable | `bmm` (BMAD Method Module — enables PM, Analyst, Architect, Dev, UX, Tech Writer agents) |

After installation, verify:

```bash
# These files must exist
ls _bmad/config.toml
ls _bmad/config.user.toml
```

Expected: both files present. `_bmad/config.toml` contains `[core]` and `[agents.*]` blocks.

## Step 3: Apply DEPT® Baseline Module

Install the `dept-baseline` customisation module from `hold-agent-studio`. This applies 11 DEPT® delivery principles as 17 sparse TOML overrides across 6 agents and 11 workflows — no new agents, no new workflows, no conflicts with BMAD core:

```bash
npx bmad-method install \
  --custom-source https://github.com/dept/hold-agent-studio \
  --tools claude-code
```

When prompted to select modules, choose `dept-baseline`.

**What `dept-baseline` installs:**

| Principle | Encoded in |
|---|---|
| Outcomes over outputs | PM agent, PRD workflow, epics, product-brief |
| Reuse over bespoke | Architect agent, create-architecture workflow |
| Plain language over jargon | Analyst, Tech Writer, PRD |
| Evidence over opinion | Analyst, PRD |
| Decisions documented (ADRs) | Architect agent, create-architecture |
| Right-size the solution | PM, product-brief, architecture |
| Performance is a constraint | UX, Architect, Dev, code-review, story |
| Accessibility is a constraint | UX, Dev, code-review, story |
| Test-first discipline | Dev agent, dev-story, code-review |
| Async-first communication | PM agent |
| Trade-offs explicit | Architect agent, create-architecture |

After installation, verify:

```bash
# Customisation TOMLs must be present
ls _bmad/custom/ 2>/dev/null || ls _bmad/dept-baseline/customizations/ 2>/dev/null
```

## Step 4: Auto-Detect and Install Stack Modules

Read `.ai/project-context.md` and `.ai/architecture.md` to detect the tech stack. Install the matching DEPT® module from `hold-agent-studio`:

| If you find this in `.ai/` | Install this module |
|---|---|
| `AEM`, `Adobe Experience Manager`, `Adobe AEM` | `dept-aem` |
| `Contentful` | `dept-contentful` |
| `Shopify`, `Centra`, `ecommerce`, `e-commerce` | `dept-ecommerce` |

For each detected module:

```bash
npx bmad-method install \
  --custom-source https://github.com/dept/hold-agent-studio \
  --tools claude-code
# Select the matched module (e.g. dept-aem) when prompted
```

If none of the keywords match, skip this step and record `Stack modules: none matched` in the completion block.

## Step 5: Git Hygiene

Ensure BMAD output and dev tooling directories are gitignored:

```bash
# Add to .gitignore if not already present
for entry in "_bmad-output/" ".bmad-dashboard/"; do
  if ! grep -qF "$entry" .gitignore 2>/dev/null; then
    echo "$entry" >> .gitignore
    echo "  Added $entry to .gitignore"
  fi
done

# Add _bmad-output/ to .graphifyignore if the file exists
if [ -f ".graphifyignore" ]; then
  if ! grep -qF "_bmad-output/" .graphifyignore; then
    echo "_bmad-output/" >> .graphifyignore
    echo "  Added _bmad-output/ to .graphifyignore"
  fi
fi
```

## Step 6: Document BMAD Agents in `agent-registry.md`

Read `_bmad/config.toml` and extract the `[agents.*]` blocks. Add a **BMAD Agents** section to `.ai/agent-registry.md`:

```markdown
## BMAD Agents

Installed by BMAD v6.5+ via `npx bmad-method install`. Source: `_bmad/config.toml`.
DEPT® delivery conventions applied via `dept-baseline` module (17 sparse TOML overrides).

| Agent key | Name | Title | Module | Team |
|---|---|---|---|---|
| bmad-agent-analyst | Mary | Business Analyst | bmm | software-development |
| bmad-agent-tech-writer | Paige | Technical Writer | bmm | software-development |
| bmad-agent-pm | John | Product Manager | bmm | software-development |
| bmad-agent-ux-designer | Sally | UX Designer | bmm | software-development |
| bmad-agent-architect | Winston | System Architect | bmm | software-development |
| bmad-agent-dev | Amelia | Senior Software Engineer | bmm | software-development |

### Using BMAD Agents

Activate an agent by name in any BMAD-aware tool. Example (Claude Code):
\`\`\`
Act as Winston (BMAD System Architect). Read _bmad/config.toml for my configuration.
\`\`\`

BMAD planning and implementation artefacts are written to `_bmad-output/`:
- `_bmad-output/planning-artifacts/` — PRDs, architecture docs, epics, stories
- `_bmad-output/implementation-artifacts/` — technical design, runbooks, dev artefacts
- `_bmad-output/brainstorming/` — ideation docs

### DEPT® Agent Studio (Web UI)

For a visual interface to manage BMAD configuration:
\`\`\`bash
npx @dept/agent-studio
\`\`\`

Requires a GitHub Personal Access Token with `read:packages` scope (DEPT® GitHub Package Registry).
Add to `~/.npmrc`:
\`\`\`
//npm.pkg.github.com/:_authToken=YOUR_PAT
@dept:registry=https://npm.pkg.github.com
\`\`\`

This is a local dev tool — do not install it as a project dependency.
```

**Action:** Append this section to `.ai/agent-registry.md`. If a `## BMAD Agents` section already exists, skip to avoid duplicates.

## Completion Signal

Output this block when Phase 5 finishes:

```
✓ Phase 5 complete: BMAD integration

### Phase 5: BMAD
- BMAD status:       [installed / already installed — skipped]
- dept-baseline:     [installed / skipped]
- Stack modules:     [list installed modules, or "none matched"]
- Agent registry:    [updated with BMAD agents / skipped — already present]
- .gitignore:        [updated / already contained entries]
- .graphifyignore:   [updated / not present / already contained _bmad-output/]

Next: Review _bmad/config.toml. Re-run npx @dept/agent-studio for the web UI (requires read:packages PAT).
```

---

## Rollback

If BMAD installation needs to be reversed:

```bash
rm -rf _bmad/ _bmad-output/ .bmad-dashboard/
# Remove _bmad-output/ and .bmad-dashboard/ from .gitignore if they were added by this phase
# Remove the "BMAD Agents" section from .ai/agent-registry.md
```

BMAD installation is purely additive — no existing project files are modified.
