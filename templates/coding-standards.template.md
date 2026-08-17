# Coding Standards Template

## Purpose
Capture the conventions and quality gates an AI agent could not derive from the repository on its
own, so it proposes changes the way this team writes them.

## Writing rules

`standards/writing-rules.md` governs this file. Read it before writing. Two parts apply directly:

- **§3, what `coding-standards.md` records about the toolchain.** The three-way auto-fixability
  test decides whether a tool-enforced rule gets written at all. Most do not. Apply it to every
  rule before writing it, and write class 3 rules as the positive instruction.
- **§2, one topic, one file.** Config contents, pipeline stages and per-package descriptions are
  owned elsewhere.

Neither is repeated here. Follow the pointers.

## Ownership header

The generated file opens with this block, immediately after the H1:

> **Owned by this file:** the commands that enforce quality and what each runs, config file
> locations by path, project-specific rules an agent cannot recover from a tool error, and the
> conventions no tool checks (commit format, review expectations, accessibility target, testing
> expectations, fork discipline). This is the authoritative source. `AGENTS.md` may carry up to
> five repo-wide constraints from it, but must not restate these rules in full.
> **Not carried here:** config file contents; deploy pipeline stages (`operational-context.md`);
> per-package descriptions (`architecture.md`); anything a formatter fixes on save.

## Required Sections

- Commands: what to run before opening a PR, and what each one checks
- Config locations, one line per path
- Configs that resolve outside this repository, and where their rules actually live
- Conflicts between two configs, and which wins in practice
- Parts of the codebase a tool does not cover, when the uncovered part needs different behaviour
- Project-specific rules a tool error cannot teach (writing-rules §3, class 3)
- Conventions no tool checks: commit format, branching and PR expectations, review expectations
- Testing requirements
- Security and compliance checks
- Accessibility target (WCAG level), DEPT baseline is WCAG 2.2 Level AA

## Example Content
- Commands: "`pnpm check` runs lint, types and unit tests. The pre-push hook runs the same target."
- Config location: "Prettier: `frontend/.prettierrc`."
- External config: "ESLint extends `dept-builder/config/eslint`; the rules live in that package,
  not in this repo."
- Conflict: "`.editorconfig` sets tabs, Prettier sets `tabWidth: 2`, Prettier runs last, so files
  land 2-space."
- Class 3 rule: "Import `env` from `@unicef/env` for every environment variable."
- Accessibility: "Front-end changes meet WCAG 2.2 Level AA (semantic HTML, keyboard nav, colour
  contrast, focus management)."

## Validation
- Does every rule in the file pass the writing-rules §3 test, and is every class 3 rule written as
  the thing to do rather than the prohibition?
- Are the mandatory commands listed, with what each one checks?
- Does every config path named in this file exist?
- Are the conventions no tool enforces written out in full?

## Missing Information
- Missing exception process for urgent hotfixes
- Unclear test coverage threshold by package
