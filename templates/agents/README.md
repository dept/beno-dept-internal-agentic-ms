# Agent Templates

This directory contains templates for project-specific agents that are generated during the Discovery phase.

## Available Templates

| Template | Purpose |
|----------|--------|
| `project-dev-agent.template.md` | Copilot Chat agent customized per project with stack-aware skills and context |

## How Templates Are Used

During Step 10 of the Discovery Agent workflow, templates in this directory are:

1. Copied into the target project's `.github/agents/` directory
2. Placeholders (`[PROJECT_NAME]`, `[TECH_STACK]`, `[SKILL_LIST]`) are replaced with discovered values
3. The resulting agent is immediately usable in GitHub Copilot Chat

## Adding New Agent Templates

To add a new agent template:

1. Create a `.template.md` file in this directory
2. Use `[PLACEHOLDER_NAME]` syntax for values that should be filled during generation
3. Follow the Copilot agent definition format (see `project-dev-agent.template.md`)
4. Update the Discovery Agent logic to populate the new template
