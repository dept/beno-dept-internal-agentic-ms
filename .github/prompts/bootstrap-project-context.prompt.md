---
agent: "AI Project Discovery Agent"
description: "Bootstrap a new project's .ai folder by running the AI Project Discovery Agent. Analyzes the repository and generates all nine .ai context files plus AI wiring files."
---

Run the **AI Project Discovery Agent** on this repository.

**Critical:** Write all output as actual files to the repository on disk. Do not write to session files or summarise in chat only. If `.ai/` does not exist, create it.

**Exclude from analysis:** `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/`, `.git/`, `coverage/`, `.cache/`, `.pnpm-store/`

**For monorepos:** Read `turbo.json`, `pnpm-workspace.yaml`, or root `package.json#workspaces` first. List all packages and treat each as a named service boundary before beginning per-package analysis.

## Step 1 — Generate `.ai/` context files

Generate and write all nine files to `.ai/`:
- `project-context.md`
- `architecture.md`
- `runbooks.md`
- `dependencies.md`
- `cms.md`
- `operational-context.md`
- `coding-standards.md`
- `agent-registry.md`
- `onboarding.md`

For each file:
1. Start from root config files. Map all packages/apps first.
2. Extract evidence from source code, config, CI/CD, and infrastructure files.
3. Populate every section — no placeholders, no empty sections.
4. Include `Assumption:` tags, `Confidence: <0-100>%`, and `Validation Questions` per major section.
5. Cite source evidence using file paths and config names.
6. Redact any secrets or privileged credentials.

## Step 2 — Wire AI context for all tools

After generating `.ai/`, create the following wiring files so every AI tool automatically loads the context:

**`.github/copilot-instructions.md`**
Write instructions telling GitHub Copilot to read `.ai/` at the start of every session. Include the full list of `.ai/` files, behaviour rules (evidence-first, no hallucination, structured output), and a note to flag stale context.

**`CLAUDE.md`** (repository root)
Write the same instructions for Claude Code in the format Claude expects.

**`.github/instructions/ai-context.instructions.md`**
Write a Copilot instructions file with `applyTo: "**"` frontmatter that loads `.ai/` context for every file interaction.

Do not overwrite an existing `.github/copilot-instructions.md` if it already exists — append the `.ai/` reading instructions to the end instead.

## Step 3 — Completion summary

After all files are written, output:
```
## Bootstrap Complete

### .ai/ files created
[list each file]

### AI wiring files created/updated
[list each file]

### Validation Questions to resolve
[list open questions from all .ai/ files]

### Next steps
- Review .ai/ files and resolve Validation Questions
- Commit to a feature branch and open a PR
- Run AI Project Maintainer Agent after each sprint
```
