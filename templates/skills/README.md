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

**Fixed DEPT skills** (used by every project regardless of stack) ARE stored here as templates:

- `confluence-axi/` — drive Confluence Cloud (handover pages) from the terminal via the `confluence-axi` npm CLI (`npx`, no bundled script). Every DEPT MS project publishes handover pages to Confluence, so this ships with every migration. **Phase 1** copies it to `.github/skills/confluence-axi/`.
- `codebase-overview/` — the discovery entry point into `.ai/`. Its `description` is what makes an agent read the project's structure before exploring the tree; its body is a routing table into `.ai/`, never a copy of it. **Phase 4** emits it to `.github/skills/codebase-overview/` alongside the stack-specific skills, substituting `[PROJECT_NAME]`. It stays thin by design: `.ai/architecture.md` is the single source of truth, and content pasted here would drift, publish to the wrong Confluence page, and be invisible to harnesses with no skill loader.

Datadog "key features" have **no skill** — they are fetched via the **Datadog MCP** (browser OAuth), configured in Phase 4.

Only **stack-specific** skills are left to Phase 4 (vendor-fetched via `gh skill` or generated from `.ai/` evidence) and are NOT stored here — they live in the target project's `.github/skills/`.

**Multi-client mirroring:** `.github/skills/` is Copilot-only: Claude Code, Continue, and Kilocode don't read it, so every skill installed to `.github/skills/` is also present at `.claude/skills/`. SKILL.md's frontmatter format is identical across clients, so no rewrite is involved. `.github/skills/` remains the single source of truth and the mirror is never hand-edited. A copy and a symlink are both acceptable: the tradeoff and the rule are stated once in `agents/discovery.agent.md` → Step B rule 5.

## Adding a new technology

1. Add an entry to `config/stack-detection.yml` with detection patterns
2. Add a matching entry to `config/mcp-registry.yml` if a verified MCP server exists
3. The Discovery Agent will use these when bootstrapping projects that include the technology
