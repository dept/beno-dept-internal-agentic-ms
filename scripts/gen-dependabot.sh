#!/usr/bin/env bash
set -euo pipefail

# Generate .github/dependabot.yml for a project from its tracked lockfiles.
#
# Install-if-absent: it never overwrites an existing dependabot.yml, because
# projects hand-tune theirs (private registries, commit prefixes, custom
# groups). It only writes one when none exists yet.
#
# Detection is lockfile-driven, not manifest-driven: a package.json without a
# lockfile is not a real update target, and monorepos have a manifest per
# component which would otherwise produce dozens of noise directories.
#
# Usage:
#   ./scripts/gen-dependabot.sh [target-project-dir]   # default: current dir

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
DEST="${TARGET_DIR}/.github/dependabot.yml"

if [[ -f "$DEST" ]]; then
  echo "  ⊘ .github/dependabot.yml already exists, leaving it untouched"
  exit 0
fi

# Tracked files only: honours .gitignore, skips vendored trees. Needs a git repo.
if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "  ⊘ ${TARGET_DIR} is not a git work tree, skipping dependabot.yml"
  exit 0
fi

ls_files() { git -C "$TARGET_DIR" ls-files "$@" 2>/dev/null; }

# Map a list of file paths to their unique parent directories, as Dependabot
# `directory` values ("/" for repo root).
dirs_for() {
  awk -F/ '{ if (NF==1) print "/"; else { d=""; for (i=1;i<NF;i++) d=d"/"$i; print d } }' | sort -u
}

emit() {
  local eco="$1" dirs="$2" n
  n=$(printf '%s\n' "$dirs" | grep -c .)
  echo "  - package-ecosystem: $eco"
  if [[ "$n" -le 1 ]]; then
    echo "    directory: \"$dirs\""
  else
    echo "    directories:"
    printf '%s\n' "$dirs" | while read -r x; do [[ -n "$x" ]] && echo "      - \"$x\""; done
  fi
  echo "    schedule:"
  echo "      interval: weekly"
  # Package ecosystems land on Monday, actions on Tuesday. One ecosystem opening
  # pull requests per day keeps a slow pipeline from building every branch at once.
  if [[ "$eco" == "github-actions" ]]; then
    echo "      day: tuesday"
  else
    echo "      day: monday"
  fi
  echo "    open-pull-requests-limit: 3"
  # Dependabot rebases every open pull request when the base branch moves, and
  # each rebase re-runs the whole pipeline. Rebase on demand instead.
  echo "    rebase-strategy: disabled"
  if [[ "$eco" == "github-actions" ]]; then
    # Majors are not ignored here: an action pinned to a major that stopped
    # receiving fixes is the risk, and the blast radius is CI, not the product.
    # Grouped so a week of action bumps is one pull request, not one per action.
    echo "    groups:"
    echo "      actions:"
    echo "        patterns: [\"*\"]"
  else
    echo "    ignore:"
    echo "      - dependency-name: \"*\""
    echo "        update-types: [\"version-update:semver-major\"]"
    echo "    groups:"
    echo "      minor-and-patch:"
    echo "        update-types: [\"minor\", \"patch\"]"
  fi
}

# grep exits 1 on no matches; `|| true` keeps that from tripping set -e/pipefail.
npm=$(ls_files 'package-lock.json' '*/package-lock.json' 'yarn.lock' '*/yarn.lock' 'pnpm-lock.yaml' '*/pnpm-lock.yaml' | { grep -viE '/node_modules/' || true; } | dirs_for)
sln=$(ls_files '*.sln' | dirs_for)
csproj=$(ls_files '*.csproj' | dirs_for)
nuget="$sln"; [[ -z "$nuget" ]] && nuget="$csproj"
composer=$(ls_files 'composer.lock' '*/composer.lock' | dirs_for)
bundler=$(ls_files 'Gemfile.lock' '*/Gemfile.lock' | dirs_for)
docker=$(ls_files 'Dockerfile' '*/Dockerfile' | { grep -viE '/node_modules/' || true; } | dirs_for)
actions=$(ls_files '.github/workflows/*' | head -1)

if [[ -z "$npm$nuget$composer$bundler$docker$actions" ]]; then
  echo "  ⊘ no tracked lockfiles or workflows found, no dependabot.yml written"
  exit 0
fi

mkdir -p "${TARGET_DIR}/.github"
{
  echo "# Managed by MS. Enable Dependabot security updates org-wide separately (GitHub settings)."
  echo "# Targets from tracked lockfiles/solutions. Private feeds need a 'registries:' block + CI secrets."
  echo "version: 2"
  echo "updates:"
  [[ -n "$npm" ]]      && emit npm "$npm"
  [[ -n "$nuget" ]]    && emit nuget "$nuget"
  [[ -n "$composer" ]] && emit composer "$composer"
  [[ -n "$bundler" ]]  && emit bundler "$bundler"
  [[ -n "$docker" ]]   && emit docker "$docker"
  [[ -n "$actions" ]]  && emit github-actions "/"
} > "$DEST"

echo "  ✓ .github/dependabot.yml"
