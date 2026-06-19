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
3. Sanitize the page title before creating it: decode HTML entities, never leave `&amp;` or `@amp;` in the title, and prefer `and` instead of symbols when needed for readability.
4. Keep the layout consistent with other MS projects by using this fixed structure:
   - Main page: `[Project Name]`
   - Subpage: `Overview`
   - Subpage: `Architecture & Package Map`
   - Subpage: `Environments & Access`
   - Subpage: `Onboarding & Handover`
5. Make content readable for mixed roles (developer + client manager).
6. In `Overview`, include what the system does, key contacts, and the main business capabilities. When the project has multiple packages, features, brands, or campaigns, add a short plain-language summary for each major area so a new developer can quickly understand what each one is for.
7. In `Architecture & Package Map`, document each major app/package/feature/campaign and what it is responsible for. For monorepos or multi-brand/campaign projects, include both:
   - an inventory table for quick scanning
   - a short summary paragraph or bullet for each major package/feature/campaign explaining purpose, ownership/context, and notable dependencies or integrations when known
8. If the repository has a `doc/` or `docs/` folder, use it as a primary input for Confluence wording, package/campaign descriptions, and onboarding context — but still verify against code/config when facts conflict.
9. In `Environments & Access`, include GitHub, test/acc/prod URLs, and Keeper reference.
10. In `Onboarding & Handover`, include setup steps, troubleshooting, escalation, and project-specific gotchas.
11. Include all 5 links collected in Phase 2 Step 4.
12. Do NOT create a separate coding standards page unless explicitly requested.

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
