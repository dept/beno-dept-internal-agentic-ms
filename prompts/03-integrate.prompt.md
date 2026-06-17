---
description: "Phase 3: Wire AI tools to load .ai/ context and create Confluence documentation."
---

# Phase 3: Integration

> Self-contained phase. Requires Phase 2 (.ai/ folder generated). Idempotent.

## Prerequisites

- Phase 2 completed (`.ai/` folder with 9 context files exists)
- Confluence access (for documentation creation)

## Step 6: Wire AI Tools

Create or update wiring files so every AI tool (Copilot, Claude, Cursor) automatically reads `.ai/` context at session start.

**Rule:** Check each file first. If it exists, append only. Never overwrite existing content.

### File 1: `.github/copilot-instructions.md`
- **Not present**: create with full `.ai/` reading instructions and behaviour rules
- **Already present**: append a `## AI Project Context (.ai/)` section

### File 2: `CLAUDE.md` (repository root)
- **Not present**: create with same instructions in Claude format
- **Already present**: append a `## AI Project Context (.ai/)` section

### File 3: `.github/instructions/ai-context.instructions.md`
- **Not present**: create with `applyTo: "**"` frontmatter and concise loading instructions
- **Already present**: leave unchanged (report as already present)

### All wiring files must instruct AI to:
1. Read `.ai/` files at session start
2. Cross-reference `.ai/` with agents/instructions/skills found in Phase 2
3. Respect constraints in existing agentic files
4. Flag contradictions between `.ai/` and codebase (don't silently accept stale context)

## Step 7: Create Confluence Project Documentation

After wiring is complete, create handover documentation in Confluence.

**Target location:**
- Space: `MS`
- Path: `Projects`
- Base URL: `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

**Action steps:**
1. Ensure `Projects` directory exists. Create if missing.
2. Create a project page under `Projects` if not present.
3. Make content readable for mixed roles (developer + client manager).
4. Use subpages for readability:
   - Overview (what the system is, key contacts)
   - Environments and Access (GitHub, test/acc/prod URLs, Keeper reference)
   - Onboarding and Handover (setup steps, troubleshooting, escalation)
5. Include all 5 links collected in Phase 2 Step 4.
6. Do NOT create a separate coding standards page unless explicitly requested.

## Verification

Before proceeding to Phase 4, confirm:
- [ ] `.github/copilot-instructions.md` references `.ai/` folder
- [ ] `CLAUDE.md` references `.ai/` folder
- [ ] `.github/instructions/ai-context.instructions.md` exists
- [ ] Confluence pages created (or report why not)

## Completion Signal

```
✓ Phase 3 complete: AI tools wired and Confluence documentation created.
  Next: Run Phase 4 (04-stack-tooling.prompt.md) to install stack-specific tools.
```
