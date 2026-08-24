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

`CLAUDE.md` is a real file holding that import, never a symlink to `AGENTS.md`, for two reasons. A
write aimed at `CLAUDE.md` follows the link and overwrites `AGENTS.md`, which has already destroyed
authored content in a real repository. And on a Windows checkout without symlink support git
materialises the link as a plain text file containing the path `AGENTS.md`, so the harness reads a
one-line file and the project silently loses its instructions. (The `.claude/skills/` mirror is the
separate case where a symlink is the rule, see Claude Code mirrors below.)

What may go into a wiring file, and what belongs in `.ai/` instead, is in
`standards/writing-rules.md` §3 and §4.

### Skills

`.agents/skills/` is the source of truth for skill content. Copilot, VS Code and Cursor read it
among other locations, and Codex reads only `.agents/skills` paths, which is why the source lives
there. Claude Code reads `.claude/skills/` and nothing else, so the source is mirrored into it,
see Claude Code mirrors below.

`.github/agents/` and `.github/prompts/` stay the source for agents and prompts, with the
`.claude/*` and `.cursor/*` copies as mirrors.

The `codebase-overview` skill is generated: its body carries the repository tree, technology stack
table, placement conventions and high-fan-in symbols copied from `.ai/architecture.md`, inside
marked generated blocks. `.ai/architecture.md` remains the only hand-edited home for those
sections, and the Maintainer Agent regenerates the skill when they change.

### Claude Code mirrors

Claude Code reads `.claude/`; every other harness reads `.agents/skills/` and `.github/`. Nothing
under `.claude/` is authored, and neither mirror is maintained by hand: a hand-maintained second
copy drifts, and it has (13 duplicated skill files in one client repository, and two copies of the
same agent in another, where the Claude copy had decayed into a 22-line wrapper telling the
reader to go and read the 106-line `.github/` file).

| Mirror | Form | Rebuilt by |
|---|---|---|
| `.claude/skills` | one relative symlink to `.agents/skills` | nothing to rebuild, it cannot drift |
| `.claude/agents/<role>.md` | one relative symlink to `.github/agents/<role>.agent.md` | nothing to rebuild, it cannot drift |
| `.claude/commands/<name>.md`, `.cursor/commands/<name>.md` | copied from `.github/prompts/<name>.prompt.md` | the phase prompts, on change |

`scripts/mirror-claude.sh` creates and repairs both Claude mirrors and is idempotent.
`scripts/install.sh` runs it on install and on every `--update` refresh, so a refresh converts a
project still carrying copied `.claude/skills/` and `.claude/agents/*.md` files. Run it yourself
after adding or deleting a skill or an agent; an *edit* needs nothing, both mirrors are links.

**Agent frontmatter is one file's worth.** `tools:` is optional in both harnesses and omitting it
means the agent has every available tool, MCP servers included, so the standard's agents carry no
`tools:` line. A Copilot-format list would be actively wrong on the Claude side, where `tools`
expects Claude tool names, and each harness ignores frontmatter keys it does not know. That leaves
`description` and `name` only, valid for both, so the agent mirror is a symlink like the skill
mirror rather than a generated file. An agent that genuinely needed a restricted Copilot tool set
would be the one case for a per-agent transform; none of the standard's agents does.

**Agent file names:** an agent is named by its role alone, on both sides:
`.github/agents/<role>.agent.md` and `.claude/agents/<role>.md`, giving `discovery`, `maintainer`
and `support`. The directory already says these are agents, so a `-agent` suffix repeated the word
(`support-agent.agent.md`), and the two sides used different names for the same agent. A symlink
may be named differently from its target, so the `.agent.md` to `.md` difference is not a problem;
the extension on the source stays because it is what VS Code's agent-file convention uses, and
GitHub's cloud coding agent matches any `.md` under `.github/agents/`. The `name:` value is the
same role in lowercase (`support`, not `"Support Agent"`), which is what Claude Code's naming rule
allows and what both pickers show.
`scripts/mirror-claude.sh` migrates a project still on the old names: it renames a legacy
`.github/agents/<role>-agent.agent.md` (or an extension-less `<role>-agent.md`) to
`<role>.agent.md`, and removes the stale `.claude/agents/<role>-agent.md` left behind, because two
mirror files carrying the same `name:` register as two agents under one name.

**Why `.github/agents/` stays the source:** it is the only location the GitHub cloud Copilot coding
agent reads for repository-level agents (the alternatives are org-level and enterprise-level
repositories, not this repository). VS Code defaults to `.github/agents` and also detects
`.claude/agents`, and its `chat.agentFilesLocations` setting only adds further locations, so it is a
machine or workspace setting rather than repository content. Moving the source under `.agents/`
would therefore need per-developer settings and still leave the cloud agent unconfigurable, forcing
a third copy. One authored file per agent is worth more than folder symmetry with skills.

Nothing is ever deleted silently. A skill found only in a copied `.claude/skills/` directory is
moved into `.agents/skills/` and reported. A `.claude/agents/<role>.md` copy is replaced by the
symlink only when its body already matches the source; when the two have drifted the script changes
nothing and says so, because only a human can decide which text is right. A `.claude/agents/*.md`
with no source is reported and left in place. On a checkout that cannot create symlinks (Windows
without developer mode) the script falls back to copying and says so, and that project has to
re-run it after every change. `scripts/validate.sh` counts a symlinked mirror correctly, it uses
`find -L`.

**Known duplication — agents in VS Code:** VS Code Copilot default-scans **both** `.github/agents/` and `.claude/agents/`, so every agent appears **twice** in its agent picker. This is intentional and unavoidable — `.github/agents/` serves the github.com cloud Copilot coding agent, `.claude/agents/` serves Claude Code, and VS Code happens to read both. There is no setting to un-scan a default location. To mitigate: (1) `.claude/agents/*.md` is a symlink to the `.github/agents/*.agent.md` source, so the two picker rows are the same file under the same `name:` (clearly one agent, not two); (2) a developer bothered by the duplicate can hide one row via the eye icon in VS Code's *Agent Customizations* editor (gear icon in the Chat view). Prompt-commands (`.claude/commands/`) and skills (`.claude/skills/`) do **not** duplicate — VS Code does not default-scan those Claude folders.

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
