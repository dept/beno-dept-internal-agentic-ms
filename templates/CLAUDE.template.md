@AGENTS.md

<!-- AGENTS.md is the authored instruction file and Claude Code imports it above. Add a line below
only if it applies to Claude Code and to nothing else: a hook, a permission note, a Claude-specific
command. Anything true for every harness belongs in AGENTS.md, and anything about the project
itself belongs in .ai/.

This file is a real file, never a symlink to AGENTS.md: a write aimed at CLAUDE.md would follow the
link and overwrite AGENTS.md, and a Windows checkout without symlink support materialises the link
as a one-line text file holding the path, which silently loses the instructions. -->

Skills for this project are in `.agents/skills/`, which `.claude/skills` symlinks to.
