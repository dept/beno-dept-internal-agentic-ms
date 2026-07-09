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

1. Read all `.ai/` files and `.ai/.meta.yml`
2. Record last maintenance date from `.meta.yml`
3. Identify `<!-- human-maintained -->` sections (untouchable)
4. Record current confidence scores

### Phase 2: Change Detection

1. Query git history since last maintenance:
   ```bash
   git log --since="$last_maintained" --name-only --pretty=format: | sort -u
   ```
2. Classify each changed file using `config/change-impact-matrix.yml`
3. Map changes to affected `.ai/` files with severity levels
4. Rank by priority: critical → moderate → minor

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
3. **Append** new information (never delete unless provably wrong)
4. **Low-confidence updates** go in `> ⚠️ Potential update:` blocks
5. **Cite sources** for every change: `<!-- Source: path/to/file:LINE -->`

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

Update `.ai/.meta.yml`:
- `last_maintained`: current timestamp
- `last_maintained_by`: agent identifier

## Conflict Resolution Rules

1. `<!-- human-maintained -->` sections are NEVER auto-updated
2. Files edited by humans since last maintenance → show diff, request review
3. Additions go at end of sections, not inline
4. When uncertain, append `## Updates (auto-generated)` section
5. Never remove content — add, update, or mark as potentially stale

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
- [ ] `.meta.yml` updated
- [ ] Change summary generated
