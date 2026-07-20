# atlassian-axi setup

One-time setup. The skill never does these automatically — auth needs user input and a secret. Walk the user through them, then re-run `npx -y atlassian-axi confluence space list` to confirm.

## 1. Prerequisites

Node + `npx` (bundled with Node). No binary to install — `npx -y atlassian-axi` fetches the CLI on demand. Jira features shell out to Atlassian's official `acli`; Confluence uses the Cloud REST API directly (no `acli` needed for Confluence).

## 2. Authenticate

Two supported paths — pick one.

### Option A — browser OAuth (default for humans)

```bash
npx -y atlassian-axi auth login
```

Opens `auth.atlassian.com`, catches the callback on `http://localhost:8765/callback`, and stores rotating tokens in `~/.config/atlassian-axi/config.json` (mode 0600).

### Option B — API token (agents / CI / headless)

Mint a token at https://id.atlassian.com/manage-profile/security/api-tokens (site-scoped — must match the site whose pages you edit, e.g. `dept-nl.atlassian.net`). Then either log in with it:

```bash
echo -n "$TOKEN" | npx -y atlassian-axi auth login --token \
  --site dept-nl.atlassian.net --email you@deptagency.com
```

or export the env vars (persist in `~/.zshrc`, then `source ~/.zshrc`):

```bash
export ATLASSIAN_SITE="dept-nl.atlassian.net"     # no https://, no /wiki
export ATLASSIAN_EMAIL="you@deptagency.com"
export ATLASSIAN_API_TOKEN="<token>"
```

Credential resolution order: `ATLASSIAN_API_TOKEN` env → OAuth session → stored token.

## 3. Verify

```bash
npx -y atlassian-axi confluence space list
# → lists spaces you can access (should include MS)
```

If it errors: check the token is for the right site, the email matches the token's account, and the account has access to the `MS` space.

## Notes

- Confluence page bodies are **storage format** (XHTML), not Markdown — convert before create/update.
- Server/Data Center (self-hosted) Confluence differs; this targets **Cloud** (`*.atlassian.net`).
