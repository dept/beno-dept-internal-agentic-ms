---
name: context-ownership
description: Use before writing or editing any `.ai/` context file, `AGENTS.md`, `CLAUDE.md`, or a skill body in this repository. Decides which single file owns the fact being written, and turns every other mention of it into a one-line pointer instead of a second copy. Apply it per section, not per file: it is what stops the same environment table, container image, version floor or command list from being written out in four places and drifting apart.
---

# Context ownership (one fact, one home)

Every fact in `.ai/` has exactly one owning file. Every other file that needs it carries a pointer.
This skill is the procedure for applying that. **The rule itself, the definition of a restatement,
the narrow allowance for a one-line constraint line, and the topic-to-file ownership map all live
in `standards/writing-rules.md` §2 and §4b.** This skill holds no copy of them on purpose: a second
copy of an ownership map is the exact defect the map exists to prevent, and it is the copy that
goes stale.

## When this applies

Any of: writing a new `.ai/` file, adding a section to an existing one, editing `AGENTS.md` or
`CLAUDE.md`, writing or editing a skill body, or reviewing a pull request that touches those files.

## The procedure, per section

1. **Name the fact in one sentence** before writing it. "The pipeline has eight stages." "The image
   is built from `node:22-alpine` and runs as a non-root user on port 3000." "Node must be at least
   22.11.0." A section you cannot reduce to a sentence is more than one fact: split it and run this
   procedure on each.

2. **Look the topic up in `standards/writing-rules.md` §4b.** That table maps a topic to its one
   owning file. §4 gives each file's full remit if §4b does not list your topic exactly.

3. **Are you in the owning file?**
   - **Yes:** write the section here, in full, with its evidence. This is the only place it is
     written out.
   - **No:** write a pointer, one line, naming the owner and its section, and nothing else. Or write
     nothing, which is often correct. Format: ``Environments: `operational-context.md` -> *Environments*.``

4. **Order the work.** Write every owning section first, then go back and write the pointers. A
   pointer written before its target exists ends up as a summary "for now", and the summary is what
   survives.

5. **Check the two tests in §2** on anything you wrote in a non-owning file. If the owning file
   changed tomorrow, would this text become wrong? Could a reader answer the question from this
   file alone without opening the owner? A yes to either means you wrote a restatement. Cut it back
   to the pointer.

## The one exception, and its exact shape

`AGENTS.md` and skill bodies may carry a **constraint line**: one line, stating the instruction,
naming the owning `.ai/` file inline, for a rule an agent has to see before it writes rather than
after it fails. `standards/writing-rules.md` §2 has the rule, the cap and what disqualifies a line
from being one. Two things to remember at the keyboard:

- No owner named in the line means it is a restatement, not a constraint line.
- Between two `.ai/` files there is no constraint line. A pointer, or nothing.

## Editing something that already exists

Adding a fact to a file that does not own it is a defect even when the fact is correct. If the fact
is already written out in two files, the owner gets the update and the other is cut back to a
pointer in the same change; `standards/writing-rules.md` §5 case 1 is the authority for removing
it, and no note is left saying it was removed.

## Before you finish

```bash
bash scripts/validate.sh .
```

Read the **Single-Source Integrity** section of the output. It fails on a `## ` heading claimed by
two `.ai/` files, which is two owners for one topic; `## Validation Questions` is mandated in every
file and is the only heading allowed to repeat. It warns on a command line repeated across files,
which is almost always the command cheatsheet growing a second copy. Clear every failure. Keep a
warning only when it is a deliberate constraint line or setup block that names its owner.
