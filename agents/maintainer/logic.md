# Maintainer Agent — Tool-Agnostic Logic

> This file defines the Maintainer Agent's workflow independently of any specific AI tool.
> Tool-specific wrappers (Copilot, Claude, Hermes) reference this logic.

## Purpose

Keep the `.ai/` folder accurate and current as the project evolves. Detect drift between documentation and codebase, apply targeted updates, and respect human edits.

## Input Requirements

- Access to the full repository filesystem
- Git history access (`git log`)
- Access to `config/change-impact-matrix.yml` (vendored into the repository by the installer)
- Optionally: Confluence access (for sync)

## When to Trigger

- After each sprint (scheduled)
- After a release
- After infrastructure changes
- After an incident
- On PR merge to main (CI trigger, critical changes only)
- On demand

## Workflow (8 Phases)

### Phase 1: Baseline Read

1. Read `.ai/.meta.yml` first — do NOT read every `.ai/` file upfront; read only the impacted ones after Phase 2
2. Record last maintenance date from `.meta.yml`
3. Identify `<!-- human-maintained -->` sections (untouchable) in impacted files
4. Record current confidence scores for impacted sections

### Phase 2: Change Detection

1. Parse `last_maintained` as the scalar value, not the raw YAML line (`grep 'last_maintained' .ai/.meta.yml` alone captures `last_maintained: "..."`, which is not a valid `--since` argument). If it's unset or `null` (first run), there is no baseline — treat every change-impact-matrix area as in scope instead of diffing "since" nothing. Otherwise query git history since that timestamp, then read DIFFS (not full files):
   ```bash
   git log --since="$last_maintained" --name-only --pretty=format: | sort -u
   git diff "$(git rev-list -1 --before="$last_maintained" HEAD)" -- <changed-paths>   # diff-first; full read only if diff insufficient. Not "@{date}": reflog syntax, empty in a fresh CI checkout
   ```
2. Classify each changed file using `config/change-impact-matrix.yml`
3. Map changes to affected `.ai/` files with severity levels
4. Rank by priority: critical → moderate → minor
5. **Early exit (cost control):** if no change maps to a documented area, report "no drift" and stop — skip Phases 3–8. Only read the `.ai/` files actually impacted, not all of them.

### Phase 3: Staleness Assessment

For each `.ai/` file, check:
- References to files/directories that no longer exist
- Dependency versions that don't match lockfiles
- Architecture mentions of removed services
- Runbook procedures referencing deprecated tools
- Significant git activity in documented areas

Assign staleness level: Critical / Moderate / Minor / Current

### Phase 4: Targeted Updates

Apply changes with conflict resolution:
1. **Skip** sections marked `<!-- human-maintained -->`
2. **Diff-review** files manually edited since last maintenance
3. **Add** new information to the section that owns the topic, found in `standards/writing-rules.md` §4b. Everywhere else the same fact is mentioned, write a one-line pointer, never a second copy. Delete only in the three cases in `standards/writing-rules.md` §5: it breaks a writing rule, repository evidence contradicts it, or a human asked. Never delete a fact just because you did not write it
4. **Low-confidence updates** go in `> ⚠️ Potential update:` blocks
5. **Cite sources** in the Phase 6 PR summary (date + `path/to/file:LINE`) — NOT as inline `<!-- ... -->` comments, which rot the files. Git blame + the PR are the audit trail.
6. **Regenerate** `.agents/skills/codebase-overview/SKILL.md` when the structural sections of `.ai/architecture.md` changed (no mirror to update, `.claude/skills` symlinks to the source)

### Phase 5: Gap Detection

Identify undocumented additions:
- New services/packages with no architecture entry
- New dependencies with no risk assessment
- New environment variables with no documentation
- New CI/CD stages with no operational context

Add with `Confidence: 0% — needs team input` marker.

### Phase 6: Change Summary

Generate structured summary with:
- Changes applied (file, section, type, severity, source)
- Skipped sections (human-maintained)
- Items needing human review
- Confidence score changes

### Phase 7: Confluence Sync

Read the `confluence:` block from `.ai/.meta.yml` (schema + `.ai/`→page mapping in `docs/confluence-page-standard.md`).

- Resolve empty page `id`s by walking `confluence.pages.landing.id`'s children and matching the exact full title — never a bare title search across the shared space, which can select another project's similarly named page; write resolved IDs back to `.meta.yml` (prevents duplicates)
- Route each changed `.ai/` file to its `sync_map` page, transformed into that page's storage/ADF format per the layout rule below — never the raw agent-facing Markdown (ownership header, agent pointers, confidence notes) pasted verbatim; `agent-registry.md` → landing page `## AI tooling status`
- Push critical/moderate updates only; skip minor (reduce noise)
- Update in place — never delete a page/section unless its subject no longer exists in the repo
- Add "Last synced from .ai/ — [timestamp]" to each touched page
- Render every section per `docs/confluence-layout.md` (block choice, canonical table columns, `H2` sections); bring an older-shaped section to the standard shape while updating it
- The architecture page's Mermaid diagram is a special case: follow `docs/confluence-page-standard.md`'s Mermaid section exactly, not the general routing above. It needs an MCP speaking the Atlassian HTML content format — a session-level capability, distinct from (and not assumed equivalent to) whatever community Atlassian MCP the CI environment wires. If unreachable, keep the plain code block and record it as an open item per that section, rather than attempting the extension write

### Phase 8: Metadata Update

Update `.ai/.meta.yml` — **only when Phase 4/5 changed real documentation content**. Both keys
already exist under the top-level `meta:` mapping and are updated in place; written at the YAML root
instead they leave `meta.last_maintained` at `null`, which makes Phase 2 treat every run as a first
run and rescan the whole history:
- `meta.last_maintained`: current timestamp
- `meta.last_maintained_by`: agent identifier

**No-op rule:** if `git status --porcelain -- .ai/` shows only `.meta.yml`, or the diff is limited to
bookkeeping fields (`last_maintained`, `last_maintained_by`, `last_checked`, resolved Confluence page
`id`s, version stamps), revert the working tree (`git checkout -- .ai/`), commit nothing, open no PR,
and report "no content drift". A timestamp is never a reason for a PR. Likewise, skip a Confluence
page whose only delta would be the "Last synced" line.

## Conflict Resolution Rules

1. `<!-- human-maintained -->` sections are NEVER auto-updated
2. Files edited by humans since last maintenance → show diff, request review
3. Additions go into the section that owns the topic (`standards/writing-rules.md` §4b), and the `context-ownership` skill is the procedure for finding it. Never open an `## Updates` or `## Changes` section: `standards/writing-rules.md` bans it
4. When uncertain about a fact, keep it and mark it as unverified rather than removing it
5. Remove content only in the three cases in `standards/writing-rules.md` §5: it breaks a writing rule, repository evidence contradicts it, or a human asked

## Escalation Levels

Opening a pull request is the only action available: the harness grants `gh pr create`, `gh pr view`
and `gh pr list` and nothing that can assign a reviewer or merge, and the target repository may have
no `CODEOWNERS` file. Severity therefore changes what the PR *says*, not what happens to it — a human
merges every one. This table and `config/change-impact-matrix.yml` → `escalation` state one rule; a
change to either lands in both.

| Severity | Action |
|----------|--------|
| Critical | Open a PR whose title names the drift, and state in the body that it needs human review before merge |
| Moderate | Open a PR describing the change and leave it for a human to merge; there is no auto-merge |
| Minor | Batch into the next scheduled maintenance PR |

## Quality Gates

- [ ] All critical findings resolved or escalated
- [ ] No secrets in any `.ai/` file
- [ ] Confidence scores updated
- [ ] Human-maintained sections untouched
- [ ] `.meta.yml` updated (only alongside real content changes)
- [ ] No PR opened for a bookkeeping-only diff
- [ ] Touched `.ai/` files pass `standards/writing-rules.md`, every added fact sits in its owning file, and `bash scripts/validate.sh .` reports no Single-Source Integrity failure this run introduced
- [ ] `codebase-overview` skill regenerated if `.ai/architecture.md` structure changed
- [ ] Change summary generated
