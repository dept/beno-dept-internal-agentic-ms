# Skill Templates

The Discovery Agent installs skills from the **public `gh skill` registry** at runtime in the target project:

```bash
gh skill search nextjs
gh skill install <owner>/<repo> nextjs
```

Skills are installed directly into the target project's `.github/skills/` by the `gh` CLI — they come from the public internet ([agentskills.io](https://agentskills.io)), not from this repo. No fallback templates are stored here; the live registry is the single source.

## Adding a new technology

1. Add an entry to `config/stack-detection.yml` with detection patterns and a `search_term`
2. Update the technology detection table in `agents/ai-project-discovery-agent.agent.md`
