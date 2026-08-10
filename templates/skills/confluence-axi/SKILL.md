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

Reach for the MCP only when this CLI genuinely cannot complete the operation. In practice that is one case: a page-body update the CLI refuses because a full-body replace would drop an embedded macro you cannot faithfully reconstruct in storage format. When it happens:

1. Do that single write through the MCP.
2. Verify with `npx -y confluence-axi page get <id> --format storage --full`.
3. Note which page went through the MCP and why, so the exception stays visible.

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

`page get`/`create`/`update` use **storage format** (Confluence XHTML) by default (`--format adf` for ADF). `page update` takes `--title`, `--body`/`--body-file`, or both (at least one required). Bodies truncate on `page get` by default — pass `--full` to get the whole body.

## Notes

- **Body is storage format**, not Markdown. Markdown passed literally is stored as-is (not converted). Convert Markdown → storage before `create`/`update`. Mermaid goes in the diagram macro, tables as `<table>`.
- **Mermaid diagram macro** — never publish Mermaid as a fenced code block or `<pre>`; readers get source instead of a diagram. Use:

  ```html
  <ac:structured-macro ac:name="mermaid">
    <ac:parameter ac:name="diagramType">mermaid</ac:parameter>
    <ac:parameter ac:name="size">xl</ac:parameter>
    <ac:parameter ac:name="isEditable">true</ac:parameter>
    <ac:parameter ac:name="theme">default</ac:parameter>
    <ac:parameter ac:name="diagramCode">flowchart LR
      Browser --&gt; WebApp
      WebApp --&gt; DB[(Database)]</ac:parameter>
  </ac:structured-macro>
  ```

  `diagramCode` is XML content: escape `>` as `&gt;` and `&` as `&amp;`, and use real newlines. Verify after publishing with `page get <id> --format storage --full`; a code block coming back means the macro was rejected and nothing renders.
- **Output is TOON-encoded** (token-efficient) — there is no plain-text or JSON mode.
- **DEPT handover sync:** page ids + full titles live in `.ai/.meta.yml` `confluence:`. Resolve by walking `landing.id`'s children (rule 1), act by id, write resolved ids back.

## Common mistakes

| Symptom | Cause / fix |
|---|---|
| Edited/created wrong project's page | Used bare title search in shared `MS` space. Walk `landing.id` children instead (rule 1). |
| Body renders as literal text/tags | Sent Markdown. Convert to storage format first. |
| `401`/`403` | Not authed, or site/token mismatch. Re-run `confluence-axi auth login` or fix the API token; see [references/setup.md](references/setup.md). |
| `update` refused with VALIDATION_ERROR (macro loss) | Full-body replace dropped an embedded `<ac:structured-macro>` (whiteboard/diagram) the page still has. Re-fetch with `page get <id> --full`, carry the macro block into the new body, then update — or pass `--allow-macro-loss` only if the loss is intended. |
