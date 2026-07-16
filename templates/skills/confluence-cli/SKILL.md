---
name: confluence-cli
description: Use when creating, reading, renaming/retitling, updating, moving, or deleting Confluence Cloud pages from the terminal (Atlassian wiki, e.g. dept-nl.atlassian.net). There is no dedicated Confluence binary and no Atlassian MCP here — you drive the REST API with curl+jq. Covers resolving a page by title, the mandatory version bump on updates (409 Conflict otherwise), and DEPT MS handover-page sync.
---

# Confluence CLI

Drive Confluence Cloud from the terminal via the REST API (`curl` + `jq`). There is **no bespoke binary and no Atlassian MCP** — the helper [confluence.sh](confluence.sh) wraps the v1 content API. `acli` does not manage Confluence pages; do not reach for it.

## Preflight (always run first)

```bash
bash confluence.sh me   # prints "auth OK ..." if configured, errors otherwise
```

Errors → **stop** and walk the user through [references/setup.md](references/setup.md). Never mint or type the token yourself — it is the user's secret; they export it.

## Two rules that prevent every common failure

1. **Resolve pages by title, never guess IDs.** `find` returns the real id. Acting on a guessed id edits the wrong page or 404s.
2. **Every update MUST bump `version.number` to current+1.** Confluence rejects a stale/missing version with **409 Conflict**. `confluence.sh title` and `setbody` fetch the current version and increment it for you — use them instead of hand-rolling `PUT`.

## Quick reference

| Task | Command |
|---|---|
| Verify auth | `bash confluence.sh me` |
| Find page (exact title in space) | `bash confluence.sh find MS "DEPT Client Portal - Overview"` |
| Get metadata (id, title, version) | `bash confluence.sh get <id>` |
| Read body (storage HTML) | `bash confluence.sh body <id> > page.html` |
| Create child page | `bash confluence.sh create MS <parentId> "<title>" body.html` |
| Rename / retitle | `bash confluence.sh title <id> "<new title>"` |
| Replace body | `bash confluence.sh setbody <id> body.html` |
| Delete | `bash confluence.sh rm <id>` |

## Notes

- **Body is storage format** (Confluence XHTML), not Markdown. Convert Markdown → storage before `create`/`setbody`. Mermaid goes in the Mermaid/diagram macro, tables as `<table>`.
- **Titles are unique per space.** In the shared `MS` space, follow the DEPT page-title convention (landing = project name; subpages prefixed `<landing title> - <subpage>`) so lookups stay unambiguous — see the standards repo's `docs/confluence-page-standard.md`.
- **DEPT handover sync:** page ids + full titles live in `.ai/.meta.yml` `confluence:`. Resolve by the stored title, act by id, write resolved ids back.

## Common mistakes

| Symptom | Cause / fix |
|---|---|
| `409 Conflict` on update | Missing/stale `version.number`. Use `title`/`setbody` (they bump it). |
| Edited/created wrong page | Guessed the id. Always `find` by title first. |
| Body renders as literal text/tags | Sent Markdown. Convert to storage format first. |
| `401`/`403` | Bad token, wrong `CONFLUENCE_SITE`, or no space permission. Re-run `me`. |
| Two pages, same name | Title collision in the shared space. Apply the DEPT title convention. |
