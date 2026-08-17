# Maintainer Agent — Tool-Agnostic Logic

> This file defines the Maintainer Agent's workflow independently of any specific AI tool.
> Tool-specific wrappers (Copilot, Claude, Hermes) reference this logic.

## Purpose

Keep the `.ai/` folder accurate and current as the project evolves. Detect drift between documentation and codebase, apply targeted updates, and respect human edits.

## Input Requirements

- Access to the full repository filesystem
- Git history access (`git log`)
- Access to `config/change-impact-matrix.yml` from the standards repo
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

1. Query git history since last maintenance, then read DIFFS (not full files):
   ```bash
   git log --since="$last_maintained" --name-only --pretty=format: | sort -u
   git diff "@{$last_maintained}" -- <changed-paths>   # diff-first; full read only if diff insufficient
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
3. **Add** new information to the section that owns the topic. Delete only in the three cases in `standards/writing-rules.md` §5: it breaks a writing rule, repository evidence contradicts it, or a human asked. Never delete a fact just because you did not write it
4. **Low-confidence updates** go in `> ⚠️ Potential update:` blocks
5. **Cite sources** in the Phase 6 PR summary (date + `path/to/file:LINE`) — NOT as inline `<!-- ... -->` comments, which rot the files. Git blame + the PR are the audit trail.
6. **Regenerate** `.agents/skills/codebase-overview/SKILL.md` (and its `.claude/skills/` mirror) when the structural sections of `.ai/architecture.md` changed

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

- Resolve empty page `id`s by title under the space; write resolved IDs back to `.meta.yml` (prevents duplicates)
- Route each changed `.ai/` file to its `sync_map` page; `agent-registry.md` → landing page `## AI tooling status`
- Push critical/moderate updates only; skip minor (reduce noise)
- Update in place — never delete a page/section unless its subject no longer exists in the repo
- Add "Last synced from .ai/ — [timestamp]" to each touched page

### Phase 8: Metadata Update

Update `.ai/.meta.yml` — **only when Phase 4/5 changed real documentation content**:
- `last_maintained`: current timestamp
- `last_maintained_by`: agent identifier

**No-op rule:** if `git status --porcelain -- .ai/` shows only `.meta.yml`, or the diff is limited to
bookkeeping fields (`last_maintained`, `last_maintained_by`, `last_checked`, resolved Confluence page
`id`s, version stamps), revert the working tree (`git checkout -- .ai/`), commit nothing, open no PR,
and report "no content drift". A timestamp is never a reason for a PR. Likewise, skip a Confluence
page whose only delta would be the "Last synced" line.

## Conflict Resolution Rules

1. `<!-- human-maintained -->` sections are NEVER auto-updated
2. Files edited by humans since last maintenance → show diff, request review
3. Additions go into the section that owns the topic. Never open an `## Updates` or `## Changes` section: `standards/writing-rules.md` bans it
4. When uncertain about a fact, keep it and mark it as unverified rather than removing it
5. Remove content only in the three cases in `standards/writing-rules.md` §5: it breaks a writing rule, repository evidence contradicts it, or a human asked

## Escalation Levels

| Severity | Action |
|----------|--------|
| Critical | Create PR, assign CODEOWNERS, require human review |
| Moderate | Create PR, auto-merge after 48h if no objections |
| Minor | Batch into weekly maintenance PR |

## Quality Gates

- [ ] All critical findings resolved or escalated
- [ ] No secrets in any `.ai/` file
- [ ] Confidence scores updated
- [ ] Human-maintained sections untouched
- [ ] `.meta.yml` updated (only alongside real content changes)
- [ ] No PR opened for a bookkeeping-only diff
- [ ] Touched `.ai/` files pass `standards/writing-rules.md`
- [ ] `codebase-overview` skill regenerated if `.ai/architecture.md` structure changed
- [ ] Change summary generated
