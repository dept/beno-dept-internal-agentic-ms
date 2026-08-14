---
description: "Phase 3: Wire AI tools to load .ai/ context and create Confluence documentation."
---

# Phase 3: Integration

> Self-contained phase. Requires Phase 2 (.ai/ folder generated). Idempotent.

## Prerequisites

- Phase 2 completed (`.ai/` folder with 9 context files exists)
- Confluence access (for documentation creation)

## Step 6: Wire AI Tools

Create or update the two wiring files so every AI tool finds `.ai/` context. **`.ai/` is the single shared source of truth**; the wiring files are pointers into it.

There is one authored wiring file. Every harness in use reads it:

| Harness | How it reads `AGENTS.md` |
|---|---|
| GitHub Copilot (github.com and VS Code) | Natively, as agent instructions |
| OpenAI Codex | Natively |
| Cursor | Natively |
| Claude Code | Through the `@AGENTS.md` import in `CLAUDE.md` |

Do not create `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, or `.cursor/rules/*.mdc`. Those tools read `AGENTS.md`. If a project already has one of them, record it in `.ai/agent-registry.md` and leave it alone.

**Rule:** Check each file first. If it exists, append only. Never overwrite existing content.

> **Wiring files are pointers, not a second source of truth.** `.ai/` is
> authoritative. `standards/writing-rules.md` §3 sets what may appear in a wiring
> file: at most five repo-wide class 3 constraints, and nothing a formatter or a
> type error already fixes. Everything else is a pointer into `.ai/`. §4 gives the
> full ownership rule for both files.

### File 1: `AGENTS.md` (repository root)
- **Not present**: create from `templates/AGENTS.template.md`
- **Already present**: append the missing sections; leave what is there
- Fill `[PROJECT_SUMMARY]` with two sentences on what the system is, from `.ai/project-context.md`
- Fill `[SETUP_COMMANDS]` with the install/run commands from `.ai/onboarding.md`
- Fill `[KEY_CONSTRAINTS_ONE_LINERS]` from `.ai/coding-standards.md`, applying the §3 test to each candidate before writing it

### File 2: `CLAUDE.md` (repository root)
- **Not present**: create from `templates/CLAUDE.template.md`, which is the `@AGENTS.md` import
- **Already present**: add the `@AGENTS.md` import line if it is missing, and leave the rest
- Claude-Code-only lines (a `.claude/skills/` note, for example) may live here. Anything that applies to every harness goes in `AGENTS.md`

### Both wiring files must instruct AI to:
1. Load `.ai/` files **on demand**, never at session start. The wiring file carries a two-to-three sentence summary of what the system is plus the always-on constraints, and a routing table saying which file to read for which kind of task. Reading nothing from `.ai/` is the correct behaviour for a task that touches none of those areas, so do not instruct an eager load of `project-context.md`, `architecture.md` and `coding-standards.md`.
2. Cross-reference `.ai/` with agents/instructions/skills found in Phase 2
3. Respect constraints in existing agentic files
4. Flag contradictions between `.ai/` and codebase (don't silently accept stale context)

## Step 7: Create Confluence Project Documentation

After wiring is complete, create handover documentation in Confluence.

**Publish path: use the `confluence-axi` skill (primary).** It is installed in Phase 1 at `.agents/skills/confluence-axi/` and drives the `confluence-axi` npm CLI (`npx -y confluence-axi ...`), which wraps the Confluence Cloud REST API. Do NOT rely on the Atlassian MCP here: the MCP is only configured in Phase 4, and an MCP added to `.mcp.json` mid-session is not callable until the tool/IDE reloads, so during a single migration run the MCP is not a usable publish path for this step. Verify access first (`npx -y confluence-axi space list` → lists spaces), then create the landing page, capture its id, and create the four subpages under it with `--parent <landingId>`. When updating existing pages, resolve subpages by walking the landing page's children (`npx -y confluence-axi page children <landingId>`), never a bare title search, because the shared `MS` space collides across projects. `page update` bumps the version automatically (no 409 handling).

> **If Confluence access is unavailable** (the `confluence-axi space list` preflight
> failed — not authed, or the site is unreachable): do NOT skip the
> work silently. Instead **stage the pages as local drafts** — write one Markdown
> file per page (landing + the four subpages, following the structure below) into
> `.ai/confluence/`, and write the `confluence:` block into `.ai/.meta.yml` with
> `published: false` and empty `id`s. The Maintainer Agent (or a later run with
> access) then publishes them and backfills the IDs. Report clearly in the
> completion summary that Confluence was staged, not published.
>
> **Drafts are transient.** Once the pages are published and their real ids are
> written into `.ai/.meta.yml`, the `.ai/confluence/` drafts are no longer needed
> — the Maintainer syncs from the `.ai/` files via `sync_map`, never from the
> drafts. Phase 5 (cleanup) removes them.

**Canonical structure source:** `docs/confluence-page-standard.md`
- Use it as the default page-layout and section-order source for every project.
- Keep the base page names and section order the same unless a project-specific need clearly justifies a deviation.
- If you deviate, keep the standard structure as intact as possible and explain the deviation in your final report.

**Target location:**
- Space: `MS`
- Path: `Projects`
- Base URL: `https://dept-nl.atlassian.net/wiki/spaces/MS/Projects`

**Action steps:**
1. Ensure `Projects` directory exists. Create if missing.
2. Create a project page under `Projects` if not present.
3. Sanitize the page title before creating it: decode HTML entities, never leave `&amp;` or `@amp;` in the title, and prefer `and` instead of symbols when needed for readability.
4. Keep the layout consistent with other MS projects by using this fixed structure. **Titles must
   follow the collision-safe rule** (see `docs/confluence-page-standard.md` → *Page titles*): the
   landing page uses the human project name with **no affix**; every subpage is **prefixed with the
   landing title** — `<landing title> - <subpage name>`. The `MS` space is shared, so bare titles
   like `Overview` collide across projects.
   - Main page: `[Project Name]`  (e.g. `DEPT Client Portal`)  ← this is the landing title
   - Subpage: `[Project Name] - Overview`
   - Subpage: `[Project Name] - Architecture & Package Map`
   - Subpage: `[Project Name] - Environments & Access`
   - Subpage: `[Project Name] - Onboarding & Handover`
5. On the **main `[Project Name]` page** (the landing page), include in order:
   - A short intro paragraph (project type, client, agency)
   - `## Key facts` table: repo, framework, package manager, CMS, hosting, database, monitoring — use `[To fill in]` for unknowns
   - `## Quick links` table: GitHub, test, acceptance, production, Keeper/secrets
   - `## Documentation structure` bullet list linking to the four subpages
   - `## AI tooling status` — list context files, agents, skills, code graph, MCP servers, instructions; add a warning panel if not yet confirmed
   - `## Key contacts` table (last section) — columns `Role`, `Name`, `Contact (email)`; add a warning panel asking the team to verify before sharing
6. Make content readable for mixed roles (developer + client manager).
6b. **Confluence is written for humans; `.ai/` is written for AI tools. Never tell a Confluence reader to go read `.ai/`.** Every page must stand on its own — the answer goes on the page, not behind a pointer to a repository file. Do not write onboarding or orientation instructions such as "read the context files in order: `.ai/project-context.md`, then `.ai/architecture.md`", and do not describe `.ai/` as background reading or the fastest route into the codebase. Where the substance only exists in `.ai/`, restate it on the page in human wording.
   Two narrow exceptions, both describing the repository rather than instructing the reader: the landing page's `## AI tooling status` section may state that `.ai/` exists and what it holds, and a sync note under a synced artifact (the architecture diagram) may name the `.ai/` file that owns the source so an engineer knows where to change it.
7. In `Overview`, include what the system does and the main business capabilities. When the project has multiple packages, features, brands, or campaigns, add a short plain-language summary for each major area so a new developer can quickly understand what each one is for. Also include a `## Key Features (Monitored)` section copied from `.ai/project-context.md` → *Key Features* (the Datadog Synthetic tests fetched in Phase 2 Step 4b). Use the canonical schema — **Public ID** (link → `https://app.datadoghq.<region>/synthetics/details/<public_id>`) · **Type** (Browser/API) · **Name** (exact test name) · **Description** (factual, from the config) — sorted Browser first, API second, with a one-line note on the split (e.g. "5 browser tests + 2 API uptime tests"). Keep it in sync with `.ai/project-context.md`; do not invent columns or details. If Datadog access was unavailable at migration time, keep the section with a `[To fill in]` note — do not omit it.
8. In `Architecture & Package Map`, document each major app/package/feature/campaign and what it is responsible for. For monorepos or multi-brand/campaign projects, include all of the following:
   - an inventory table for quick scanning
   - a short summary paragraph or bullet for each major package/feature/campaign explaining purpose, ownership/context, and notable dependencies or integrations when known
   - a **Mermaid diagram** at the top of the page that gives a quick structural overview of how the project works
9. The Mermaid diagram must be a concise architecture overview, not an ASCII tree or screenshot-style code block. Prefer a simple `flowchart LR` or `flowchart TD` showing the main runtime path, major internal components, and key external systems/services.
   **Publish it with the Atlassian Labs "Mermaid Diagrams Viewer" app** (app key `com.atlassian.confluence.plugins.mermaid-diagrams-viewer`), which renders a code block on the page client-side and therefore works for pages written purely through the API. Never use the "Mermaid Chart for Confluence" macro: it caches a pre-rendered SVG in the macro config, so an API-written page shows a blank diagram until a human re-saves it in the editor. The ADF shape is a collapsed expand holding the source, immediately followed by the viewer macro:

   ```json
   {"type":"expand","attrs":{"title":"Diagram source"},"content":[
     {"type":"codeBlock","attrs":{"language":"ruby"},
      "content":[{"type":"text","text":"flowchart LR\n    Browser --> WebApp\n    WebApp --> DB[(Database)]"}]}]}
   {"type":"extension","attrs":{
     "layout":"default",
     "extensionType":"com.atlassian.ecosystem",
     "extensionKey":"23392b90-4271-4239-98ca-a3e96c663cbb/63d4d207-ac2f-4273-865c-0240d37f044a/static/mermaid-diagram",
     "text":"Mermaid diagram",
     "parameters":{
       "layout":"extension",
       "guestParams":{"index":0},
       "forgeEnvironment":"PRODUCTION",
       "extensionId":"ari:cloud:ecosystem::extension/23392b90-4271-4239-98ca-a3e96c663cbb/63d4d207-ac2f-4273-865c-0240d37f044a/static/mermaid-diagram",
       "extensionTitle":"Mermaid diagram"}}}
   ```

   Rules for it:
   - `guestParams` must be `{"index": N}`, with `N` the 0-based position of this source among **all** code blocks on the page, counted recursively so blocks inside expands count too. Two diagrams means index `0` and index `1`. Leaving it `""` ("Auto detect") produces *Error while loading diagram* on any API-written page, and is the single most common defect.
   - Keep the expand collapsed. The viewer still finds the code block inside it, so readers see the diagram with the source behind a toggle.
   - The code block `language` is cosmetic for this app. Do not tag it `mermaid`.
   - The source must be a verbatim copy of the `mermaid` block in `.ai/architecture.md`, which stays the single source of truth. Add one sentence under the diagram saying so, and telling the reader to change the repository file and re-sync rather than editing the diagram in Confluence.
   - The app id and environment id above are specific to the dept-nl site install. If the app was reinstalled or another site is targeted, read a live page's ADF back and copy the current `extensionKey` and `extensionId`.
   - After publishing, re-read the page with `npx -y confluence-axi page get <id> --format adf --full` and confirm the expand plus extension pair is present with the right `index`. Do not judge from the rendered page alone, and give it 10 to 20 seconds after load before calling a diagram broken.
   - If no Mermaid app is installed on the target site, keep the plain code block and record "request the Atlassian Labs Mermaid Diagrams Viewer app" as an open handover item rather than silently shipping an unrendered diagram.
10. If the repository has a `doc/` or `docs/` folder, use it as a primary input for Confluence wording, package/campaign descriptions, and onboarding context — but still verify against code/config when facts conflict.
11. In `Environments & Access`, include GitHub, test/acc/prod URLs, and Keeper reference.
12. In `Onboarding & Handover`, include setup steps, troubleshooting, escalation, and project-specific gotchas. Do **not** repeat the Key Contacts table here — it lives on the main `[Project Name]` landing page. Write the reading path for a person: point at the Overview and Architecture pages for orientation, never at `.ai/` files (see rule 6b).
13. Include all 5 links collected in Phase 2 Step 4.
14. Do NOT create a separate coding standards page unless explicitly requested.
15. **Record the page mapping.** After creating/finding the pages, write a `confluence:` block into `.ai/.meta.yml` using the schema in `docs/confluence-page-standard.md` — space, base URL, each page's **full prefixed** `title`, its real `id`, and the `sync_map`. This is what lets the Maintainer Agent sync the right pages without duplicating. If a page's ID cannot be captured, leave it empty; the Maintainer resolves it by the full title and backfills it on first run.

## Verification

Before proceeding to Phase 4, confirm:
- [ ] `AGENTS.md` exists, has no unfilled `[PLACEHOLDER]`, and routes into `.ai/` (Copilot, Codex, Cursor)
- [ ] `CLAUDE.md` contains the `@AGENTS.md` import (Claude Code)
- [ ] `AGENTS.md` carries at most five constraints, each of them class 3 by the `standards/writing-rules.md` §3 test
- [ ] Confluence pages created, or the completion summary says what blocked it
- [ ] No Confluence page instructs a human reader to read `.ai/` files (rule 6b; the landing page's AI tooling status entry and the diagram sync note are the only allowed mentions)
- [ ] `.ai/.meta.yml` has a `confluence:` block with page IDs + `sync_map`

## Completion Signal

```
✓ Phase 3 complete: AI tools wired and Confluence documentation created.
  Next: Run Phase 4 (04-stack-tooling.prompt.md) to install stack-specific tools.
```
