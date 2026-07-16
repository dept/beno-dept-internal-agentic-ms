# Agentic Project Standard

## Why Projects Should Be AI-Ready

Managed Services requires continuity across engineers, squads, and time zones. AI assistance only works safely when project context is complete, current, and structured. AI-ready projects reduce onboarding time, improve incident response, and increase delivery consistency.

## Purpose of the `.ai` Folder

The `.ai` folder is the canonical machine-readable project context package. It complements (not replaces) human documentation by giving AI agents a reliable operating baseline.

Core outcomes:
- predictable AI outputs;
- lower hallucination risk;
- faster root-cause analysis;
- consistent change planning and validation.

## Required Files

Every AI-ready project must maintain:
- `project-context.md`
- `architecture.md`
- `runbooks.md`
- `dependencies.md`
- `cms.md`
- `operational-context.md`
- `coding-standards.md`
- `agent-registry.md`
- `onboarding.md`

## Documentation Standards

1. **Structured headings**: stable section names for machine parsing.
2. **Source traceability**: link each critical statement to code, config, or platform evidence.
3. **Assumption marking**: clearly tag inferred information.
4. **Confidence scoring**: rate reliability of each major section.
5. **Validation questions**: include unresolved questions blocking high confidence.

## Update Cadence and Agent Support

Two agents support the `.ai` lifecycle:

- **Discovery Agent** (`agents/discovery.agent.md`): generates the complete `.ai` folder for a new or previously undocumented project.
- **Maintainer Agent** (`agents/maintainer.agent.md`): keeps `.ai` files current as the project evolves. Run after each sprint, release, infrastructure change, or incident postmortem.

Manual review of `.ai` files remains mandatory before merging changes. Agents produce drafts; human engineers validate and approve.

## Multi-Client Support

`.ai/` is the **single shared source of truth** — the one folder every AI client reads. No IDE reads another's config folder, so the standard writes a thin *pointer* file per client (each redirects into `.ai/`) rather than duplicating context. The supported clients and where each artifact lives:

| Artifact | GitHub Copilot | Claude Code | OpenAI Codex | Cursor |
|---|---|---|---|---|
| Context (source of truth) | `.ai/` | `.ai/` | `.ai/` | `.ai/` |
| Context wiring (pointer) | `.github/copilot-instructions.md`, `.github/instructions/` | `CLAUDE.md` | `AGENTS.md` | `.cursor/rules/ai-context.mdc` (+ `AGENTS.md`) |
| Agents / subagents | `.github/agents/` | `.claude/agents/` | — (no concept) | — (no concept) |
| Skills | `.github/skills/` | `.claude/skills/` | — (no concept) | — (no concept) |
| Slash commands / prompts | `.github/prompts/` | `.claude/commands/` | reads `AGENTS.md` / prompt file | `.cursor/commands/` |
| MCP servers | `.vscode/mcp.json` (`servers`) | `.mcp.json` (`mcpServers`) | user-level `~/.codex/config.toml` | `.cursor/mcp.json` (`mcpServers`) |

Rules: `.github/*` is the source of truth for agents/skills/prompts (Copilot's native home); the `.claude/*` and `.cursor/*` copies are exact mirrors, re-copied on change and never hand-edited. `AGENTS.md` is the nearest-to-universal pointer (Codex, Cursor, and Copilot's coding agent all honor it). Codex has no project-level agent/skill/command folders and its MCP config is user-level, so it is wired via `AGENTS.md` only.

## Governance Principles

- **Ownership**: each `.ai` document has a named owner (team, not individual).
- **Review**: `.ai` updates follow normal PR review policy.
- **Security**: no secrets, tokens, or privileged data in `.ai` documents.
- **Auditability**: changes are versioned and explainable.
- **Operational fit**: documents must support run, support, and change workflows.
- **Accessibility**: front-end changes target **WCAG 2.2 Level AA** as the DEPT baseline. Agents must respect a project's documented level (in `coding-standards.md`), avoid introducing regressions, and flag accessibility risks in proposed changes.

## Long-Term Vision

The standard enables a shared DEPT-wide delivery model where AI agents can:
- onboard into any managed services project quickly;
- propose safer code and infrastructure changes;
- support operations with context-aware recommendations;
- scale institutional knowledge without sacrificing governance.
