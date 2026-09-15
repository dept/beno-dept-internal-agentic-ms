# The Agentic Project Standard, and why it is landing in your repo

*For developers and leads on Managed Services projects. Copy into Slack, Confluence, or a PR
description. How it works technically is in the repo's `README.md`.*

## What it is

One standard shape for project context, plus the agents that create and maintain it.

- **`.ai/`**: nine markdown files in your repository holding the project's context. Architecture,
  stack, runbooks, dependencies, conventions, operational notes, onboarding. Written so an AI tool
  can consume it, and so a human can read it.
- **A Discovery Agent** that generates `.ai/` from the codebase, and a **Maintainer Agent** that
  opens a PR when code and context drift apart.
- **Wiring** (`AGENTS.md`, `CLAUDE.md`, agent and skill definitions) so Copilot, Claude Code,
  Cursor and Codex all read the same context instead of each team configuring its own.

No application code, dependencies or pipeline config change. It is documentation and config.

## Why we do this

Managed Services runs on continuity across engineers, squads and time zones. Today that continuity
lives in people's heads, in Slack threads, and in Confluence pages nobody trusts. Three drivers, two of
which we already pay for constantly:

1. **Every context handover starts from zero.** New engineer, takeover team, someone covering an
   incident at 2am on a project they touched once in March.
2. **AI assistance is unsafe without context.** An assistant that does not know the stack,
   conventions and sharp edges confidently suggests patterns the project does not use. Garbage
   context produces garbage suggestions, and reviewing those costs more than writing the code.
3. **24/7 support is coming, part of it from teams abroad.** Colleagues in other time zones will
   pick up projects they have never worked on, sometimes on the first night of their rotation. They
   cannot be onboarded by a chat with the squad that built it. What scales is context that is
   already written down, current, and in the same place in every project, so a new person is
   productive in hours instead of weeks.

Structured, versioned, in-repo context answers all three. It gives an AI assistant that knows
instead of guesses, and a new colleague a place to start instead of a person to interrupt.

## Why every MS project, not a pilot

The value is in it being the same everywhere:

- An engineer moving between projects does not relearn where things are documented.
- A takeover or transition into Managed Services goes from weeks of archaeology to reading one
  folder.
- Tooling, agents and future capabilities (incident triage, release readiness, change impact) can
  be built once and work on every project, because they can rely on the structure.

One project doing this well is a nice folder. Every project doing it is a delivery model.

## What it does not ask of you

- It does not force anyone to use AI. If half the team ignores the agents, the folder is still the
  best project documentation you have.
- It does not replace Confluence. Client-facing pages stay; `.ai/` is the developer and agent
  facing source, and the standard keeps the two consistent.
- It does not gate your pipeline. The validation script is a check, not a blocker, unless your
  team decides to wire it in.

## Your own agents, skills and MCP servers stay yours

The project team leads here, and the standard follows. If your project already has agents, skills
or MCP configuration, the migration keeps them.

- **Nothing of yours is replaced.** The migration reads existing files and merges. MCP
  configuration (`.mcp.json`, `.vscode/mcp.json`, `.cursor/mcp.json`) is read first and written back
  with your entries intact, and a skill you already have is recorded, not overwritten.
- **Automatic installation is for projects that have nothing yet.** Where the project has no skill
  or MCP server for a technology it clearly uses, the migration adds one: from the DEPT registry
  first, otherwise a vendor-published server from the public registry. Individual-account packages
  are skipped on purpose.
- **You are free to edit, add and delete.** A skill you write, tune or remove stays that way. A
  version refresh only rewrites files the standard itself installed, by exact path, so it cannot
  silently reach into your own agents and skills.

Treat what arrives as a starting floor, not a ceiling. A team that already has a good setup keeps
it and adds only the context folder.

## What runs automatically, and how often

The Maintainer Agent runs on a schedule in your repository: twice a month, on the 1st and the 15th
at 09:00 UTC, plus on demand from the Actions tab. Each run it does two things:

- **Checks the code against `.ai/`** and opens a PR only when something actually drifted. No drift,
  no PR, so it does not generate noise between real changes.
- **Updates your project's Confluence pages** under [Managed Services > Projects](https://dept-nl.atlassian.net/wiki/spaces/MS/pages/21252440077/Projects),
  based on what changed in the project. These are written directly rather than proposed, and only
  for sections that actually changed, so the handover pages follow the code instead of aging
  quietly.

The schedule and the cost limit live in your repository's workflow file, so your team can change
the cadence or pause it without asking anyone.

## Who owns what

| | Owned by | Meaning |
|---|---|---|
| The standard: templates, agents, prompts, scripts | Managed Services standards team, centrally in `dept-agentic-standards` | Versioned in `config/standard-version.yml`, with a changelog per release. Updates arrive as a PR you review. |
| Your `.ai/` content | Your project team | Central releases never rewrite it. Edit it by hand whenever you want. |
| Your maintainer workflow (schedule, budget) | Your project team | Deliberately not auto-updated, so a central release cannot change what your CI spends. |

Updates are always PRs. Nothing changes in your repository silently, and nothing is deleted by an
update.

Questions, bugs and "this is wrong for our project" go to the standards repo as an issue. A rule
that does not fit reality is a defect in the standard, not something to work around locally.

## What we ask

1. Review the `.ai/` content for factual errors when it first lands. You know the project. Wrong
   statements are the one thing worth blocking on.
2. Treat Maintainer Agent PRs like any other PR: review, merge, or reject with a reason.
3. Tell us when it gets in your way.

Details, installation and the update command: `README.md` in the standards repo. The formal
definition: `standards/agentic-project-standard.md`. The longer-term direction:
`docs/vision.md`.
