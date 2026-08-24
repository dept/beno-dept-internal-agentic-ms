# Skill Templates

The Discovery Agent installs skills into the target project at runtime using GitHub CLI skills:

```bash
# Search for a vendor-maintained skill on GitHub
gh skill search "<technology-name>" --owner <vendor-org> --limit 5 --json repo,skillName,path,stars

# If a vendor org result is found, install it into the project
gh skill install <owner>/<repo> <skill-name> --dir .agents/skills --force
```

If no authoritative vendor-owned `gh skill search` result is found, the agent generates a minimal project-specific fallback skill from the `.ai/` evidence collected during discovery so the detected technology still has a concrete `.agents/skills/<technology-name>/SKILL.md`. These generated skills live in the target project's `.agents/skills/` folder, not in this repo.

**Fallback skills must be evidence-accurate** (see accuracy rules in `prompts/04-stack-tooling.prompt.md`): no invented APIs/symbols (grep them first), only real paths (`ls`-confirmed), code samples copied from real call sites, no empty sections, and no restatement of global constraints already in `.ai/` or `AGENTS.md` (pointer only). `standards/writing-rules.md` applies to skill bodies as it does to `.ai/`.

**Fixed DEPT skills** (used by every project regardless of stack) ARE stored here as templates:

- `confluence-axi/`: drive Confluence Cloud (handover pages) from the terminal via the `confluence-axi` npm CLI (`npx`, no bundled script). Every DEPT MS project publishes handover pages to Confluence, so this ships with every migration. **Phase 1** copies it to `.agents/skills/confluence-axi/`.
- `context-ownership/`: the per-section procedure for the single-source rule, deciding which `.ai/` file owns a fact and how to write a pointer instead of a second copy. It holds no copy of the ownership map: `standards/writing-rules.md` §2 and §4b stay the single home, and the skill is what makes an agent go and apply them at the moment it writes. **Phase 1** copies it to `.agents/skills/context-ownership/`, before Phase 2 writes any `.ai/` file.
- `codebase-overview/`: the structural entry point into the project. Its `description` is what makes an agent read the project's structure before exploring the tree; its body carries the structural sections of `.ai/architecture.md`, generated from that file behind a marker. **Phase 4** emits it to `.agents/skills/codebase-overview/` alongside the stack-specific skills, substituting `[PROJECT_NAME]`. `.ai/architecture.md` stays the single editable source: the skill is a generated artifact and is regenerated when that file changes, never hand-edited.

Datadog "key features" have **no skill**: they are fetched via the **Datadog MCP** (browser OAuth), configured in Phase 4.

Only **stack-specific** skills are left to Phase 4 (vendor-fetched via `gh skill` or generated from `.ai/` evidence) and are NOT stored here: they live in the target project's `.agents/skills/`.

**Multi-client mirroring:** `.agents/skills/` is the source of truth. Copilot, VS Code, Codex and Cursor read it directly; Claude Code does not, so `.claude/skills` is a relative symlink to it, created by `scripts/install.sh` and recreated by `scripts/mirror-claude.sh`. A skill written to the source is mirrored the moment it exists, and nothing under `.claude/` is ever hand-edited. The rule, including the fallback for a checkout without symlink support, is stated once in `standards/agentic-project-standard.md` -> Claude Code mirrors.

## Adding a new technology

1. Add an entry to `config/stack-detection.yml` with detection patterns
2. Add a matching entry to `config/mcp-registry.yml` if a verified MCP server exists
3. The Discovery Agent will use these when bootstrapping projects that include the technology
