#!/usr/bin/env bash
set -euo pipefail

# DEPT migration bootstrap installer.
#
# Purpose:
#   Install the local migration entrypoint files into a target project so the
#   user can immediately run /ms-migration without copy-pasting a long curl
#   sequence.
#
# Usage:
#   ./scripts/install.sh                  # install into current directory
#   ./scripts/install.sh /path/to/project # install into another repo
#   ./scripts/install.sh . --update       # overwrite existing installed files
#
# Remote usage without cloning this repo first:
#   bash <(command curl -fsSL \
#     https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/install.sh) .

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_DIR='.'
UPDATE=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
RAW_BASE="${DEPT_MS_RAW_BASE:-https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main}"
CREATED=0
SKIPPED=0
UPDATED=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [target-project-dir] [--update]

Install the DEPT /ms-migration bootstrap bundle into a target project.

Arguments:
  target-project-dir   Repository root to install into (default: current dir)
  --update             Overwrite already-installed files
  -h, --help           Show this help message

Examples:
  ./scripts/install.sh
  ./scripts/install.sh /path/to/project
  ./scripts/install.sh . --update
  bash <(command curl -fsSL ${RAW_BASE}/scripts/install.sh) .
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update)
      UPDATE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo -e "${RED}Unknown option:${NC} $1"
      usage
      exit 1
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

if [[ ! -d "$TARGET_DIR/.git" ]]; then
  echo -e "${YELLOW}WARNING:${NC} ${TARGET_DIR} does not look like a git repository root (.git/ not found)."
  echo -e "${YELLOW}Continuing anyway.${NC}"
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DEPT Migration Bootstrap Installer${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  Target: ${BLUE}${TARGET_DIR}${NC}"
if [[ -f "${REPO_DIR}/prompts/migrate.prompt.md" ]]; then
  echo -e "  Source: ${BLUE}local repo copy${NC}"
else
  echo -e "  Source: ${BLUE}${RAW_BASE}${NC}"
fi
echo ""

ARTIFACTS=(
  ".github/prompts/migrate.prompt.md|prompts/migrate.prompt.md"
  ".github/prompts/01-install.prompt.md|prompts/01-install.prompt.md"
  ".github/prompts/02-discover.prompt.md|prompts/02-discover.prompt.md"
  ".github/prompts/03-integrate.prompt.md|prompts/03-integrate.prompt.md"
  ".github/prompts/04-stack-tooling.prompt.md|prompts/04-stack-tooling.prompt.md"
  ".claude/commands/ms-migration.md|prompts/migrate.prompt.md"
  ".github/agents/discovery.agent.md|agents/discovery.agent.md"
  ".github/agents/maintainer.agent.md|agents/maintainer.agent.md"
  "scripts/graphify-bootstrap.sh|scripts/graphify-bootstrap.sh"
  "scripts/validate.sh|scripts/validate.sh"
  "scripts/mirror-claude.sh|scripts/mirror-claude.sh"
  "config/standard-version.yml|config/standard-version.yml"
  "standards/writing-rules.md|standards/writing-rules.md"
  ".agents/skills/confluence-axi/SKILL.md|templates/skills/confluence-axi/SKILL.md"
  ".agents/skills/confluence-axi/references/setup.md|templates/skills/confluence-axi/references/setup.md"
)

# Bootstrap-only artifacts: they exist to carry a project through its first migration and Phase 5
# of the migrate prompt offers to delete them afterwards. The migration entry point itself belongs
# here too: a migrated project runs a full re-run from the standards repository bootstrap, so the
# prompt and its /ms-migration command are dead weight in the slash-command palette.
# Reinstalling any of them on every version refresh would hand the clutter back permanently, so
# they are never created in a project that has already migrated (a `.ai/.meta.yml` exists) and
# --update never creates one that is absent.
# Everything else in ARTIFACTS is durable and always refreshed.
BOOTSTRAP_ONLY=(
  ".github/prompts/migrate.prompt.md"
  ".claude/commands/ms-migration.md"
  ".github/prompts/01-install.prompt.md"
  ".github/prompts/02-discover.prompt.md"
  ".github/prompts/03-integrate.prompt.md"
  ".github/prompts/04-stack-tooling.prompt.md"
  ".github/agents/discovery.agent.md"
  "scripts/graphify-bootstrap.sh"
)

MIGRATED=0
[[ -f "${TARGET_DIR}/.ai/.meta.yml" ]] && MIGRATED=1
# Newline-separated "dest_rel|reason" lines, not an array: bash 3.2 (the macOS default) errors on
# an empty array expansion under `set -u`.
BOOTSTRAP_SKIPPED=""

is_bootstrap_only() {
  local dest_rel="$1" entry
  for entry in "${BOOTSTRAP_ONLY[@]}"; do
    [[ "$entry" == "$dest_rel" ]] && return 0
  done
  return 1
}

was_bootstrap_skipped() {
  case "$BOOTSTRAP_SKIPPED" in
    *"$1|"*) return 0 ;;
  esac
  return 1
}

# Returns 0 (skip this artifact) with the reason printed and recorded, 1 (install it as usual).
skip_bootstrap() {
  local dest_rel="$1" dest="$2" reason=""

  is_bootstrap_only "$dest_rel" || return 1

  if [[ $MIGRATED -eq 1 ]]; then
    reason="project already migrated (.ai/.meta.yml present), bootstrap-only artifact"
  elif [[ $UPDATE -eq 1 && ! -e "$dest" ]]; then
    reason="bootstrap-only artifact absent in target, --update never creates one"
  else
    return 1
  fi

  echo -e "  ${YELLOW}⊘${NC} ${dest_rel} — skipped: ${reason}"
  BOOTSTRAP_SKIPPED="${BOOTSTRAP_SKIPPED}${dest_rel}|${reason}"$'\n'
  SKIPPED=$((SKIPPED + 1))
  return 0
}

copy_local() {
  local src_rel="$1"
  local dest="$2"
  local src="${REPO_DIR}/${src_rel}"

  [[ -f "$src" ]] || return 1
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  return 0
}

download_remote() {
  local src_rel="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  command curl -fsSL "${RAW_BASE}/${src_rel}" -o "$dest"
}

install_one() {
  local dest_rel="$1"
  local src_rel="$2"
  local dest="${TARGET_DIR}/${dest_rel}"

  if skip_bootstrap "$dest_rel" "$dest"; then
    return 0
  fi

  # The vendored version file is standard-owned bookkeeping, never hand-edited, and a stale
  # copy would make the drift check in validate.sh compare two equally stale numbers.
  # It is always refreshed, with or without --update.
  if [[ -e "$dest" && $UPDATE -ne 1 && "$dest_rel" != "config/standard-version.yml" ]]; then
    echo -e "  ${YELLOW}⊘${NC} ${dest_rel} — already exists, skipping"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  if copy_local "$src_rel" "$dest"; then
    :
  else
    download_remote "$src_rel" "$dest"
  fi

  if [[ "$dest_rel" == *.sh ]]; then
    chmod +x "$dest"
  fi

  if [[ -e "$dest" && $UPDATE -eq 1 ]]; then
    echo -e "  ${GREEN}↻${NC} ${dest_rel}"
    UPDATED=$((UPDATED + 1))
  else
    echo -e "  ${GREEN}✓${NC} ${dest_rel}"
    CREATED=$((CREATED + 1))
  fi
}

echo -e "${BLUE}── Installing bootstrap bundle ──${NC}"
for artifact in "${ARTIFACTS[@]}"; do
  dest_rel="${artifact%%|*}"
  src_rel="${artifact#*|}"
  install_one "$dest_rel" "$src_rel"
done

# Rebuild the Claude Code mirrors: `.claude/skills` as a symlink to `.agents/skills`, and one
# derived `.claude/agents/<name>.md` per `.github/agents/<name>.agent.md`. Neither is authored,
# so both are rebuilt on every run, with or without --update: that is what makes a refresh
# repair a mirror that drifted. Installing the agent mirrors here, before the migration session
# runs, is also what lets Phase 2 dispatch a real Discovery subagent on the first run.
#
# Bootstrap-only artifacts need no special case any more: a derived mirror exists exactly when
# its source does, so a project that removed the discovery agent in Phase 5 gets no mirror back.
echo ""
echo -e "${BLUE}── Claude Code mirrors ──${NC}"
if [[ -f "${REPO_DIR}/scripts/mirror-claude.sh" ]]; then
  bash "${REPO_DIR}/scripts/mirror-claude.sh" "$TARGET_DIR"
else
  bash "${TARGET_DIR}/scripts/mirror-claude.sh" "$TARGET_DIR"
fi
echo ""

# Stamp the freshly installed standard version into an existing .ai/.meta.yml, so a project
# that is re-installed or refreshed reports the version it actually runs, not the one its first
# migration wrote. No .meta.yml yet (first migration) means nothing to stamp: the Discovery Agent
# and scripts/scaffold.sh create it with the current version.
stamp_meta_version() {
  local meta="${TARGET_DIR}/.ai/.meta.yml"
  local version_file="${TARGET_DIR}/config/standard-version.yml"
  [[ -f "$meta" && -f "$version_file" ]] || return 0

  # `|| true` on every read: a no-match grep would otherwise propagate through pipefail and
  # set -e, killing the installer inside the command substitution with no error message.
  local version recorded
  version=$(grep -E '^[[:space:]]+version:' "$version_file" | head -1 \
    | sed 's/.*version:[[:space:]]*//; s/"//g' | tr -d '[:space:]' || true)
  [[ -n "$version" ]] || return 0

  grep -qE '^[[:space:]]*standard_version:' "$meta" || {
    echo -e "  ${YELLOW}⊘${NC} .ai/.meta.yml has no standard_version field, not stamping"
    return 0
  }

  recorded=$(grep -E '^[[:space:]]*standard_version:' "$meta" | head -1 \
    | sed 's/.*standard_version:[[:space:]]*//; s/"//g' | tr -d '[:space:]' || true)
  if [[ "$recorded" == "$version" ]]; then
    echo -e "  ${GREEN}✓${NC} .ai/.meta.yml already records standard ${version}"
    return 0
  fi

  sed -E "s|^([[:space:]]*standard_version:).*|\1 \"${version}\"|" "$meta" > "${meta}.tmp"
  mv "${meta}.tmp" "$meta"
  echo -e "  ${GREEN}↻${NC} .ai/.meta.yml standard_version: ${recorded:-unset} → ${version}"
  UPDATED=$((UPDATED + 1))
}

stamp_meta_version

echo ""
echo -e "${BLUE}── Verification ──${NC}"
for required in \
  ".github/prompts/migrate.prompt.md" \
  ".github/prompts/01-install.prompt.md" \
  ".github/prompts/02-discover.prompt.md" \
  ".github/prompts/03-integrate.prompt.md" \
  ".github/prompts/04-stack-tooling.prompt.md" \
  ".claude/commands/ms-migration.md" \
  ".github/agents/discovery.agent.md" \
  ".github/agents/maintainer.agent.md" \
  ".claude/agents/maintainer.md" \
  "scripts/graphify-bootstrap.sh" \
  "scripts/validate.sh" \
  "scripts/mirror-claude.sh" \
  "standards/writing-rules.md" \
  ".agents/skills/confluence-axi/SKILL.md" \
  ".claude/skills/confluence-axi/SKILL.md"
do
  if [[ ! -f "${TARGET_DIR}/${required}" ]]; then
    # A bootstrap-only artifact this run deliberately did not install is not a failure.
    if was_bootstrap_skipped "$required"; then
      continue
    fi
    echo -e "${RED}ERROR:${NC} missing required file after install: ${required}"
    exit 1
  fi
done

for script in scripts/graphify-bootstrap.sh scripts/mirror-claude.sh; do
  if [[ -f "${TARGET_DIR}/${script}" && ! -x "${TARGET_DIR}/${script}" ]]; then
    echo -e "${RED}ERROR:${NC} ${script} is not executable"
    exit 1
  fi
done

echo -e "  ${GREEN}✓${NC} bootstrap bundle present"
echo ""
echo -e "${BLUE}── Summary ──${NC}"
echo -e "  Created: ${GREEN}${CREATED}${NC}"
echo -e "  Updated: ${GREEN}${UPDATED}${NC}"
echo -e "  Skipped: ${YELLOW}${SKIPPED}${NC}"
if [[ -n "$BOOTSTRAP_SKIPPED" ]]; then
  echo ""
  echo -e "  ${YELLOW}Bootstrap-only artifacts not installed:${NC}"
  while IFS='|' read -r skipped_rel skipped_reason; do
    [[ -n "$skipped_rel" ]] || continue
    echo -e "    ⊘ ${skipped_rel} — ${skipped_reason}"
  done <<< "$BOOTSTRAP_SKIPPED"
  echo "  Nothing was deleted. Removing artifacts a project still has stays an explicit operator choice."
fi
echo ""
if [[ $MIGRATED -eq 1 ]]; then
  echo "Next: nothing. ${TARGET_DIR} has already migrated and its .ai/ context is refreshed."
  echo "A full re-run is started from the standards repository bootstrap, not from a vendored copy of the prompt."
else
  echo "Next: run /ms-migration in your AI tool from ${TARGET_DIR}."
  echo "If your tool does not support slash prompts directly, open .github/prompts/migrate.prompt.md and follow it."
fi
