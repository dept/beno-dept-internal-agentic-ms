# AGENTS.md: [PROJECT_NAME]

<!-- The wiring file of a project whose context has moved to the central context repository. It is
a pointer and nothing else: no summary, no commands, no constraints. Those live in the project
context, and a copy here is the one that drifts. A project that still holds its own .ai/ folder
uses AGENTS.template.md instead. [ORG]__[REPO] is the GitHub owner and repository name joined by
two underscores, the folder name the central repository uses. -->

The project context (architecture, conventions, commands, environments, runbooks, onboarding)
is not in this repository. It lives in `dept/beno-dept-ms-agentic-context`, under
`projects/[ORG]__[REPO]/.ai/`. Read it before your first edit or review.

- With the `ms-agentic-context` skill installed, use it: it says which file answers which question.
- Without the skill, read it from one clone outside this repository:

  ```bash
  C=~/.cache/ms-agentic-context
  if [ ! -d "$C/.git" ]; then
    gh repo clone dept/beno-dept-ms-agentic-context "$C" -- --depth 1
  else
    git -C "$C" pull --quiet --ff-only
  fi
  ls "$C/projects/[ORG]__[REPO]/.ai"
  ```

  If the clone fails (no `gh`, not logged in, or no access), say so and continue without the
  project context. Do not guess at it.
- A `.ai/` folder in the working tree is a copy an agent runtime placed there. Read it, never edit
  or commit it.

If the context contradicts the code, the code wins: say so. Corrections are a pull request on
`dept/beno-dept-ms-agentic-context`, not a file here.
