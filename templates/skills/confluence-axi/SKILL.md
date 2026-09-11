---
name: confluence-axi
description: Use when creating, reading, updating, or deleting Confluence Cloud pages (and searching Confluence via CQL) from the terminal for DEPT MS handover — e.g. dept-nl.atlassian.net. Drives the `confluence-axi` npm CLI via `npx` (agent-ergonomic Confluence Cloud CLI over the REST API directly). No custom script and no long-lived MCP needed. Covers auth, resolving handover pages by walking the landing page's children (never bare title search in the shared MS space), and the idempotent version bump on updates.
---

# Confluence AXI (Confluence handover)

Drive Confluence Cloud from the terminal with the **`confluence-axi`** npm CLI, run via `npx` — no global install, no bespoke script. It calls the Confluence Cloud REST API directly (Node >= 20, no `acli` dependency). Updates are idempotent and bump the page version automatically (no manual 409 handling), and there's a native `page children` command for the DEPT page-resolution rule.

> `confluence-axi` is the Confluence-only successor to the now-sunset `atlassian-axi`. Jira lives in the separate `jira-axi` package; DEPT MS handover only uses Confluence.

## Preflight (always run first)

```bash
npx -y confluence-axi space list   # lists spaces if auth is good, errors otherwise
```

Errors → **ask the user to log in.** The preferred path is browser OAuth (`npx -y confluence-axi auth login`), which the user runs in their own terminal; it needs their own registered 3LO app, set up once per [references/setup.md](references/setup.md). The API-token path is the fallback for CI and headless runs. Never mint, type, echo, or store the token yourself — it is the user's secret.

**If the user cannot or will not log in right now and the remote Atlassian MCP *is* reachable, proceed on the MCP alone** rather than blocking the run — but say so up front, once, in these terms:

> ⚠️ `confluence-axi` is not authenticated, so all Confluence work is going through the Atlassian MCP. That reads whole page bodies instead of compact truncated output, so this run will use noticeably more tokens. Logging in with `confluence-axi auth login` avoids it.

Say it once at the point you fall back, not per page. This fallback covers a missing login only; everything below about *which* tool to prefer still applies whenever the CLI is authenticated.

## Hybrid rule: this CLI first, Atlassian MCP only when it cannot do the job

Use `confluence-axi` for **every** Confluence operation by default — search, page resolution, reads, create, update, and post-write verification. Reads are the bulk of the token cost on a handover run and this CLI returns compact output that truncates unless you pass `--full`, so sending reads through the remote Atlassian MCP burns tokens for nothing.

Reach for the MCP only when this CLI genuinely cannot complete the operation. In practice that is two cases:

1. **A page-body update the CLI refuses** because a full-body replace would drop an embedded macro you cannot faithfully reconstruct in storage format. Do that single write through the MCP, verify with `npx -y confluence-axi page get <id> --format storage --full`, and note which page went through the MCP and why.
2. **Any Mermaid-diagram write** (the architecture page's viewer extension) — `create`/`update` are storage-format only in this CLI and have no path to ADF-only content at all; see *Mermaid diagrams* below for the exact procedure and why raw storage-format `ac:adf-extension` XML doesn't work either. Verify with `npx -y confluence-axi page get <id> --format adf --full` (ADF, not storage — see below for why storage-format verification is actively misleading here), and note the page went through the MCP for this reason.

Either way, note which page went through the MCP and why, so the exception stays visible.

The one other time the MCP takes over is the unauthenticated fallback in Preflight above — allowed, but announced with the token warning, never silent.

## Two rules that prevent every common failure

1. **Resolve handover pages by walking the landing page's children — never a bare title search.** The `MS` space is shared across many client projects, so `search "title = 'Overview'"` resolves the wrong project's page. Get the landing page id from `.ai/.meta.yml` (`confluence.pages.landing.id`) and list its subtree:
   ```bash
   npx -y confluence-axi page children <landingId>
   ```
   Match the subpage by its full prefixed title (`<landing title> - <subpage>`). Act by the id you find.
2. **Updates bump the version automatically and idempotently.** `page update <id> --body-file f` handles the version increment — no `409 Conflict`, no manual version math. A no-op mutation reports "Already ..." and re-fetches the post-state, so re-running a failed mutation is safe.

## Command reference

Flags come **after** the command.

| Task | Command |
|---|---|
| Verify auth | `npx -y confluence-axi space list` |
| List a page's children (resolve subpages) | `npx -y confluence-axi page children <id>` |
| Read a page body (storage) | `npx -y confluence-axi page get <id> --full` |
| Create a child page | `npx -y confluence-axi page create --space MS --title "<full title>" --body-file body.html --parent <parentId>` |
| Update title and/or body | `npx -y confluence-axi page update <id> --title "<t>" --body-file body.html` |
| Delete | `npx -y confluence-axi page delete <id>` |
| Search (CQL) | `npx -y confluence-axi search "space = MS AND type = page"` |

`page get` supports both **storage format** (Confluence XHTML, default) and `--format adf`. **`create`/`update` are storage-format only** — as of `confluence-axi` 1.0.4 (the latest published version) neither has a `--format` flag at all, so the CLI cannot write ADF-only content. `page update` takes `--title`, `--body`/`--body-file`, or both (at least one required). Bodies truncate on `page get` by default — pass `--full` to get the whole body.

## Notes

- **Body is storage format**, not Markdown. Markdown passed literally is stored as-is (not converted). Convert Markdown → storage before `create`/`update`. Tables go in as `<table>`. Mermaid needs ADF — this CLI cannot write it, see below.
- **Mermaid diagrams — this is the one operation this CLI cannot do; use an MCP with the Atlassian HTML content format instead.** Publish with the Atlassian Labs **Mermaid Diagrams Viewer** app, which renders a code block on the page at view time. Never use the "Mermaid Chart for Confluence" macro (`ac:name="mermaid"`): it caches a pre-rendered SVG in its config, which an API write cannot produce, so the diagram stays blank until a human re-saves it in the editor.

  `confluence-axi create`/`update` genuinely cannot write this: the extension is an ADF-only node with no storage-format macro, and raw `<ac:adf-extension>`/`<ac:adf-parameter>` XML — the storage-format escape hatch for ADF-only content — silently **flattens or kebab-cases every nested parameter key** on the way through (`guestParams` → `guestparams` or `guest-params`, confirmed both ways in practice). The Mermaid app reads `parameters.guestParams.index` case-sensitively, so a mangled key produces *Error while loading diagram* even though the write "succeeded". This is the sanctioned exception in the Hybrid rule above (the CLI cannot complete the operation): do this one write through an MCP that supports the Atlassian **HTML content format** (`@atlassian/atlassian-html-format` — e.g. the `getContentFormatGuide`/`updateConfluencePage` tools on a first-party Atlassian/Rovo connector, if the current session has one configured; this is a different, session-level capability from the community `atlassian`/`mcp-atlassian` server Phase 4 wires into the target repo's own `.mcp.json`, whose ADF-write fidelity for extensions is unverified — don't assume it behaves the same). That format takes a single JSON-encoded `data-parameters` attribute (not decomposed XML attributes), which preserves key casing because it's parsed as JSON, not walked as a nested element tree:

  ```html
  <details><summary>Diagram source</summary><pre><code class="language-text">flowchart LR
      Browser --&gt; WebApp
      WebApp --&gt; DB[(Database)]</code></pre></details>
  <div data-type="extension"
       data-extension-key="23392b90-4271-4239-98ca-a3e96c663cbb/63d4d207-ac2f-4273-865c-0240d37f044a/static/mermaid-diagram"
       data-extension-type="com.atlassian.ecosystem"
       data-layout="default"
       data-parameters='{"layout":"extension","guestParams":{"index":0},"forgeEnvironment":"PRODUCTION","extensionId":"ari:cloud:ecosystem::extension/23392b90-4271-4239-98ca-a3e96c663cbb/63d4d207-ac2f-4273-865c-0240d37f044a/static/mermaid-diagram","extensionTitle":"Mermaid diagram"}'>Mermaid diagram</div>
  ```

  The `<details>` (a native HTML5 expand, collapsed by default — do not add `open`) converts to a real ADF `expand` node holding a real `codeBlock`, not a wrapped/opaque one; only the extension itself needs the `data-type="extension"` treatment.

  `guestParams` must be `{"index": N}`, with `N` the 0-based position of the source among **all** code blocks on the page, counted recursively so blocks nested inside expands count too. `""` ("Auto detect") gives *Error while loading diagram* on API-written pages. The code block `language` is cosmetic; do not tag it `mermaid`. The ids above are specific to the dept-nl install: if the app is reinstalled or another site is targeted, read a live page's ADF and copy the current ones.

  **Verify by reading true ADF back, never the storage-format echo.** `npx -y confluence-axi page get <id> --format adf --full` (or the MCP's own ADF read) reflects what actually renders and must show `"type":"extension"` with camelCase `guestParams`/`forgeEnvironment`/`extensionId`/`extensionTitle` intact and `guestParams.index` as a **number**. `npx -y confluence-axi page get <id> --full` (storage format, the default) is **not a valid check here** — Confluence's storage-format serialization of an `ac:adf-extension` kebab-cases or flattens the same keys for display even when the underlying stored ADF is correct, so it will look broken when it isn't (and vice versa, cannot prove correctness). The rendered diagram itself takes 10 to 20 seconds to appear after page load — wait that long before calling it broken.
- **Output is TOON-encoded** (token-efficient) — there is no plain-text or JSON mode.
- **DEPT handover sync:** page ids + full titles live in `.ai/.meta.yml` `confluence:`. Resolve by walking `landing.id`'s children (rule 1), act by id, write resolved ids back.

## Common mistakes

| Symptom | Cause / fix |
|---|---|
| Edited/created wrong project's page | Used bare title search in shared `MS` space. Walk `landing.id` children instead (rule 1). |
| Body renders as literal text/tags | Sent Markdown. Convert to storage format first. |
| `401`/`403` | Not authed, or site/token mismatch. Re-run `confluence-axi auth login` or fix the API token; see [references/setup.md](references/setup.md). |
| `update` refused with VALIDATION_ERROR (macro loss) | Full-body replace dropped an embedded `<ac:structured-macro>` (whiteboard/diagram) the page still has. Re-fetch with `page get <id> --full`, carry the macro block into the new body, then update — or pass `--allow-macro-loss` only if the loss is intended. |
