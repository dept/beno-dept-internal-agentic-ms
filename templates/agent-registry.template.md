# Agent Registry Template

## Purpose
Track all agentic configuration in this project: existing agents, instructions, prompts, skills, and MCP servers — plus approved AI agents, their permissions, and safe operating scope.

## Required Sections

### Existing Agentic Setup

Document everything found during the agentic setup inventory:

| Type | File / Location | Target Tool | Purpose |
|------|----------------|-------------|---------|
| Agent | `.github/agents/example.agent.md` | Copilot | Example agent |
| Instructions | `.github/copilot-instructions.md` | Copilot | Project-wide instructions |
| Instructions | `CLAUDE.md` | Claude Code | Project-wide instructions |
| Prompt | `.github/prompts/example.prompt.md` | Copilot | Example prompt |
| MCP | `.vscode/mcp.json` | VS Code / Copilot | MCP server config |
| MCP | `.cursor/mcp.json` | Cursor | MCP server config |
| MCP | `.mcp.json` | Claude Code | MCP server config |

If none found: `None detected — this project has no prior agentic configuration.`

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
- Is existing agentic config documented and understood by the team?

## Missing Information
- Missing escalation owner for policy violations
- Incomplete logging retention policy
