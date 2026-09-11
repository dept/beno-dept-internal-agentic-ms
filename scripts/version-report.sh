#!/usr/bin/env bash
# DEPT Agentic Standard: cross-project version report
# Usage: ./scripts/version-report.sh <project-dir> [more-project-dirs...]
#
# Reads standard_version from each project's .ai/.meta.yml and compares it against the CURRENT
# standard version in THIS repository's config/standard-version.yml. Use it to see which projects
# need refreshing after a version bump.
#
# scripts/validate.sh compares a project against its own vendored copy of the version file, which
# is a consistency check inside one project. This script is the one that knows what current means.
#
# Exit code is 1 when at least one project is behind, so it can gate a scheduled job.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="${REPO_DIR}/config/standard-version.yml"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <project-dir> [more-project-dirs...]"
  echo ""
  echo "Example: $(basename "$0") ~/work/*/"
  exit 1
fi

read_version_field() {
  # $1 = file, $2 = field name (version | standard_version)
  # A missing file or a missing field is an empty string and a success status. Without the
  # trailing `|| true`, grep's no-match exit code propagates through pipefail and set -e kills
  # the script inside the command substitution, with no error message.
  local file="$1" field="$2"
  [[ -f "$file" ]] || return 0
  grep -E "^[[:space:]]*${field}:" "$file" 2>/dev/null | head -1 \
    | sed "s/.*${field}:[[:space:]]*//; s/\"//g" | tr -d '[:space:]' || true
}

CURRENT_VERSION=$(read_version_field "$VERSION_FILE" "version")
if [[ -z "$CURRENT_VERSION" ]]; then
  echo -e "${RED}ERROR:${NC} no version found in ${VERSION_FILE}"
  exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DEPT Agentic Standard: version report${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "  Current standard: ${BLUE}${CURRENT_VERSION}${NC} (${VERSION_FILE})"
echo ""

printf '  %-40s %-12s %-12s %s\n' "PROJECT" "RECORDED" "CURRENT" "BEHIND"
printf '  %-40s %-12s %-12s %s\n' "----------------------------------------" "------------" "------------" "------"

BEHIND_COUNT=0
UNKNOWN_COUNT=0
OK_COUNT=0

for project in "$@"; do
  name=$(basename "$(cd "$project" 2>/dev/null && pwd || echo "$project")")
  recorded=$(read_version_field "${project}/.ai/.meta.yml" "standard_version")

  if [[ ! -d "$project" ]]; then
    printf '  %-40s %-12s %-12s %b\n' "$name" "-" "$CURRENT_VERSION" "${YELLOW}unknown (no such directory)${NC}"
    UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
  elif [[ -z "$recorded" ]] || [[ "$recorded" = "null" ]]; then
    printf '  %-40s %-12s %-12s %b\n' "$name" "none" "$CURRENT_VERSION" "${YELLOW}unknown (no .ai/.meta.yml version)${NC}"
    UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
  elif [[ "$recorded" = "$CURRENT_VERSION" ]]; then
    printf '  %-40s %-12s %-12s %b\n' "$name" "$recorded" "$CURRENT_VERSION" "${GREEN}no${NC}"
    OK_COUNT=$((OK_COUNT + 1))
  else
    oldest=$(printf '%s\n%s\n' "$recorded" "$CURRENT_VERSION" | sort -V | head -1)
    if [[ "$oldest" = "$recorded" ]]; then
      printf '  %-40s %-12s %-12s %b\n' "$name" "$recorded" "$CURRENT_VERSION" "${RED}yes${NC}"
      BEHIND_COUNT=$((BEHIND_COUNT + 1))
    else
      printf '  %-40s %-12s %-12s %b\n' "$name" "$recorded" "$CURRENT_VERSION" "${YELLOW}ahead${NC}"
      UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
    fi
  fi
done

echo ""
echo -e "  ${GREEN}${OK_COUNT} up to date${NC} | ${RED}${BEHIND_COUNT} behind${NC} | ${YELLOW}${UNKNOWN_COUNT} unknown${NC}"

if [[ "$BEHIND_COUNT" -gt 0 ]]; then
  echo -e "  ${YELLOW}Refresh a project with:${NC} bash scripts/install.sh <project-dir> --update"
  exit 1
fi
exit 0
