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
  ".github/agents/discovery.agent.md|agents/discovery.agent.md"
  ".github/agents/maintainer.agent.md|agents/maintainer.agent.md"
  "scripts/graphify-bootstrap.sh|scripts/graphify-bootstrap.sh"
)

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

  if [[ -e "$dest" && $UPDATE -ne 1 ]]; then
    echo -e "  ${YELLOW}⊘${NC} ${dest_rel} — already exists, skipping"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  if copy_local "$src_rel" "$dest"; then
    :
  else
    download_remote "$src_rel" "$dest"
  fi

  if [[ "$dest_rel" == scripts/*.sh ]]; then
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

echo ""
echo -e "${BLUE}── Verification ──${NC}"
for required in \
  ".github/prompts/migrate.prompt.md" \
  ".github/prompts/01-install.prompt.md" \
  ".github/prompts/02-discover.prompt.md" \
  ".github/prompts/03-integrate.prompt.md" \
  ".github/prompts/04-stack-tooling.prompt.md" \
  ".github/agents/discovery.agent.md" \
  ".github/agents/maintainer.agent.md" \
  "scripts/graphify-bootstrap.sh"
do
  if [[ ! -f "${TARGET_DIR}/${required}" ]]; then
    echo -e "${RED}ERROR:${NC} missing required file after install: ${required}"
    exit 1
  fi
done

if [[ ! -x "${TARGET_DIR}/scripts/graphify-bootstrap.sh" ]]; then
  echo -e "${RED}ERROR:${NC} scripts/graphify-bootstrap.sh is not executable"
  exit 1
fi

echo -e "  ${GREEN}✓${NC} bootstrap bundle present"
echo ""
echo -e "${BLUE}── Summary ──${NC}"
echo -e "  Created: ${GREEN}${CREATED}${NC}"
echo -e "  Updated: ${GREEN}${UPDATED}${NC}"
echo -e "  Skipped: ${YELLOW}${SKIPPED}${NC}"
echo ""
echo "Next: run /ms-migration in your AI tool from ${TARGET_DIR}."
echo "If your tool does not support slash prompts directly, open .github/prompts/migrate.prompt.md and follow it."
