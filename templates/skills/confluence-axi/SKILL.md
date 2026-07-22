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

Errors → **stop** and walk the user through [references/setup.md](references/setup.md). Auth is either `confluence-axi auth login` (browser OAuth — needs your own registered 3LO app) or the API-token path (agents/CI). Never mint or type the token yourself — it is the user's secret.

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
- **Output is TOON-encoded** (token-efficient) — there is no plain-text or JSON mode.
- **DEPT handover sync:** page ids + full titles live in `.ai/.meta.yml` `confluence:`. Resolve by walking `landing.id`'s children (rule 1), act by id, write resolved ids back.

## Common mistakes

| Symptom | Cause / fix |
|---|---|
| Edited/created wrong project's page | Used bare title search in shared `MS` space. Walk `landing.id` children instead (rule 1). |
| Body renders as literal text/tags | Sent Markdown. Convert to storage format first. |
| `401`/`403` | Not authed, or site/token mismatch. Re-run `confluence-axi auth login` or fix the API token; see [references/setup.md](references/setup.md). |
| `update` refused with VALIDATION_ERROR (macro loss) | Full-body replace dropped an embedded `<ac:structured-macro>` (whiteboard/diagram) the page still has. Re-fetch with `page get <id> --full`, carry the macro block into the new body, then update — or pass `--allow-macro-loss` only if the loss is intended. |
