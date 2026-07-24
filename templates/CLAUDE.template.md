# Project Context — Claude Code

## Behaviour rules

1. Only infer facts from source code, config files, and CI/CD.
2. Never invent service names, endpoints, team members, or environment details.
3. If something is not found, say: `Unknown — not found in repository`.
4. Use bullet points and tables. Avoid filler language.

For sustained development or support work, use the Support Agent in `.github/agents/` — it loads project context automatically.
