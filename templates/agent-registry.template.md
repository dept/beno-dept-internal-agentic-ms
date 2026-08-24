# Agent Registry Template

## Purpose
Track the agentic configuration present in this project: agents, instructions, prompts, skills, and
MCP servers, plus approved AI agents, their permissions, and safe operating scope.

## Writing rules

`standards/writing-rules.md` governs this file, and §1 names it specifically: this file lists what
is installed now, one row each, with what each thing is for. Read it before writing. It is not
restated here.

## Ownership header

The generated file opens with this block, immediately after the H1:

> **Owned by this file:** the agents, skills, MCP servers and instruction files present now, one
> row each with what each is for, and the governance rules for using them. This is the
> authoritative source.
> **Not carried here:** anything about how they got there. Install dates, migration phases, what
> was removed, what was skipped, and what did not exist before are all out.

## Required Sections

### Existing Agentic Setup

Document what the agentic setup inventory finds present:

| Type | File / Location | Target Tool | Purpose |
|------|----------------|-------------|---------|
| Agent | `.github/agents/example.agent.md` | Copilot | Example agent |
| Instructions | `AGENTS.md` | All harnesses | Project-wide instructions |
| Instructions | `CLAUDE.md` | Claude Code | Imports `AGENTS.md` |
| Prompt | `.github/prompts/example.prompt.md` | Copilot | Example prompt |
| Skill | `.agents/skills/codebase-overview/` | All harnesses | Repository structure and placement |
| Skill | `.claude/skills` | Claude Code | Symlink to `.agents/skills/` |
| MCP | `.vscode/mcp.json` | VS Code / Copilot | MCP server config |
| MCP | `.cursor/mcp.json` | Cursor | MCP server config |
| MCP | `.mcp.json` | Claude Code | MCP server config |

List what is present. If nothing is present, the section is omitted.

### Approved Agents

- Agent catalog (name, purpose, tool)
- Allowed actions per agent
- Restricted actions
- Required human approvals

### Governance

- Audit and logging requirements
- Escalation owner for policy violations
- Approval boundaries

## Validation
- Is each agent mapped to a clear owner?
- Are approval boundaries explicit and enforceable?
- Does every row name something that exists in the repository right now?
- Does the file pass every rule in `standards/writing-rules.md`?

## Missing Information
- Missing escalation owner for policy violations
- Incomplete logging retention policy
