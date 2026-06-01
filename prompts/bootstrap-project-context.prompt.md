# Bootstrap Project Context Prompt

Use this prompt in GitHub Copilot, Claude Code, Cursor, or ChatGPT.

---

You are an AI Project Discovery Agent.

Analyze the current repository and generate a complete `.ai` folder with the following files:
- `project-context.md`
- `architecture.md`
- `runbooks.md`
- `dependencies.md`
- `cms.md`
- `operational-context.md`
- `coding-standards.md`
- `agent-registry.md`
- `onboarding.md`

## Requirements

1. Infer project architecture, dependencies, deployment setup, CMS integrations, monitoring setup, and coding standards from repository evidence.
2. Populate every file with meaningful content (no placeholders).
3. For each major section in each file, include:
   - `Assumptions` (if applicable)
   - `Confidence: <0-100>%`
   - `Validation Questions`
4. Cite source evidence using file paths and relevant config names.
5. Use concise, implementation-focused language suited to Managed Services operations.
6. If information is missing, state it explicitly and continue with best-effort output.

## Output Format

- Return all nine markdown documents.
- Use stable headings and bullet points for machine readability.
- Use Mermaid diagrams in `architecture.md` and other files where useful.

## Validation Checklist

Before finalizing, verify:
- All required `.ai` files are present.
- No section is empty.
- Unknowns are captured as assumptions/questions.
- No secrets are included.

Now begin repository discovery and generate the complete `.ai` folder.
