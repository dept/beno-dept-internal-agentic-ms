# confluence-axi setup

One-time setup. The skill never does these automatically — auth needs user input and a secret. Walk the user through them, then re-run `npx -y confluence-axi space list` to confirm.

## 1. Prerequisites

Node >= 20 + `npx` (bundled with Node). No binary to install — `npx -y confluence-axi` fetches the CLI on demand. It calls the Confluence Cloud REST API directly; there is no `acli` dependency.

## 2. Authenticate

Two supported paths. **Browser OAuth (Option B) is the preferred path for DEPT handover work**; the API token (Option A) is the fallback for CI and headless runs. Either way the *user* logs in — the agent only verifies. Resolution order: `ATLASSIAN_API_TOKEN` env → OAuth session → stored API token.

### Option A — API token (CI / headless, or if you have no registered 3LO app)

Mint a token at https://id.atlassian.com/manage-profile/security/api-tokens (must match the site whose pages you edit, e.g. `dept-nl.atlassian.net`). The token is read from **stdin only**, never as an argument:

```bash
echo -n "$TOKEN" | npx -y confluence-axi auth login --token \
  --site dept-nl.atlassian.net --email you@deptagency.com
```

For CI, set the token in the environment instead (it overrides any stored session):

```bash
export ATLASSIAN_API_TOKEN="<token>"
```

### Option B — browser OAuth (preferred; humans, interactive TTY)

OAuth needs **your own registered Atlassian 3LO app** — there is no shipped default client. Register an app, then:

```bash
export ATLASSIAN_AXI_OAUTH_CLIENT_ID="<your app client id>"   # plus the app secret, per the prompt
npx -y confluence-axi auth login
```

Registering the app is a one-time cost per person; after that `auth login` is a browser click and the session refreshes itself, with no secret to paste into a terminal. Fall back to Option A only for CI, headless runs, or until the app is registered. See the package's `docs/auth.md` for registering an app, storage, and the threat model.

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
