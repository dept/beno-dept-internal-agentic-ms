---
name: atlassian-axi
description: Use when creating, reading, updating, or deleting Confluence Cloud pages (and searching Jira/Confluence) from the terminal for DEPT MS handover — e.g. dept-nl.atlassian.net. Drives the `atlassian-axi` npm CLI via `npx` (agent-ergonomic Atlassian CLI: Jira via official acli, Confluence via the Cloud REST API). No custom script and no long-lived MCP needed. Covers auth, resolving handover pages by walking the landing page's children (never bare title search in the shared MS space), and the automatic version bump on updates.
---

# Atlassian AXI (Confluence handover)

Drive Confluence Cloud from the terminal with the **`atlassian-axi`** npm CLI, run via `npx` — no global install, no bespoke script. It wraps the Confluence Cloud REST API (and Jira via Atlassian's `acli`). `atlassian-axi` bumps page versions automatically (no manual 409 handling) and has a native `page children` command for the DEPT page-resolution rule.

## Preflight (always run first)

```bash
npx -y atlassian-axi confluence space list   # lists spaces if auth is good, errors otherwise
```

Errors → **stop** and walk the user through [references/setup.md](references/setup.md). Auth is either `atlassian-axi auth login` (browser OAuth) or the `ATLASSIAN_SITE`/`ATLASSIAN_EMAIL`/`ATLASSIAN_API_TOKEN` env vars (agents/CI). Never mint or type the token yourself — it is the user's secret.

## Two rules that prevent every common failure

1. **Resolve handover pages by walking the landing page's children — never a bare title search.** The `MS` space is shared across many client projects, so `search "title = 'Overview'"` resolves the wrong project's page. Get the landing page id from `.ai/.meta.yml` (`confluence.pages.landing.id`) and list its subtree:
   ```bash
   npx -y atlassian-axi confluence page children <landingId>
   ```
   Match the subpage by its full prefixed title (`<landing title> - <subpage>`). Act by the id you find.
2. **Updates bump the version automatically.** `page update <id> --body-file f` handles the version increment — no `409 Conflict`, no manual version math (unlike the old curl wrapper).

## Command reference

| Task | Command |
|---|---|
| Verify auth | `npx -y atlassian-axi confluence space list` |
| List a page's children (resolve subpages) | `npx -y atlassian-axi confluence page children <id>` |
| Read a page body (storage) | `npx -y atlassian-axi confluence page get <id> --full` |
| Create a child page | `npx -y atlassian-axi confluence page create --space MS --title "<full title>" --body-file body.html --parent <parentId>` |
| Update title and/or body | `npx -y atlassian-axi confluence page update <id> --title "<t>" --body-file body.html` |
| Delete | `npx -y atlassian-axi confluence page delete <id>` |
| Search (CQL, v1) | `npx -y atlassian-axi confluence search "space = MS AND type = page"` |

`page get`/`create`/`update` use **storage format** (Confluence XHTML) by default (`--format adf` for ADF). `page update` takes `--title`, `--body`/`--body-file`, or both (at least one required).

## Notes

- **Body is storage format**, not Markdown. Convert Markdown → storage before `create`/`update`. Mermaid goes in the diagram macro, tables as `<table>`.
- **DEPT handover sync:** page ids + full titles live in `.ai/.meta.yml` `confluence:`. Resolve by walking `landing.id`'s children (rule 1), act by id, write resolved ids back.
- **Jira** is available too (`atlassian-axi jira ...`) but DEPT MS handover only uses Confluence.

## Common mistakes

| Symptom | Cause / fix |
|---|---|
| Edited/created wrong project's page | Used bare title search in shared `MS` space. Walk `landing.id` children instead (rule 1). |
| Body renders as literal text/tags | Sent Markdown. Convert to storage format first. |
| `401`/`403` | Not authed, or `ATLASSIAN_SITE`/token mismatch. Re-run `atlassian-axi auth login` or fix env vars; see [references/setup.md](references/setup.md). |
| `update` dropped a macro | Body lost an embedded macro/whiteboard; re-add it, or pass `--allow-macro-loss` only if the loss is intended. |
