# [PROJECT_NAME]

[PROJECT_SUMMARY]

<!-- Two sentences from project-context.md of the project context: what the system is and who it
serves. Never a summary of the context: every harness reads this file first, so a summary here goes
stale silently. -->

<!-- This is the wiring file of a project whose context has moved to the central context
repository. A project that still holds its own .ai/ folder uses AGENTS.template.md instead. What
may be written here is in standards/writing-rules.md section 3 and section 4. -->

This is the one authored instruction file in this repository. Every harness reads it: Claude Code
through the `@AGENTS.md` import in `CLAUDE.md`, Copilot on GitHub and in VS Code as agent
instructions, Codex and Cursor natively. There is no second copy to keep in sync.

## Setup

[SETUP_COMMANDS]

The full command list is in `onboarding.md` of the project context. The block above is the two or
three commands run on every task, not a second copy of that list.

## Project context

The context of this project (architecture, conventions, environments, deployment, runbooks,
onboarding) is not in this repository. It lives in the private repository
`dept/beno-dept-ms-agentic-context`, under `projects/[ORG]__[REPO]/.ai/`, and is maintained there.

- With the `ms-agentic-context` skill installed, use it: it finds the folder and says which file
  answers which question.
- Without the skill, keep one clone of that repository outside this one and read the files there:

  ```bash
  C=~/.cache/ms-agentic-context
  if [ ! -d "$C/.git" ]; then
    gh repo clone dept/beno-dept-ms-agentic-context "$C" -- --depth 1
  else
    git -C "$C" pull --quiet --ff-only
  fi
  ls "$C/projects/[ORG]__[REPO]/.ai"
  ```

  If the clone fails, the user has no access to that repository: say so and continue without the
  project context. Do not guess at it.
- When a `.ai/` folder is present in the working tree, an agent runtime placed a copy of the same
  context there. Read it. Never edit or commit it.

Do not load every file up front: read one when the task touches its area. A correction to the
context is a pull request on that repository, not a file here.

<!-- [ORG]__[REPO] is the GitHub owner and repository name joined by two underscores, the folder
name the central repository uses. The clone runs under the developer's own GitHub login, so it
works for anyone with read access to the central repository and for nobody else. -->

## Behaviour rules

1. Only infer facts from source code, config files, and CI/CD.
2. Never invent service names, endpoints, team members, or environment details.
3. If something is not found, say: `Unknown: not found in repository`.
4. Use bullet points and tables. Avoid filler language.

## Key constraints

[KEY_CONSTRAINTS_ONE_LINERS]

<!-- Same test and same form as in AGENTS.template.md, with the owning file named as a file of the
project context, for example: "Tailwind is v3, not v4: `dependencies.md` in the project context is
authoritative." -->

## When context is stale

The project context reflects the project as of its last maintenance run. If it contradicts the
code, the code wins: say so and say the context needs a maintenance run. Do not work around the
contradiction silently.
