# Success Metrics & Feedback Loop

> How we measure whether the Agentic Project Standard is delivering value.

## Why Measure

Phase 3 (Scale) rolls the standard across multiple Managed Services projects. Without metrics, we can't tell if it's helping or creating overhead. This document defines what to track, how to collect it, and what actions to take.

## Leading Indicators (Track Weekly)

| Metric | How to Measure | Target | Action if Off-Track |
|--------|---------------|--------|--------------------|
| Projects migrated | Count of repos with `.ai/` folder | +2/sprint | Review blockers, simplify scaffold |
| Scaffold success rate | `validate.sh` pass rate on fresh migrations | >90% | Fix templates or Discovery Agent |
| Time to migrate | Clock from prompt start to validation pass | <30 min | Automate more steps, reduce LLM dependency |
| Developer adoption | % of AI-assisted PRs in migrated projects | >40% within 30d | Improve onboarding, add examples |

## Lagging Indicators (Track Monthly)

| Metric | How to Measure | Target | Action if Off-Track |
|--------|---------------|--------|--------------------|
| .ai/ staleness | % of files not updated in >30 days | <20% | Automate Maintainer Agent triggers |
| Maintainer signal-to-noise | % of Maintainer Agent diffs accepted by team | >70% | Refine change impact matrix |
| Incident MTTR | Mean time to resolve on migrated vs non-migrated | 20% improvement | Improve runbooks template |
| Onboarding time | New engineer productive time (self-reported) | 50% faster | Enrich onboarding.md template |
| Developer NPS on AI tooling | Quarterly survey (1-10 scale) | >7 | Iterate on pain points |

## Collection Methods

### Automated (Preferred)

- **Validation results**: Run `scripts/validate.sh` in CI on every PR that touches `.ai/`. Store results.
- **Staleness**: Cron job that runs `validate.sh` across all migrated repos weekly.
- **Migration count**: GitHub search for repos containing `.ai/project-context.md`.

### Manual (Quarterly)

- **Developer survey**: 5-question form on AI tooling usefulness.
- **Incident review**: Compare MTTR for incidents on migrated vs non-migrated projects.
- **Maintainer review**: Sample 10 Maintainer Agent PRs — count accepted vs rejected.

## Feedback Loop Process

```
1. Collect metrics (automated weekly, manual quarterly)
2. Review in MS team retrospective
3. Identify top 2 improvement areas
4. Create issues in dept-agentic-standards repo
5. Implement fixes in next sprint
6. Re-measure
```

## Red Flags (Immediate Action)

- **Scaffold success rate drops below 70%**: Freeze migrations, fix root cause.
- **>50% of .ai/ files stale after 30 days**: Maintainer Agent isn't running or isn't useful.
- **Developer NPS below 5**: Fundamental UX problem — interview developers.
- **Maintainer Agent generates >30% noise diffs**: Tighten change impact matrix.

## Dashboard

When at scale (>10 projects), consider a simple dashboard:

```
┌──────────────────────────────────────────┐
│  DEPT Agentic Standards — Health Board   │
├──────────────────────────────────────────┤
│  Projects Migrated:     12 / 18         │
│  Compliant:             10 (83%)        │
│  Stale (>30d):          2 (17%)         │
│  Avg Migration Time:    22 min          │
│  Developer NPS:         7.4             │
│  Maintenance Accept Rate: 78%            │
└──────────────────────────────────────────┘
```

This can be a simple script that queries GitHub and outputs to Slack.
