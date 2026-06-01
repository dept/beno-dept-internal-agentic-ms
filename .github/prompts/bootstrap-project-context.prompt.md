---
agent: "AI Project Discovery Agent"
description: "Bootstrap a new project's .ai folder by running the AI Project Discovery Agent. Analyzes the repository and generates all nine .ai context files."
---

Run the **AI Project Discovery Agent** on this repository.

Analyze the current repository and generate a complete `.ai` folder with all required files:
- `project-context.md`
- `architecture.md`
- `runbooks.md`
- `dependencies.md`
- `cms.md`
- `operational-context.md`
- `coding-standards.md`
- `agent-registry.md`
- `onboarding.md`

Follow the full discovery procedure:
1. Analyze repository structure, languages, and service boundaries.
2. Extract architecture, dependencies, deployment, CMS, monitoring, and coding standards from evidence in the codebase.
3. Populate all nine files — no placeholders, no empty sections.
4. For each major section include `Assumption:` tags, `Confidence: <0-100>%`, and `Validation Questions`.
5. Cite source evidence using file paths and config names.
6. Redact any secrets or privileged credentials.

After generating the `.ai` folder, remind the user to:
- Review and resolve all Validation Questions
- Commit `.ai/` to a feature branch and open a PR
- Run the AI Project Maintainer Agent after each sprint to keep it current
