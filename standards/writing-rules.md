# Writing rules for `.ai/`, wiring files, and skills

This file is the single home for the rules that govern what gets written into a project's
`.ai/` folder, its wiring files, and its skill files.

**These rules are never restated.** Every template, agent, prompt and logic file that needs them
carries a pointer to this file and nothing more. Copying a rule out of here into a second file is
the exact failure the rules exist to prevent: two copies drift, and an agent then has two
contradictory instructions and no way to tell which is current.

`scripts/validate.sh` enforces the parts of §2 a script can see: a `## ` heading claimed by two
`.ai/` files, and a command line repeated across files.

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

## 2. One fact, one home

Every fact in `.ai/` has exactly one owning file. §4b names the owner for each topic and §4 gives
each file's full remit. Every other file that needs that fact carries a **pointer** to the owner.
It does not carry the fact.

**A `.ai/` file is not self-contained, and must not try to be.** It is one chapter of one document,
not a standalone briefing for its own audience. Writing each file complete on its own terms is
exactly what produced, in one migrated repository, the same eight build steps under two different
headings, the same container image described in six files, the same Node and package-manager
version floor in seven, and three copies of one command list that had already drifted apart
without anyone deciding they should. A reader who needs the neighbouring chapter follows the
pointer. That is what the pointer is for.

### The three shapes, and where each is allowed

Count the facts a sentence carries about a topic this file does not own.

| Shape | Facts it carries | Looks like | Allowed in |
|---|---|---|---|
| **Pointer** | none | ``Environments: `operational-context.md` -> *Environments*.`` | every file, always |
| **Constraint line** | one, with the owning file named in the same line | ``Tailwind is v3, not v4: `dependencies.md` is authoritative.`` | `AGENTS.md` and skill bodies only |
| **Restatement** | two or more, or one with no owner named | a table with two of the owner's five columns; a "short summary"; "see also" followed by three sentences of the content | nowhere: delete it |

**The constraint line is deliberate, and it is capped.** It exists for the one case a pointer
cannot serve: a rule that has to be under an agent's nose at the moment it writes code, where a
link arrives too late. That is the five repo-wide constraints in `AGENTS.md` (§3), and a global
rule a skill body would otherwise have an agent break. Its shape is fixed: one line, stating the
instruction rather than describing the topic, naming its owning `.ai/` file inline. **Without the
named owner it is not a constraint line, it is a restatement.** Two constraint lines on the same
topic in the same file is a restatement of that topic split over two lines; write the pointer.

**Between two `.ai/` files there is no constraint line.** A `.ai/` file that is not the owner
writes a pointer or writes nothing. The allowance is for `AGENTS.md` and skill bodies, which are
read at a different moment and for a different reason.

### Two tests, and both must pass

1. **If the owning file changed tomorrow, would this text become wrong?** If yes, it is a
   restatement. If it would merely become incomplete, it is still a restatement. A pointer cannot
   go stale, because it carries no facts. A constraint line can, which is why it is capped, kept
   to one line, and made to name its owner.
2. **Could a reader answer the question from this file alone, without opening the owner?** If yes,
   and this file is not the owner, you have written the owner's section a second time. Cut it back
   to a pointer. "But my reader needs it here" is the instinct that produced the duplication; the
   pointer is the answer to it.

### A heading is a claim of ownership

A `## ` heading claims its topic for the file it appears in. The same `## ` heading in two `.ai/`
files is two owners for one topic, and it is how `## Environments`, `## Environment Variables` and
`## Commit Convention` each ended up written out twice in one repository. Before adding a heading,
check that no other `.ai/` file already carries it; if one does, that file is the owner and this
one gets a pointer. The one exception is the boilerplate section every file carries by mandate,
`## Validation Questions`. `scripts/validate.sh` fails on any other repeated `## ` heading across
`.ai/`, and warns on a command line repeated across files.

### Before writing a section

Find its topic in §4b. If this is not the owning file, write a pointer of at most one line, or
write nothing. Write the owning file's section first and the pointers to it afterwards, so there
is something to point at.

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
| `architecture.md` | Annotated repository tree, one line per app/package; technology stack table; service and trust boundaries; runtime and data-flow diagram; high-fan-in symbols; placement conventions ("a new X goes in Y, follow Z") | Business purpose or ownership (-> `project-context.md`); tool configuration (-> `coding-standards.md`); dependency versions, toolchain version floors or vendor risk (-> `dependencies.md`); any URL (-> `onboarding.md`) |
| `project-context.md` | What the system is for; business capabilities; key features and their monitoring; client, team and delivery model | The tree, the stack table, per-package roles (-> `architecture.md`); environments or URLs (-> `operational-context.md` / `onboarding.md`); anything about how code is written (-> `coding-standards.md`) |
| `coding-standards.md` | What each quality gate enforces and which command name runs it; config file locations by path; class 3 rules (§3); conventions no tool checks (commit message and branch convention, review expectations, accessibility target, testing expectations, fork discipline) | The command cheatsheet itself (-> `onboarding.md`); config contents; pipeline stages (-> `operational-context.md`); a branch-to-environment table (-> `operational-context.md`); per-package descriptions (-> `architecture.md`); anything a formatter fixes |
| `dependencies.md` | Direct dependency inventory with versions and why each is present; **toolchain version floors** (language runtime, package manager, SDK); **framework and library version constraints** and the reason for each ("v3, not v4"); upgrade constraints; vendor and supply-chain risk; lockfile situation | Which package uses what for feature reasons (-> `architecture.md`); install commands (-> `onboarding.md`) |
| `operational-context.md` | Environments and what each is for, including the branch-to-variable-group-to-environment mapping; deploy pipeline stages; container image details (base image, build stages, run user, exposed port, entrypoint); configuration, environment-variable and secret handling model, including the variable tables; monitoring and alerting wiring and the trace sampling ratio per environment; hosting model | Environment URLs (-> `onboarding.md`); executable procedures, rollback steps included (-> `runbooks.md`); per-package notes (-> `architecture.md`) |
| `runbooks.md` | Procedures someone executes: incident triage, **rollback**, scheduled operations, known failure signatures, escalation path | Description of the pipeline, the environments, the image or the monitoring wiring (-> `operational-context.md`); anything not written as steps |
| `cms.md` | Content model and types; editorial workflow; publish and preview behaviour; **the cache layers a published change has to pass and how each is purged or revalidated**; CMS-side integrations | The CMS console URL (-> `onboarding.md`); CMS environment variables (-> `operational-context.md`); which package renders what (-> `architecture.md`) |
| `onboarding.md` | **Every URL and access link in the project**: repository, environments, CMS console, secret store, dashboards. **The command cheatsheet**: every command a developer or an agent runs, one row each with what it does. First-day setup; local development workflow; contacts | Explanations of what the systems behind those URLs do (-> the owning file); what a quality gate enforces (-> `coding-standards.md`) |
| `agent-registry.md` | The agents, skills, MCP servers and instruction files present now, one row each, with what each is for; governance rules for using them | Anything about how they got there: install dates, migration phases, what was removed, skipped, or did not exist before (§1) |
| `.meta.yml` | Standard version, generation and maintenance stamps, the Confluence `sync_map` and resolved page IDs | Prose. Any fact about the codebase |
| `AGENTS.md` | The one authored wiring file. Two sentences on what the project is; the two or three commands run on every task, as a block naming `onboarding.md` as the home of the full cheatsheet; up to five class 3 repo-wide constraint lines, each naming the `.ai/` file that owns it (§2); the index into `.ai/` and into skills | Any class 1 or class 2 rule; the command cheatsheet (-> `onboarding.md`); a constraint line that names no owner, which is a restatement (§2); any other fact that lives in a `.ai/` file |
| `CLAUDE.md` | One line: `@AGENTS.md`, plus Claude-Code-only lines if any exist, in a real file | Everything else. It is an import, not a copy, and never a symlink to `AGENTS.md` |
| `.agents/skills/codebase-overview/SKILL.md` | A description that triggers discovery, plus the structural content generated from `.ai/architecture.md`: annotated tree, stack table, placement conventions, high-fan-in symbols. Those four sections inside the generated block are the one copy this standard sanctions, because a script rewrites them | Facts not present in `.ai/architecture.md`; the command cheatsheet (-> `onboarding.md`); a routing table into the other `.ai/` files beyond one pointer line; hand edits inside the generated block |
| `.agents/skills/<technology>/SKILL.md` | How this project uses that technology, with code copied from real call sites | Global constraints already in `.ai/`, beyond a single constraint line naming the owner (§2); the command cheatsheet (-> `onboarding.md`); line numbers; evidence residue; negative trivia |
| `.claude/skills` | Symlink to `.agents/skills/` | Any hand-written content, it belongs in the source |
| `.github/agents/<role>.agent.md` | The one authored file for an agent: `description` and a `name` in display form (`Support Agent`), then the agent's instructions | A `tools:` line (omitting it means every available tool in both harnesses, and a Copilot-format list is wrong on the Claude side); any other harness-specific frontmatter key |
| `.claude/agents/<role>.md` | Symlink to `.github/agents/<role>.agent.md` | Any content at all, it belongs in the source |

Every harness in use reads `AGENTS.md`: Claude Code through the `@AGENTS.md` import in `CLAUDE.md`,
Copilot on the GitHub website and in VS Code as agent instructions, Codex and Cursor natively.
There is therefore one authored wiring file and no generated copies of it.

---

## 4b. Topic index: which file owns this fact

§4 answers "what does this file own". This table answers the question a writer actually has, which
is "I have this fact in front of me, where does it go". Look the topic up here **before** writing
the section. If the answer is not this file, write a pointer (§2) and move on.

| The fact in front of you | Its one home |
|---|---|
| What the system is for, business capabilities, client, team, delivery model | `project-context.md` |
| Which user flows are monitored and by which synthetic test | `project-context.md` |
| Repository tree, technology stack table, per-package roles, service and trust boundaries | `architecture.md` |
| Placement conventions, high-fan-in symbols, data flow and runtime diagrams | `architecture.md` |
| Environments and what each is for | `operational-context.md` |
| Branch to variable group to environment mapping | `operational-context.md` |
| Environment variable names, where each is set, and which group holds it | `operational-context.md` |
| Secret handling model (which store, how a value reaches a running app) | `operational-context.md` |
| Build and deploy pipeline stages, in order | `operational-context.md` |
| Container image: base image, build stages, run user, exposed port, entrypoint | `operational-context.md` |
| Hosting model, image registry, CDN in front of the app | `operational-context.md` |
| Monitoring and alerting wiring, and the trace sampling ratio per environment | `operational-context.md` |
| Rollback, written as steps someone runs | `runbooks.md` |
| Incident triage, scheduled operations, failure signatures, escalation path | `runbooks.md` |
| Direct dependency inventory, why each is present, lockfile situation, vendor risk | `dependencies.md` |
| Toolchain version floors: language runtime, package manager, SDK | `dependencies.md` |
| Framework and library version constraints ("v3, not v4") and the reason | `dependencies.md` |
| The command cheatsheet: every command a developer or agent runs, one row each | `onboarding.md` |
| First-day setup, local development workflow, contacts | `onboarding.md` |
| Every URL and access link: repository, environments, consoles, secret store, dashboards | `onboarding.md` |
| What each quality gate enforces, and where each tool config lives by path | `coding-standards.md` |
| Commit message convention and branch naming convention | `coding-standards.md` |
| Accessibility target | `coding-standards.md` |
| Testing conventions, review and PR expectations, fork discipline | `coding-standards.md` |
| Content model, editorial workflow, publish and preview behaviour | `cms.md` |
| Cache layers a published change passes, and how each is purged or revalidated | `cms.md` |
| Agents, skills, MCP servers and instruction files present now | `agent-registry.md` |

A topic that is genuinely not in this table gets one owner chosen by the same rule and written into
the owning file's §4 row in the same change. Do not resolve a gap by writing the fact into two
files.

### Ambiguities this table settles on purpose

These are the pairs that look like shared ownership and are not. Each was two files deep in a real
migrated repository.

- **Pipeline versus rollback.** `operational-context.md` describes the pipeline, including that
  there is no rollback stage and what redeploying a previous build actually means. `runbooks.md`
  carries rollback as steps. The description lives in one file, the procedure in the other, and
  neither repeats the other's half.
- **Environment variables versus the CMS.** Every variable, CMS variables included, is in
  `operational-context.md`. `cms.md` points at it. A second table filtered to CMS variables is a
  restatement.
- **Branch mapping versus branch convention.** The branch-to-environment-and-variable-group table
  is `operational-context.md`. `coding-standards.md` owns the branch *naming* convention and
  writes no environment table at all.
- **The command cheatsheet versus the quality gates.** Every command is listed once, in
  `onboarding.md`. `coding-standards.md` says what a gate enforces and names the command, and
  never re-lists the set. `AGENTS.md` may carry the two or three commands run on every task, as a
  block that names `onboarding.md`. Splitting the list by audience is how one project ended up
  with three copies that had already drifted.
- **Monitoring tooling versus monitored features.** `operational-context.md` owns the wiring and
  the sampling ratios. `project-context.md` owns which user flows are covered and by which test.

### The role of `AGENTS.md` and of skills, relative to this table

Neither is a place where `.ai/` facts get a second home.

**`AGENTS.md` is an index plus up to five constraint lines.** The index is the routing table saying
which `.ai/` file to read for which kind of task, and it carries no facts from those files. The
constraint lines are the §2 allowance: one line each, naming the owning `.ai/` file inline, only
for a rule that has to be seen before the agent writes rather than after it fails. Everything else
in `AGENTS.md` is a pointer. A summary of `.ai/` in `AGENTS.md` is a restatement however short it
is, because it goes stale silently and every harness reads it first.

**A skill body is how this project uses one technology**, with code copied from real call sites. It
owns nothing from this table. A global constraint an agent would otherwise break gets one
constraint line naming its `.ai/` owner, and nothing more: not the command list, not the version
floors, not the deploy model. The single exception is `codebase-overview`, whose generated block
is a script-maintained copy of four named sections of `architecture.md`; it cannot drift because
nobody hand-edits it, and its scope is those four sections only.

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
