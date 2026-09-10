# Confluence Page Layout Conventions

## Purpose

Keep every DEPT Managed Services handover page *look* the same, not just carry the same sections.

Two documents govern these pages and the split between them is strict:

| Document | Answers | Owns |
| --- | --- | --- |
| `docs/confluence-page-standard.md` | Which pages exist, which sections they carry, in what order | Page tree, titles, required sections, the `.ai/` to page mapping, the `.meta.yml` schema, diagram publishing |
| `docs/confluence-layout.md` (this file) | How a section is rendered once you know it belongs there | Block choice, heading depth, canonical table columns, code blocks, panels, prose budget, placeholders |

Neither file restates the other. When a section is missing from a page, that is a page-standard
question. When a section is present but reads as a wall of bullets, that is this file.

## Rule 0: pick the block from the shape of the content

This is the whole convention in one table. Apply it per section, before writing a word.

| The content is | Render it as | Never as |
| --- | --- | --- |
| Three or more facts with the same shape (one value per property, per environment, per package) | A table with a fixed column set (see below) | A bullet list of `Label: value` lines |
| Anything a person types into a terminal | A code block, one block per task | Inline code inside a paragraph, or a bullet ending in a command |
| An ordered procedure where step N depends on step N-1 | A numbered list, one action per step | A prose paragraph with "then" three times |
| Two or fewer facts, or a judgement that needs a reason | A sentence or two of prose | A one-row table |
| A short set of unrelated, non-parallel items (gotchas, risks, open questions) | A bullet list, one line each | A table with an empty second column |
| A fact that is not verified, or a value nobody confirmed yet | A placeholder in the cell or row that owns it, plus one warning panel per page at most | A prose caveat scattered per sentence |

The single most common defect is the first row: a section that should be a table written as bullets
of the form `Install: pnpm i`, `Run: pnpm dev`, `Test: pnpm test`. It scans badly, it hides an
omission (nobody notices a missing row), and it drifts the moment one project uses three bullets
and the next uses five.

## Headings

- **No `H1` in the body.** Confluence renders the page title above the body, so an `H1` repeating
  the project name is a duplicate title.
- **`H2` for the standard sections**, spelled exactly as `docs/confluence-page-standard.md` lists
  them. Same wording, same order, every project.
- **`H3` for sub-groupings inside a standard section**, when a section genuinely has parts (per
  package, per environment group, per issue). An `H3` that would hold one sentence is a bold lead
  line instead.
- **`H4` only inside Troubleshooting and Runbooks**, one per named symptom. Nowhere else.
- Sentence case for headings, and no emoji, numbering or trailing colons in a heading.
- No project-specific section before the standard ones. Extra sections go after, as `H2`.

## Canonical tables

Same table, same columns, every project. Deviating columns are what makes two pages look unrelated.

| Table | Page | Columns |
| --- | --- | --- |
| Key facts | Landing | `Property`, `Value` |
| Quick links | Landing | `Link`, `URL` |
| Key contacts | Landing | `Role`, `Name`, `Contact (email)` |
| Key features (monitored) | Overview | `Public ID`, `Type`, `Name`, `Description` |
| Major areas at a glance | Overview | `Area`, `Purpose`, `Notes` |
| Package and component inventory | Architecture | `Area`, `Type`, `Responsibility`, `Key dependencies` |
| URLs and endpoints | Environments | `Environment`, `Purpose`, `URL`, `Notes` |
| Environment variables | Environments | `Variable`, `Purpose`, `Where it is set` |
| Monitoring | Environments | `Signal`, `Tool`, `Where to look` |
| Local development workflow | Onboarding | `Task`, `Command`, `Notes` |
| Quality gates | Onboarding | `Gate`, `Command`, `When it runs` |
| Troubleshooting | Onboarding | `Symptom`, `Cause`, `Fix` |

Table rules:

- Header row is a real header row (`<th>`), never a bold first data row.
- One fact per cell. A cell holding two sentences plus a command belongs in two columns or a code
  block under the table.
- Commands inside a table cell are inline `<code>`. A multi-line command does not go in a table:
  put the table row's `Notes` cell to work and follow the table with the code block.
- Sort deliberately and say so when it is not obvious (alphabetical, environment promotion order,
  browser tests before API tests).
- Do not add a `Status` column to every table. Use it only where confirmation state is the point
  (contacts, links a project has not verified).

## Code blocks

- One block per task, preceded by one lead line that says what it does. A block with no lead line
  and a block per line of a five-command sequence are both wrong.
- Real commands, copied from `.ai/onboarding.md`. No invented flags, no `$` prompt prefix, no
  output pasted in unless the output is the point.
- Language tag matches the content (`bash`, `json`, `yaml`, `csharp`). The one exception is the
  Mermaid source block, which is deliberately not tagged `mermaid`; see
  `docs/confluence-page-standard.md` for why.
- Storage format uses the `code` macro, not `<pre>`:

  ```xml
  <ac:structured-macro ac:name="code" ac:schema-version="1">
    <ac:parameter ac:name="language">bash</ac:parameter>
    <ac:plain-text-body><![CDATA[pnpm install
  pnpm dev]]></ac:plain-text-body>
  </ac:structured-macro>
  ```

## Panels

Three macros, three jobs, nothing else:

| Macro | Use for | Limit |
| --- | --- | --- |
| `warning` | Content nobody has verified yet, or an action that breaks production if done wrong | One per page, at the top of the section it qualifies |
| `note` | Provenance of a synced artifact (which repository file owns it, when it was last synced) | One per synced artifact |
| `info` | A prerequisite the reader needs before the section makes sense | Rare, prefer a lead sentence |

No `tip`, no `success`, no nested panels, no panel holding a table, and no panel used for emphasis
that a plain sentence would carry.

## Prose, bullets and placeholders

- **Lead paragraph:** every `H2` opens with at most three sentences, then the structured block.
  A section that opens with eight sentences of prose is a section that has a table hiding in it.
- **Bullets:** one line each, no nesting past one level, at most seven per list. Past seven it is a
  table. A bullet that contains a colon followed by a value is a table row in disguise.
- **Placeholders:** `[To fill in]` in the cell that owns the unknown, never a paragraph explaining
  that something is unknown. Keep the row: a removed row is an invisible gap, a placeholder row is
  a visible task.
- **Mixed audience:** plain language first, then the specifics. An engineer skips a plain sentence
  faster than a client manager decodes a package name.

## Anti-patterns

| Anti-pattern | Why it fails | Do instead |
| --- | --- | --- |
| `Install: … / Run: … / Test: … / Build: …` as bullets | Parallel data as prose, and an omitted row (the commit convention) goes unnoticed | The `Task`, `Command`, `Notes` table, with a `Commit` row |
| Duplicate `H1` repeating the page title | Two titles, one page | Start at `H2` |
| A table per fact, or a one-row table | Table chrome for one value | A sentence |
| Command inside a bullet, mid-sentence | Not copyable, not scannable | Code block, or inline `<code>` in a table cell |
| Deep `H3`/`H4` nesting on Overview or Environments | Every project nests differently, so no two pages look alike | `H2` sections, `H3` only for real parts |
| Emoji headings, status badges, decorative panels | Reads as a personal page, not a standard one | Plain headings, a `Status` column where state matters |
| A prose paragraph restating a table that sits right under it | Two copies drift within one page | Table only, with a lead sentence |

## Applying this file

An agent writing or syncing these pages:

1. Reads `docs/confluence-page-standard.md` for which sections the page carries, in order.
2. For each section, applies Rule 0 to choose the block, and the canonical column set when it is a
   listed table.
3. Reuses the exact heading wording and column headers rather than paraphrasing them.
4. Names, in its final report, any section it rendered differently and why.
