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

`standards/writing-rules.md` is the single home for the rules that decide what may be written into
these files: what never goes in, which file owns which topic, which tool-enforced rules are worth
recording at all, and when an agent may delete existing content. It is installed into every
migrated repository and referenced from every agent, prompt and template. It is never restated.

## Update Cadence and Agent Support

Two agents support the `.ai` lifecycle:

- **Discovery Agent** (`agents/discovery.agent.md`): generates the complete `.ai` folder for a new or previously undocumented project.
- **Maintainer Agent** (`agents/maintainer.agent.md`): keeps `.ai` files current as the project evolves. Run after each sprint, release, infrastructure change, or incident postmortem.

Manual review of `.ai` files remains mandatory before merging changes. Agents produce drafts; human engineers validate and approve.

## Multi-Client Support

`.ai/` is the **single shared source of truth**: the one folder every AI client reads. The standard writes one authored wiring file, `AGENTS.md`, which every harness in use reads, and one import of it for Claude Code. The supported clients and where each artifact lives:

| Artifact | GitHub Copilot | Claude Code | OpenAI Codex | Cursor |
|---|---|---|---|---|
| Context (source of truth) | `.ai/` | `.ai/` | `.ai/` | `.ai/` |
| Context wiring | `AGENTS.md` | `CLAUDE.md`, which is `@AGENTS.md` | `AGENTS.md` | `AGENTS.md` |
| Agents / subagents | `.github/agents/` | `.claude/agents/` | no concept | no concept |
| Skills | `.agents/skills/` | `.claude/skills/` | `.agents/skills/` | `.agents/skills/` |
| Slash commands / prompts | `.github/prompts/` | `.claude/commands/` | reads `AGENTS.md` / prompt file | `.cursor/commands/` |
| MCP servers | `.vscode/mcp.json` (`servers`) | `.mcp.json` (`mcpServers`) | user-level `~/.codex/config.toml` | `.cursor/mcp.json` (`mcpServers`) |

### Wiring files

`AGENTS.md` is the one authored wiring file. GitHub Copilot reads it as agent instructions on the
GitHub website and in VS Code; Codex and Cursor read it natively; Claude Code reads it through the
`@AGENTS.md` import that is the whole of `CLAUDE.md`. The standard therefore generates no
`.github/copilot-instructions.md`, no `.github/instructions/*.instructions.md`, and no
`.cursor/rules/*.mdc`. A project that already has one of those keeps it, recorded in
`agent-registry.md`.

What may go into a wiring file, and what belongs in `.ai/` instead, is in
`standards/writing-rules.md` §3 and §4.

### Skills

`.agents/skills/` is the source of truth for skill content. Copilot, VS Code and Cursor read it
among other locations, and Codex reads only `.agents/skills` paths, which is why the source lives
there. Claude Code reads `.claude/skills/` and nothing else, so every skill is mirrored into it.
The mirror is a copy or a symlink, never hand-edited independently.

`.github/agents/` and `.github/prompts/` stay the source for agents and prompts, with the
`.claude/*` and `.cursor/*` copies as exact mirrors, re-copied on change.

The `codebase-overview` skill is generated: its body carries the repository tree, technology stack
table, placement conventions and high-fan-in symbols copied from `.ai/architecture.md`, inside
marked generated blocks. `.ai/architecture.md` remains the only hand-edited home for those
sections, and the Maintainer Agent regenerates the skill when they change.

**Known duplication — agents in VS Code:** VS Code Copilot default-scans **both** `.github/agents/` and `.claude/agents/`, so every agent appears **twice** in its agent picker. This is intentional and unavoidable — `.github/agents/` serves the github.com cloud Copilot coding agent, `.claude/agents/` serves Claude Code, and VS Code happens to read both. There is no setting to un-scan a default location. To mitigate: (1) each `.claude/agents/*.md` mirror keeps the **same `name:` frontmatter** as its `.github/agents/*.agent.md` source, so the two picker rows carry the identical label (clearly one agent, not two); (2) a developer bothered by the duplicate can hide one row via the eye icon in VS Code's *Agent Customizations* editor (gear icon in the Chat view). Prompt-commands (`.claude/commands/`) and skills (`.claude/skills/`) do **not** duplicate — VS Code does not default-scan those Claude folders.

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
