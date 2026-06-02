# Skill Templates — Fallback Only

These files are fallback skill templates. They are only used when `gh skill search` returns no results or the `gh` CLI is not available in the target environment.

## Primary method

The Discovery Agent installs skills from the **public `gh skill` registry**:

```bash
gh skill search nextjs
gh skill install <owner>/<repo> nextjs
```

Skills are installed directly into the target project's `.github/skills/` by the `gh` CLI — they come from the public internet ([agentskills.io](https://agentskills.io)), not from this repo.

## Fallback method

If `gh` is unavailable, the agent generates a skill file from the matching template here and writes it to `.github/skills/<name>/SKILL.md` in the target project — populated with project-specific context from `.ai/` files.

## Adding a new technology

1. Add an entry to `config/stack-detection.yml` with detection patterns and `gh_skill_search` term
2. Add a fallback template here (optional but recommended)
3. Update the detection table in Step 10 of `.github/agents/ai-project-discovery-agent.agent.md`
