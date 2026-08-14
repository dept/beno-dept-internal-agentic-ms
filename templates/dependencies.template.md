# Dependencies Template

## Purpose
Provide a structured inventory of technical dependencies and their operational impact.

## Required Sections
- Runtime dependencies
- Build/test dependencies
- External services
- Version policy
- Upgrade and risk notes

If a package needs a note here, write only what is specific to this file's topic and to that
package. The package's purpose is in `architecture.md`.

## Writing rules

`standards/writing-rules.md` governs this file. Read it before writing. It is not restated here.

## Ownership header

The generated file opens with this block, immediately after the H1:

> **Owned by this file:** the direct dependency inventory with versions and why each is present,
> upgrade constraints, vendor and supply-chain risk, and the lockfile situation. This is the
> authoritative source.
> **Not carried here:** which package uses what for feature reasons (`architecture.md`); install
> commands (`onboarding.md`).

## Example Content
- Runtime: `next@14`, `contentful@10`
- External service: "Azure Key Vault for secret resolution"
- Package dependency note: "`apps/marketing-site` pins `contentful@10` because the edge middleware depends on its v10 response shape."

## Validation
- Are versions sourced from manifests?
- Are high-risk dependencies flagged?
- Does the file pass every rule in `standards/writing-rules.md`?

## Missing Information
- Unknown transitive dependency risks
- Missing EOL policy references
