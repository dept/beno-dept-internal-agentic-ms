# Writing rules for `.ai/`, wiring files, and skills

This file is the single home for the rules that govern what gets written into a project's
`.ai/` folder, its wiring files, and its skill files.

**These rules are never restated.** Every template, agent, prompt and logic file that needs them
carries a pointer to this file and nothing more. Copying a rule out of here into a second file is
the exact failure the rules exist to prevent: two copies drift, and an agent then has two
contradictory instructions and no way to tell which is current.

Referenced from `agents/discovery.agent.md`, `agents/maintainer.agent.md`,
`agents/discovery/logic.md`, `agents/maintainer/logic.md`, `prompts/02-discover.prompt.md`,
`prompts/04-stack-tooling.prompt.md`, `prompts/migrate.prompt.md`, and all nine `.ai/` templates.

---

## 1. Write what is there

A `.ai/` file describes the system as it is now. It is not a log, a changelog, an audit trail, or a
record of how it came to look this way. Four kinds of sentence are banned in every `.ai/` file,
with one exception, stated at the end.

1. **Absence.** "There is no X." "No per-package lint configs exist." "None detected."
2. **Removal.** "X was removed on 2026-07-16." "Commit `527c955a` removed the install prompts." Any
   section titled *Cleanup*, *Post-migration*, or *Removed*.
3. **Process and dates.** "Installed by Phase 4 (2026-06-26)." "Added this maintenance window."
   "Skipped during Phase 2." Any reference to a migration phase, a maintenance run, or the date on
   which documentation work happened.
4. **Self-correction.** "Corrected 2026-07-20: a prior version of this note claimed..." Any
   strikethrough of a previous answer.

**The test: delete the sentence, and ask whether a reader now believes something false about the
system.** If deleting it changes nothing except that they know less about our documentation
process, it was never about the system. Delete it.

Categories 2, 3 and 4 go in the pull request that carried the change, and nowhere else. A human
reads history in git.

### The one exception, and how to write it

Sometimes an absence is a live constraint: an agent that does not know it will do the wrong thing.
"CI runs no tests" is that, because an agent will otherwise assume its change is covered. "There is
no ESLint config" is not, because nothing follows from it.

An absence qualifies only if you can finish this sentence: *"an agent that did not know this
would ___"*, with a concrete wrong action in the blank. If you cannot finish it, drop the sentence.

When it qualifies, **write the instruction, not the absence.** The fact goes in as what to do.

- Write: ``CI builds and deploys but runs no tests; verify a change by deploying to `inte.hyva.com`
  and checking by hand.``
  Not: ``There is no `dotnet test` step in the pipeline.``
- Write: ``Formatting is enforced by Prettier alone; add formatting rules to `.prettierrc`, not to
  ESLint.``
  Not: `There is no ESLint formatting config.`
- Write: ``Content renders server-side from Razor views, so there is no content API to fetch
  from.`` (once the instruction leads, the absence may ride along in the same sentence)
  Not: `There is no headless layer.`

**Confidence and evidence notes are unaffected.** `Confidence: 85% (source: turbo.json, verified
2026-08-12)` is a fact about the evidence, not about a previous version of the file. A note naming
an earlier version of the file, a commit, or a prior repository state is banned however it is
phrased, including when dressed up as provenance.

**`agent-registry.md` in particular.** It lists what is installed now, one row each, with what each
thing is for. Not when it arrived, not which phase installed it, not what was considered and
skipped, not what was removed, not what was there before.

### Consequence for deletion

Content that breaks any rule in this file is by that fact wrong, and an agent that finds it removes
it. This is not a judgement call and does not need a second opinion. See §5.

---

## 2. One topic, one file

Every fact in `.ai/` has exactly one owning file. A file that needs a fact it does not own links
to it and does not restate it: not in summary, not in a shorter table, not in a different shape.

Before writing a section, find its topic in the ownership table in §4. If this is not the owning
file, write a pointer of at most one line, or write nothing.

A pointer is: ``Environments and URLs: `onboarding.md` -> *Platform Access Links*.``
A pointer is not a table with two of the five columns, a "short summary", or "see also" followed
by three sentences of the content.

**The test for a restatement: if the owning file changed tomorrow, would this text become wrong?**
If yes, it is a restatement. Delete it. If it would merely become incomplete, it is still a
restatement. A pointer cannot go stale, because it carries no facts.

**Per-area sections are the trap.** Several files can plausibly host a per-package or per-feature
list. Only `architecture.md` does. If you have written "`packages/foo` handles X" anywhere else,
that sentence belongs in `architecture.md`. What stays behind is the thing specific to *this*
file's topic *and* to that package, never the package's purpose.

### The ownership header

Every generated `.ai/` file opens with an ownership header, immediately after the H1, taken from
the file's row in the §4 table:

```
> **Owned by this file:** <the "Owns" column, in prose>.
> **Not carried here:** <the "Must never contain" column, each with the file that owns it>.
```

### Boilerplate that repeats across files

A block of text that would be identical in more than one `.ai/` file is a pointer, one line, not a
block. This applies to the Confluence "Open Questions" pointer under *Validation Questions*: write
one line naming the page, not a paragraph explaining the workflow.

---

## 3. What `coding-standards.md` records about the toolchain

A rule that a tool applies to your output without you knowing it exists is not context, it is
noise. Before writing any rule, apply this test. It has three outcomes and no middle ground.

**If an agent wrote code that broke this rule, what happens?**

1. **A tool silently rewrites it and the code is then correct.** Prettier, `dotnet format`,
   `eslint --fix` on a stylistic rule, EditorConfig, `gofmt`, `ruff format`. **Never write the
   rule.** Quote style, indent width, trailing commas, semicolons, import order, line length,
   brace style and final newlines are in this class permanently.
2. **A tool rejects it and the error message alone tells the agent what to write instead.** A type
   error, an unknown import, a missing required prop. **Never write the rule.** The correction
   arrives free on the first failed run.
3. **A tool rejects it and the agent cannot get the right answer from the error**, because the
   correct alternative is a project-specific symbol, path or package it would have to go find.
   **Write it, once, here, as the positive instruction.**

Class 3 is small. In practice it is: a banned global with a project-local replacement, a required
import path, a wrapper that must be used instead of a standard API, a generation step that must
run after a schema change. If the rule you are about to write does not name a replacement the
agent could not have guessed, it is class 1 or class 2. Drop it.

**How to write a class 3 rule.** State the thing to do. Do not state the prohibition, do not name
the tool, do not name the rule ID, do not describe the consequence of getting it wrong.

- Write: ``Import `env` from `@unicef/env` for every environment variable.``
- Not: ``Never access `process.env` directly, import `env` from `@unicef/env`. Oxlint catches it
  repo-wide as an error, so the cost of getting it wrong is a failed `pnpm check`.``

**What this file records about the toolchain instead of its rules:**

- The commands. `pnpm check`, `dotnet format --verify-no-changes`, what the pre-commit and
  pre-push hooks run.
- Where each config lives, by path, one line each: ``Prettier: `frontend/.prettierrc` ``. Never its
  contents.
- Configs that resolve **outside** the repository, because there the agent cannot read them:
  ``ESLint extends `dept-builder/config/eslint`; the rules live in that package, not in this repo.``
- A disagreement between two configs and which one wins in practice, because reading either alone
  gives the wrong answer: ``.editorconfig` sets tabs, Prettier sets `tabWidth: 2`, Prettier runs
  last, so files land 2-space.``
- A part of the codebase a tool does **not** cover, when the uncovered part needs different
  behaviour: ``Razor views are exempt from nullable analysis; `#nullable disable` has no effect
  there and the warnings are suppressed in `Views/_viewstart.cshtml`.``

**Rules no tool checks at all still belong here in full**: commit message format when there is no
commitlint, review expectations, the accessibility target, testing conventions, "this is a fork,
keep diffs minimal". The test above governs tool-enforced rules only.

**In wiring files** (`AGENTS.md`, `CLAUDE.md`): nothing from class 1 or class 2 at all, and from
class 3 only rules that apply repo-wide. Five maximum. Everything else is a pointer to
`coding-standards.md`.

---

## 4. Ownership table

Single ownership. No shared responsibility. This table is the referent for §2 and is the source of
each file's ownership header.

| File | Owns, as the single source | Must never contain |
|---|---|---|
| `architecture.md` | Annotated repository tree, one line per app/package; technology stack table; service and trust boundaries; runtime and data-flow diagram; high-fan-in symbols; placement conventions ("a new X goes in Y, follow Z") | Business purpose or ownership (-> `project-context.md`); tool configuration (-> `coding-standards.md`); dependency versions or vendor risk (-> `dependencies.md`); any URL (-> `onboarding.md`) |
| `project-context.md` | What the system is for; business capabilities; key features and their monitoring; client, team and delivery model | The tree, the stack table, per-package roles (-> `architecture.md`); environments or URLs (-> `operational-context.md` / `onboarding.md`); anything about how code is written (-> `coding-standards.md`) |
| `coding-standards.md` | The commands that enforce quality and what each runs; config file locations by path; class 3 rules (§3); conventions no tool checks (commits, review, accessibility target, testing expectations, fork discipline) | Config contents; pipeline stages (-> `operational-context.md`); per-package descriptions (-> `architecture.md`); anything a formatter fixes |
| `dependencies.md` | Direct dependency inventory with versions and why each is present; upgrade constraints; vendor and supply-chain risk; lockfile situation | Which package uses what for feature reasons (-> `architecture.md`); install commands (-> `onboarding.md`) |
| `operational-context.md` | Environments and what each is for; deploy pipeline stages; configuration and secret handling model; monitoring and alerting wiring; hosting model | Environment URLs (-> `onboarding.md`); executable procedures (-> `runbooks.md`); per-package notes (-> `architecture.md`) |
| `runbooks.md` | Procedures someone executes: incident triage, rollback, scheduled operations, known failure signatures, escalation path | Description of the pipeline itself (-> `operational-context.md`); anything not written as steps |
| `cms.md` | Content model and types; editorial workflow; publish and preview behaviour; cache or revalidation consequences of publishing; CMS-side integrations | The CMS console URL (-> `onboarding.md`); which package renders what (-> `architecture.md`) |
| `onboarding.md` | **Every URL and access link in the project**: repository, environments, CMS console, secret store, dashboards. First-day setup; local development workflow; contacts | Explanations of what the systems behind those URLs do (-> the owning file); coding rules (-> `coding-standards.md`) |
| `agent-registry.md` | The agents, skills, MCP servers and instruction files present now, one row each, with what each is for; governance rules for using them | Anything about how they got there: install dates, migration phases, what was removed, skipped, or did not exist before (§1) |
| `.meta.yml` | Standard version, generation and maintenance stamps, the Confluence `sync_map` and resolved page IDs | Prose. Any fact about the codebase |
| `AGENTS.md` | The one authored wiring file. Two sentences on what the project is; setup and check commands; up to five class 3 repo-wide constraints; the index into `.ai/` and into skills | Any class 1 or class 2 rule; any fact that lives in a `.ai/` file, restated |
| `CLAUDE.md` | One line: `@AGENTS.md`, plus Claude-Code-only lines if any exist | Everything else. It is an import, not a copy |
| `.agents/skills/codebase-overview/SKILL.md` | A description that triggers discovery, plus the structural content generated from `.ai/architecture.md`: annotated tree, stack table, placement conventions, high-fan-in symbols | Facts not present in `.ai/architecture.md`; a routing table into the other `.ai/` files beyond one pointer line; hand edits inside the generated block |
| `.agents/skills/<technology>/SKILL.md` | How this project uses that technology, with code copied from real call sites | Global constraints already in `.ai/` (pointer only); line numbers; evidence residue; negative trivia |
| `.claude/skills/` | Mirror of `.agents/skills/`, copy or symlink | Divergent content |

Every harness in use reads `AGENTS.md`: Claude Code through the `@AGENTS.md` import in `CLAUDE.md`,
Copilot on the GitHub website and in VS Code as agent instructions, Codex and Cursor natively.
There is therefore one authored wiring file and no generated copies of it.

---

## 5. Deleting content that breaks these rules

The agents are otherwise conservative about deletion, and must stay that way: a human may have
added a fact by hand, and an agent that did not generate it still must not remove it just because
it did not recognise it.

The three cases where an agent removes existing content:

1. **It breaks a rule in this file.** Change narration, a restated fact owned by another file, a
   class 1 or class 2 rule, an absence that fails the "an agent that did not know this would ___"
   test. Delete it outright. No note is left saying it was deleted: that note would itself break §1.
2. **It is provably wrong**, meaning current repository evidence contradicts it: it names a file,
   symbol, command, or environment that does not exist. Replace it with what is there.
3. **A human explicitly asked for its removal.**

In every other case, add or update, and do not delete. Content that is merely old, merely
unfamiliar, or merely not something this agent would have written is not eligible. If a fact
cannot be confirmed from repository evidence and does not break a rule above, leave it and note the
uncertainty next to it rather than removing it.
