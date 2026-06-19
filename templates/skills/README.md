# Skill Templates

The Discovery Agent installs skills into the target project at runtime using GitHub CLI skills:

```bash
# Search for a vendor-maintained skill on GitHub
gh skill search "<technology-name>" --owner <vendor-org> --limit 5 --json repo,skillName,path,stars

# If a vendor org result is found, install it into the project
gh skill install <owner>/<repo> <skill-name> --dir .github/skills --force
```

If no authoritative vendor-owned `gh skill search` result is found, the agent generates a minimal project-specific fallback skill from the `.ai/` evidence collected during discovery so the detected technology still has a concrete `.github/skills/<technology-name>/SKILL.md`. These generated skills live in the target project's `.github/skills/` folder, not in this repo.

No template skills are stored here. Skills for this standards repo itself (agents, prompts, scripts) live at the repo root under `agents/` and `prompts/`.

## Adding a new technology

1. Add an entry to `config/stack-detection.yml` with detection patterns
2. Add a matching entry to `config/mcp-registry.yml` if a verified MCP server exists
3. The Discovery Agent will use these when bootstrapping projects that include the technology
