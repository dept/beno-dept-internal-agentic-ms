#!/usr/bin/env bash
# Hands a freshly migrated project's context to the central context repository.
#
#   bash scripts/onboard-central.sh <org/repo> [--branch <b>] [--owners "@a @b"]
#                                   [--no-confluence-sync] [--dry-run]
#
# Run from the project root after Phases 1 to 4, while .ai/ (gitignored) and
# .agents/skills/codebase-overview/ are still in the working tree. It clones
# dept/beno-dept-ms-agentic-context into a temporary directory, imports both with the central
# repository's own scripts/ctx.sh, lists the project as state: final, adds a CODEOWNERS line and
# opens a pull request. --dry-run stops before the push and prints where the clone is.
set -euo pipefail

CENTRAL="${CENTRAL_REPO:-dept/beno-dept-ms-agentic-context}"
repo="" branch="" owners="" sync=true dry=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) branch="$2"; shift 2 ;;
    --owners) owners="$2"; shift 2 ;;
    --no-confluence-sync) sync=false; shift ;;
    --dry-run) dry=1; shift ;;
    -*) echo "onboard-central: unknown option $1" >&2; exit 2 ;;
    *) repo="$1"; shift ;;
  esac
done

if [[ ! "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
  echo "usage: onboard-central.sh <org/repo> [--branch <b>] [--owners \"@a @b\"] [--no-confluence-sync] [--dry-run]" >&2
  exit 2
fi
if [[ ! -f .ai/.meta.yml ]]; then
  echo "onboard-central: no .ai/.meta.yml here. Run from the project root after Phase 2." >&2
  exit 1
fi
if [[ -n "$(git ls-files .ai)" ]]; then
  echo "onboard-central: .ai/ is tracked in this repository, so it is a dual-period project." >&2
  echo "Cut it over with the checklist in the $CENTRAL README instead." >&2
  exit 1
fi
[[ -n "$branch" ]] || branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
[[ -n "$branch" ]] || branch="$(git rev-parse --abbrev-ref HEAD)"

slug="${repo/\//__}"
proj="$(pwd)"
work="$(mktemp -d)/central"

gh repo clone "$CENTRAL" "$work" -- --depth 1 --quiet
cd "$work"

if grep -q "^  - repo: ${repo}\$" projects.yml; then
  echo "onboard-central: $repo is already in $CENTRAL projects.yml, nothing to do." >&2
  exit 1
fi

git checkout -q -b "onboard/$slug"
bash scripts/ctx.sh import "$slug" "$proj"

printf '  - repo: %s\n    branch: %s\n    state: final\n    confluence_sync: %s\n' \
  "$repo" "$branch" "$sync" >> projects.yml

if [[ -n "$owners" ]]; then
  mkdir -p .github
  printf '/projects/%s/ %s\n' "$slug" "$owners" >> .github/CODEOWNERS
fi

git add projects.yml "projects/$slug"
[[ -f .github/CODEOWNERS ]] && git add .github/CODEOWNERS
git commit -q -m "feat: onboard $repo

Imported from a fresh migration with the DEPT standard (scripts/onboard-central.sh).
The project never tracked .ai/, so it starts in state: final."

if [[ $dry -eq 1 ]]; then
  git show --stat --format='%s' HEAD
  echo "Dry run: nothing pushed. Central clone with the commit: $work"
  exit 0
fi

git push -q -u origin "onboard/$slug"
gh pr create --repo "$CENTRAL" --base main --head "onboard/$slug" \
  --title "feat: onboard $repo" \
  --body "Context for \`$repo\` (branch \`$branch\`), produced by the DEPT standard migration and handed off with \`scripts/onboard-central.sh\`.

- \`projects/$slug/.ai/\` and \`projects/$slug/skills/codebase-overview/\` imported with \`scripts/ctx.sh import\`
- \`projects.yml\`: \`state: final\`, \`confluence_sync: $sync\`
- After merge: run *Maintain context* once for \`$repo\`."
