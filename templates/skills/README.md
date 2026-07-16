# Skill Templates

The Discovery Agent installs skills into the target project at runtime using GitHub CLI skills:

```bash
# Search for a vendor-maintained skill on GitHub
gh skill search "<technology-name>" --owner <vendor-org> --limit 5 --json repo,skillName,path,stars

# If a vendor org result is found, install it into the project
gh skill install <owner>/<repo> <skill-name> --dir .github/skills --force
```

If no authoritative vendor-owned `gh skill search` result is found, the agent generates a minimal project-specific fallback skill from the `.ai/` evidence collected during discovery so the detected technology still has a concrete `.github/skills/<technology-name>/SKILL.md`. These generated skills live in the target project's `.github/skills/` folder, not in this repo.

**Fallback skills must be evidence-accurate** (see accuracy rules in `prompts/04-stack-tooling.prompt.md`): no invented APIs/symbols (grep them first), only real paths (`ls`-confirmed), code samples copied from real call sites, no empty sections, and no restatement of global constraints already in `.ai/`/`copilot-instructions.md` (pointer only).

**Fixed DEPT skills** (used by every project regardless of stack) ARE stored here as templates and installed in **Phase 1**:

- `confluence-cli/` — drive Confluence Cloud (handover pages) from the terminal via the REST API. Every DEPT MS project publishes handover pages to Confluence, so this ships with every migration. Phase 1 copies it to `.github/skills/confluence-cli/`.

Only **stack-specific** skills are left to Phase 4 (vendor-fetched via `gh skill` or generated from `.ai/` evidence) and are NOT stored here — they live in the target project's `.github/skills/`.

**Multi-client mirroring:** `.github/skills/` is Copilot-only — Claude Code, Continue, and Kilocode don't read it. Every skill installed to `.github/skills/` (Phase 1's `confluence-cli` and Phase 4's stack-specific skills alike) is also copied verbatim to `.claude/skills/`. SKILL.md's frontmatter format is identical across clients, so this is a plain copy, not a rewrite. `.github/skills/` remains the single source of truth; re-copy on change, never hand-edit the mirror.

## Adding a new technology

1. Add an entry to `config/stack-detection.yml` with detection patterns
2. Add a matching entry to `config/mcp-registry.yml` if a verified MCP server exists
3. The Discovery Agent will use these when bootstrapping projects that include the technology
