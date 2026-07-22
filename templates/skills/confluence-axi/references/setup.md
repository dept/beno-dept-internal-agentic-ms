# confluence-axi setup

One-time setup. The skill never does these automatically — auth needs user input and a secret. Walk the user through them, then re-run `npx -y confluence-axi space list` to confirm.

## 1. Prerequisites

Node >= 20 + `npx` (bundled with Node). No binary to install — `npx -y confluence-axi` fetches the CLI on demand. It calls the Confluence Cloud REST API directly; there is no `acli` dependency.

## 2. Authenticate

Two supported paths — pick one. Resolution order: `ATLASSIAN_API_TOKEN` env → OAuth session → stored API token.

### Option A — API token (recommended for DEPT: agents / CI / headless, and simplest for humans)

Mint a token at https://id.atlassian.com/manage-profile/security/api-tokens (must match the site whose pages you edit, e.g. `dept-nl.atlassian.net`). The token is read from **stdin only**, never as an argument:

```bash
echo -n "$TOKEN" | npx -y confluence-axi auth login --token \
  --site dept-nl.atlassian.net --email you@deptagency.com
```

For CI, set the token in the environment instead (it overrides any stored session):

```bash
export ATLASSIAN_API_TOKEN="<token>"
```

### Option B — browser OAuth (humans, interactive TTY)

OAuth needs **your own registered Atlassian 3LO app** — there is no shipped default client. Register an app, then:

```bash
export ATLASSIAN_AXI_OAUTH_CLIENT_ID="<your app client id>"   # plus the app secret, per the prompt
npx -y confluence-axi auth login
```

For DEPT handover the API-token path (Option A) is simpler; use OAuth only if you already have a registered app. See the package's `docs/auth.md` for registering an app, storage, and the threat model.

## 3. Verify

```bash
npx -y confluence-axi space list
# → lists spaces you can access (should include MS)
```

If it errors: check the token is for the right site, the email matches the token's account, and the account has access to the `MS` space.

## Notes

- Confluence page bodies are **storage format** (XHTML), not Markdown — convert before create/update. Markdown is stored literally, not converted.
- Server/Data Center (self-hosted) Confluence differs; this targets **Cloud** (`*.atlassian.net`).
- Jira is out of scope here — it's the separate `jira-axi` package.
