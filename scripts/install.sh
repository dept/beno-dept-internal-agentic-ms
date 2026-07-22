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
  "config/standard-version.yml|config/standard-version.yml"
  ".github/skills/confluence-axi/SKILL.md|templates/skills/confluence-axi/SKILL.md"
  ".github/skills/confluence-axi/references/setup.md|templates/skills/confluence-axi/references/setup.md"
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

# Mirror agents to Claude Code (.claude/agents/) so they are registered as
# invokable subagents at the NEXT Claude Code session start. Installing them here
# — before the migration session runs — is what lets Phase 2 dispatch a real
# Discovery subagent on the first run instead of falling back to the main thread.
#
# Claude Code subagent frontmatter is `name` + `description` only; the Copilot
# `tools:` line is dropped (Claude Code subagents inherit all tools). We transform
# the just-installed .github source (single source of truth) rather than shipping a
# duplicate body that could drift.
mirror_claude_agent() {
  local github_rel="$1"   # e.g. .github/agents/discovery.agent.md
  local claude_rel="$2"   # e.g. .claude/agents/discovery.md
  local github_dest="${TARGET_DIR}/${github_rel}"
  local claude_dest="${TARGET_DIR}/${claude_rel}"

  [[ -f "$github_dest" ]] || return 0

  if [[ -e "$claude_dest" && $UPDATE -ne 1 ]]; then
    echo -e "  ${YELLOW}⊘${NC} ${claude_rel} — already exists, skipping"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  mkdir -p "$(dirname "$claude_dest")"
  # Strip the Copilot-only `tools:` frontmatter line; keep name + description body.
  sed '/^tools:[[:space:]]*\[/d' "$github_dest" > "$claude_dest"

  if [[ $UPDATE -eq 1 ]]; then
    echo -e "  ${GREEN}↻${NC} ${claude_rel} (mirrored)"
    UPDATED=$((UPDATED + 1))
  else
    echo -e "  ${GREEN}✓${NC} ${claude_rel} (mirrored)"
    CREATED=$((CREATED + 1))
  fi
}

mirror_claude_agent ".github/agents/discovery.agent.md" ".claude/agents/discovery.md"
mirror_claude_agent ".github/agents/maintainer.agent.md" ".claude/agents/maintainer.md"

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
  ".claude/agents/discovery.md" \
  ".claude/agents/maintainer.md" \
  "scripts/graphify-bootstrap.sh" \
  "scripts/validate.sh" \
  ".github/skills/confluence-axi/SKILL.md"
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
