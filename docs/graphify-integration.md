# Graphify Integration for DEPT Agentic Standards

## Bottom line

**Yes — Graphify is worth integrating into this project, and `/migrate` should attempt it by default in a non-blocking pre-pass.**

That is the best compromise between:
- a **single migration entry point** for users
- better structural discovery on large or messy repositories
- avoiding a brittle dependency that can derail the whole migration

In DEPT terms, the correct policy is:
1. `/migrate` tries Graphify first
2. Discovery uses `graphify-out/` as structural input when available
3. Discovery still verifies important claims against primary repo evidence
4. `.ai/` remains the durable operational support layer
5. migration continues if Graphify cannot be installed or run

---

## What Graphify actually does upstream

Based on the upstream Graphify repository (`safishamsi/graphify`, default branch `v8`):

### Core output in current CLI behavior
The current CLI flow is effectively two-step:
1. `graphify .`
2. `graphify cluster-only .`

The initial extraction writes:
- `graphify-out/graph.json`

The follow-up clustering/report step writes:
- `graphify-out/GRAPH_REPORT.md`
- `graphify-out/graph.html`

`graphify-out/cache/ast/` is expected cache output for AST extraction, especially on large repositories.

### Three-pass extraction model
Upstream `docs/how-it-works.md` describes:
1. **Code structure pass** — local tree-sitter/code analysis, no API calls
2. **Video/audio pass** — local transcription, no API calls
3. **Docs/papers/images pass** — Claude subagents, token-costing semantic extraction

So the precise claim is:
- **code extraction is local**
- **non-code semantic extraction may use Claude**

That means Graphify is useful, but it is **not** a universal “nothing leaves the machine” guarantee in every mode.

---

## Install methods from upstream

The upstream README currently recommends:

### Preferred
```bash
uv tool install graphifyy
graphify install
```

### Alternatives
```bash
pipx install graphifyy
graphify install
```

```bash
pip install graphifyy
graphify install
```

Important upstream notes:
- the PyPI package is **`graphifyy`** (double-y)
- the CLI command is still **`graphify`**
- upstream prefers **`uv tool install`** because it puts the CLI on PATH automatically
- **`pipx install`** is also a good isolated install path
- plain `pip install` can create PATH/interpreter mismatch issues and should be treated as a fallback, especially on macOS and Windows

For DEPT, that means our migration guidance should prefer:
1. `uv tool install graphifyy`
2. `pipx install graphifyy`
3. `python3 -m pip install --user graphifyy` as a last resort

---

## Why Graphify helps DEPT migration

Graphify is strongest where DEPT Discovery currently has to reconstruct structure from raw source files.

It is especially helpful for:
- large legacy repositories
- monorepos with unclear package boundaries
- projects with many cross-file relationships
- mixed corpora where code and docs need to be stitched together

In practice, the best DEPT fit is Phase 2 Discovery, especially for:
- `.ai/architecture.md`
- `.ai/project-context.md`
- `.ai/dependencies.md`
- structural portions of `.ai/agent-registry.md`

It can accelerate:
- service boundary identification
- dependency cluster discovery
- cross-file call path discovery
- hotspot detection
- prioritization of which raw files to inspect next

---

## What Graphify should not replace

Graphify is not the DEPT support layer.

Even when Graphify runs successfully, DEPT still needs explicit `.ai/` files for:
- runbooks
- escalation paths
- environment URLs
- onboarding
- deployment approvals
- operational constraints
- ownership and support nuance

Those are the things managed services teams and future agents need in durable markdown form.

So the policy is:
- **Graphify maps structure**
- **DEPT `.ai/` captures operational reality**

---

## Recommended DEPT policy

### Default migration behavior
`/migrate` should:
- attempt Graphify automatically before Discovery
- prefer `uv` for install when Graphify is absent
- fall back to `pipx` if `uv` is unavailable
- fall back to `python3 -m pip install --user graphifyy` if neither `uv` nor `pipx` is available
- create or update a root `.graphifyignore` when Graphify is used so obvious junk folders are excluded from the scan
- continue migration if Graphify cannot be installed or run
- ignore `graphify-out/` in Git by default unless a team explicitly chooses otherwise

### Discovery behavior
When `graphify-out/` exists, Discovery should read in this order:
1. `graphify-out/GRAPH_REPORT.md`
2. `graphify-out/graph.json` only when detailed structural verification is needed

### Verification rule
Graphify output is:
- **supplemental evidence**
- **read-only generated artifact**
- **valuable structural input**

But it is **not**:
- the source of truth
- a replacement for `.ai/`
- a reason to skip validation against actual repo files

---

## Why `/migrate` should attempt Graphify by default

Your UX goal is correct: users should not have to remember two different migration habits.

The best experience is:
- run `/migrate`
- let it try Graphify automatically
- let Discovery use the output if available
- still complete migration if Graphify is unavailable

That preserves:
- **one entry point**
- **higher-quality structural discovery when possible**
- **resilience when local environments are imperfect**

This is better than both extremes:
- better than making Graphify fully optional/manual every time
- safer than making Graphify a hard blocker

---

## Git hygiene

By default, DEPT should treat `graphify-out/` as generated local output.

Unless a team explicitly chooses to version it, `/migrate` or helper scripts should ensure:
```gitignore
graphify-out/
```

That keeps generated graph artifacts out of normal client commits while still allowing ad hoc local use.

## Graphify ignore hygiene

Upstream supports a root `.graphifyignore` file using `.gitignore` syntax, layered on top of `.gitignore`.

For DEPT migration, the bootstrap helper should ensure `.graphifyignore` exists when Graphify is used, with at least:

```gitignore
.history/
.ai/
graphify-out/
node_modules/
dist/
build/
.next/
coverage/
.turbo/
.cache/
.vercel/
```

Rationale:
- `.history/` often contains editor/AI scratch material that adds no structural value
- `.ai/` is DEPT-generated output and should not feed back into Graphify on reruns
- `graphify-out/` avoids recursive ingestion of prior Graphify output
- common build/cache directories reduce noise and runtime on large projects

---

## What this repository now implements

This repository now reflects the following policy:
- `README.md` explains that `/migrate` attempts Graphify automatically
- `prompts/migrate.prompt.md` describes the non-blocking Graphify pre-pass
- `prompts/02-discover.prompt.md` tells Discovery how to consume `graphify-out/` as structural working context and convert verified findings into durable `.ai/` files
- `agents/ai-project-discovery.agent.md` treats Graphify as structural input, not truth
- `scripts/graphify-bootstrap.sh` provides a helper for running Graphify before Discovery

**Important:** DEPT uses Graphify as a terminal/CLI pre-pass. For migration itself, the critical requirement is that the `graphify` CLI runs successfully. Upstream `graphify install` registers assistant-specific slash-command skills, which is useful for ongoing interactive use but is **not required** for the DEPT migration pre-pass.

---

## Final recommendation

**Yes, implement Graphify support here — but implement it as a default attempted pre-pass, not as a mandatory dependency.**

That gives DEPT the upside:
- better architecture discovery
- fewer brute-force scans
- better support for large repos

without taking on the downside of:
- migration brittleness
- over-trusting generated graphs
- replacing operational support docs with structural artifacts
