# [PROJECT_NAME]

[PROJECT_SUMMARY]

<!-- Two sentences from .ai/project-context.md: what the system is and who it serves. This is the
only .ai/ content restated here. Keep it a summary, never a copy. -->

This is the one authored instruction file in this repository. Every harness reads it: Claude Code
through the `@AGENTS.md` import in `CLAUDE.md`, Copilot on GitHub and in VS Code as agent
instructions, Codex and Cursor natively. There is no second copy to keep in sync.

## Setup

[SETUP_COMMANDS]

## Project context

Do not load `.ai/` files up front. Read one when the task touches its area:

| File | Read it for |
|------|-------------|
| `.ai/architecture.md` | Repository layout, technology stack, service boundaries, which shared helper to reuse, where a new file goes |
| `.ai/project-context.md` | What the system is for, business capabilities, key features, team ownership |
| `.ai/coding-standards.md` | Any code change: the commands to run, the conventions this project expects |
| `.ai/dependencies.md` | Dependency, upgrade, or security questions |
| `.ai/operational-context.md` | Environments, deployment, monitoring, SLOs |
| `.ai/runbooks.md` | Incidents, recovery, on-call procedures |
| `.ai/cms.md` | Content models, publishing, preview, cache invalidation |
| `.ai/onboarding.md` | Local setup, and every URL and access link in the project |
| `.ai/agent-registry.md` | Which agents, skills and MCP servers are configured here |

Skills live in `.agents/skills/`, mirrored to `.claude/skills/` for Claude Code. Agents and prompts
live in `.github/agents/` and `.github/prompts/`. For sustained development or support work, use the
Support Agent in `.github/agents/`: it loads project context automatically.

## Behaviour rules

1. Only infer facts from source code, config files, and CI/CD.
2. Never invent service names, endpoints, team members, or environment details.
3. If something is not found, say: `Unknown: not found in repository`.
4. Use bullet points and tables. Avoid filler language.

## Key constraints

[KEY_CONSTRAINTS_ONE_LINERS]

<!-- At most five, and only rules an agent could not recover from a tool error: a required import
path, a wrapper it must use instead of a standard API, a generation step that must run after a
schema change. Nothing a formatter fixes, nothing a type error already explains. The test is in
standards/writing-rules.md section 3. Everything else stays in .ai/coding-standards.md. -->

## When context is stale

`.ai/` reflects the project as of its last maintenance run. If it contradicts the code, the code
wins: say so and recommend running the Maintainer Agent. Do not work around the contradiction
silently, and do not record it in `.ai/`.
