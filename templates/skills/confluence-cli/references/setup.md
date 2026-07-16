# confluence-cli setup

One-time setup. The skill never does these automatically — they need user input and a secret. Walk the user through them, then re-run `bash confluence.sh me` to confirm.

## 1. Prerequisites

`curl` and `jq` (both standard on macOS / most Linux). No binary to install — this uses the Confluence Cloud REST API directly.

```bash
command -v jq || brew install jq
```

## 2. Create an Atlassian API token

The user must mint this themselves:

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. **Create API token**, copy the value.
3. This is a **site-scoped** token — it must be for the same Atlassian site whose pages you are editing (e.g. `dept-nl.atlassian.net`). A token for a different site (e.g. `asudev.jira.com`) will 401.

## 3. Export credentials

Persist in `~/.zshrc` so future shells (and agent tool calls) inherit them, then `source ~/.zshrc`:

```bash
export CONFLUENCE_SITE="https://dept-nl.atlassian.net"   # no trailing slash, no /wiki
export CONFLUENCE_EMAIL="you@deptagency.com"             # your Atlassian login email
export CONFLUENCE_TOKEN="<token from step 2>"
```

## 4. Verify

```bash
bash confluence.sh me
# → auth OK for you@deptagency.com @ https://dept-nl.atlassian.net
```

If it errors: check the token is for the right site, the email matches the token's account, and the account has access to the target space.

## Notes

- Auth is HTTP Basic with `email:api_token` (not the account password).
- `CONFLUENCE_SITE` is the site root; the helper appends `/wiki/rest/api`.
- Server/Data Center (self-hosted) Confluence uses a different base path and Personal Access Tokens instead of `email:token` — this skill targets **Cloud**.
