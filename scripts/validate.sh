#!/usr/bin/env bash
# DEPT Agentic Standard — .ai/ Folder Validator
# Usage: ./scripts/validate.sh [path-to-project]
# Validates that a project's .ai/ folder meets the standard.

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
PROJECT_DIR="${1:-.}"
AI_DIR="${PROJECT_DIR}/.ai"
PASSED=0
WARNED=0
FAILED=0

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DEPT Agentic Standard — .ai/ Folder Validator${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

check_references() {
  local prefixes="$1"; shift
  local f hit line ref bad=0
  local files=()
  # bash 3.2 expands an empty array to an unbound variable under set -u.
  if [ "$#" -gt 0 ]; then files=("$@"); fi

  for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    while IFS= read -r hit; do
      line="${hit%%:*}"
      ref="${hit#*:}"
      ref="${ref#\`}"; ref="${ref%\`}"
      # Placeholders, globs, command lines and URLs are not paths to resolve.
      case "$ref" in
        *" "*|*"<"*|*">"*|*"*"*|*"{"*|*"$"*|*"|"*|*"://"*|*"..."*) continue ;;
      esac
      ref="${ref%/}"; ref="${ref%.}"; ref="${ref%,}"; ref="${ref%)}"
      [ -n "$ref" ] || continue
      # Only what the standard owns.
      local owned=0 p
      for p in $prefixes; do
        case "$ref" in "$p"|"$p"/*) owned=1; break ;; esac
      done
      [ "$owned" -eq 1 ] || continue
      # -e follows symlinks, so a mirror whose source is gone fails here too, which is the point.
      if [ ! -e "${PROJECT_DIR}/${ref}" ]; then
        echo -e "  ${RED}✗${NC} ${f#${PROJECT_DIR}/}:${line} names ${ref}, which does not exist"
        FAILED=$((FAILED + 1))
        bad=$((bad + 1))
      fi
    done < <(grep -no '`[^`]*`' "$f" 2>/dev/null || true)
  done

  if [ "$bad" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} every standard-owned path named in ${#files[@]} file(s) resolves"
    PASSED=$((PASSED + 1))
  fi
}


# Check .ai/ directory exists
if [ ! -d "$AI_DIR" ]; then
  # The standards repository itself has no .ai/: it produces one for other repositories. The
  # reference check is the only section that applies to it, and it applies to its own layout.
  # docs/ and examples/ are left out of the prefix list on purpose: a `docs/...` path in these
  # files is as likely to name a target project's docs or an upstream package's, and nothing
  # here can tell those apart from a path into this repository.
  if [ -f "${PROJECT_DIR}/standards/agentic-project-standard.md" ] && [ -f "${PROJECT_DIR}/config/standard-version.yml" ]; then
    echo -e "Validating the standards repository itself: ${BLUE}${PROJECT_DIR}${NC}"
    echo ""
    echo -e "${BLUE}── Reference Integrity ──${NC}"
    REPO_REF_FILES=()
    while IFS= read -r f; do REPO_REF_FILES+=("$f"); done < <(
      find "${PROJECT_DIR}" -name '*.md' -type f \
        -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/graphify-out/*' 2>/dev/null || true
    )
    if [ "${#REPO_REF_FILES[@]}" -gt 0 ]; then
      check_references \
        "agents config prompts scripts standards templates AGENTS.md CLAUDE.md README.md" \
        "${REPO_REF_FILES[@]}"
    fi
    echo ""
    if [ "$FAILED" -gt 0 ]; then
      echo -e "  Status: ${RED}${FAILED} broken reference(s)${NC}"
      exit 1
    fi
    echo -e "  Status: ${GREEN}ALL REFERENCES RESOLVE${NC}"
    exit 0
  fi
  echo -e "${RED}FAIL:${NC} No .ai/ directory found at ${AI_DIR}"
  echo -e "${YELLOW}Hint:${NC} Run the Discovery Agent or scripts/scaffold.sh first."
  exit 1
fi

echo -e "Validating: ${BLUE}${AI_DIR}${NC}"
echo ""

# ── 1. Required Files ──────────────────────────────────────
echo -e "${BLUE}── Required Files ──${NC}"
REQUIRED_FILES=(
  "project-context.md"
  "architecture.md"
  "runbooks.md"
  "dependencies.md"
  "cms.md"
  "operational-context.md"
  "coding-standards.md"
  "agent-registry.md"
  "onboarding.md"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "${AI_DIR}/${file}" ]; then
    echo -e "  ${GREEN}✓${NC} ${file}"
    ((PASSED++))
  else
    echo -e "  ${RED}✗${NC} ${file} — MISSING"
    ((FAILED++))
  fi
done

# Check recommended files
if [ -f "${AI_DIR}/.meta.yml" ]; then
  echo -e "  ${GREEN}✓${NC} .meta.yml (recommended)"
  ((PASSED++))
else
  echo -e "  ${YELLOW}△${NC} .meta.yml — missing (recommended for version tracking)"
  ((WARNED++))
fi

echo ""

# ── 2. Content Quality ─────────────────────────────────────
echo -e "${BLUE}── Content Quality ──${NC}"

for file in "${REQUIRED_FILES[@]}"; do
  filepath="${AI_DIR}/${file}"
  [ ! -f "$filepath" ] && continue

  issues=""

  # Check minimum content length
  line_count=$(wc -l < "$filepath" | tr -d ' ')
  if [ "$line_count" -lt 10 ]; then
    issues="${issues}  stub (${line_count} lines);"
  fi

  # Check for placeholder/TODO markers
  if grep -qiE '\[TODO\]|\{\{.*\}\}|\[PLACEHOLDER\]|FIXME' "$filepath" 2>/dev/null; then
    markers=$(grep -ciE '\[TODO\]|\{\{.*\}\}|\[PLACEHOLDER\]|FIXME' "$filepath" 2>/dev/null || echo "0")
    issues="${issues}  ${markers} placeholder(s);"
  fi

  # Check for headings
  if ! grep -q '^#' "$filepath" 2>/dev/null; then
    issues="${issues}  no headings;"
  fi

  if [ -z "$issues" ]; then
    echo -e "  ${GREEN}✓${NC} ${file} — OK"
    ((PASSED++))
  else
    echo -e "  ${YELLOW}△${NC} ${file} —${issues}"
    ((WARNED++))
  fi
done

echo ""

# ── 3. File-Specific Checks ────────────────────────────────
echo -e "${BLUE}── File-Specific Checks ──${NC}"

# architecture.md should have a mermaid diagram
if [ -f "${AI_DIR}/architecture.md" ]; then
  if grep -qi 'mermaid' "${AI_DIR}/architecture.md" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} architecture.md has diagram"
    ((PASSED++))
  else
    echo -e "  ${YELLOW}△${NC} architecture.md — no mermaid diagram found"
    ((WARNED++))
  fi
fi

# dependencies.md should have a table
if [ -f "${AI_DIR}/dependencies.md" ]; then
  if grep -q '|' "${AI_DIR}/dependencies.md" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} dependencies.md has table"
    ((PASSED++))
  else
    echo -e "  ${YELLOW}△${NC} dependencies.md — no table found (expected | delimiters)"
    ((WARNED++))
  fi
fi

# agent-registry.md should list at least one agent, skill, instruction file or MCP server.
# Checks for a table row naming a configured artifact, not for any one file: the artifacts a
# project has vary, and a check that names a specific file forces the file to be written about
# even after it is gone.
if [ -f "${AI_DIR}/agent-registry.md" ]; then
  if grep -qE '^\|.*(\.md|\.json|\.agents/|\.claude/|\.github/)' "${AI_DIR}/agent-registry.md" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} agent-registry.md lists configured agentic artifacts"
    ((PASSED++))
  else
    echo -e "  ${YELLOW}△${NC} agent-registry.md has no agent, skill, or MCP rows"
    ((WARNED++))
  fi
fi

# codebase-overview skill is generated from .ai/architecture.md. Warn when the source is newer
# than the generated copy. A warning, not a failure: a hand edit to either should not break CI.
if command -v git &>/dev/null && git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
  arch_ts=$(git -C "$PROJECT_DIR" log -1 --format=%ct -- ".ai/architecture.md" 2>/dev/null || echo "")
  skill_ts=$(git -C "$PROJECT_DIR" log -1 --format=%ct -- ".agents/skills/codebase-overview/SKILL.md" 2>/dev/null || echo "")
  if [ -n "$arch_ts" ] && [ -n "$skill_ts" ] && [ "$arch_ts" -gt "$skill_ts" ]; then
    echo -e "  ${YELLOW}△${NC} codebase-overview skill is older than .ai/architecture.md, regenerate it"
    ((WARNED++))
  fi
fi

echo ""

# ── 3b. Standard Version Drift ─────────────────────────────
# .ai/.meta.yml records the standard version the project runs; config/standard-version.yml is the
# copy the standard vendored in at install time. When the recorded version is older, the project
# needs a refresh. All warning-level: a missing version on either side is not a compliance failure.
echo -e "${BLUE}── Standard Version ──${NC}"

read_version_field() {
  # $1 = file, $2 = field name (version | standard_version)
  # A missing file or a missing field is an empty string and a success status. Without the
  # trailing `|| true`, grep's no-match exit code propagates through pipefail and set -e kills
  # the script inside the command substitution, with no error message.
  local file="$1" field="$2"
  [ -f "$file" ] || return 0
  grep -E "^[[:space:]]*${field}:" "$file" 2>/dev/null | head -1 \
    | sed "s/.*${field}:[[:space:]]*//; s/\"//g" | tr -d '[:space:]' || true
}

RECORDED_VERSION=$(read_version_field "${AI_DIR}/.meta.yml" "standard_version")
CURRENT_VERSION=$(read_version_field "${PROJECT_DIR}/config/standard-version.yml" "version")

if [ -z "$RECORDED_VERSION" ] || [ "$RECORDED_VERSION" = "null" ]; then
  echo -e "  ${YELLOW}△${NC} .ai/.meta.yml records no standard_version, cannot check for drift"
  ((WARNED++))
elif [ -z "$CURRENT_VERSION" ]; then
  echo -e "  ${YELLOW}△${NC} config/standard-version.yml missing or has no version, cannot check for drift"
  ((WARNED++))
elif [ "$RECORDED_VERSION" = "$CURRENT_VERSION" ]; then
  echo -e "  ${GREEN}✓${NC} standard ${CURRENT_VERSION} (matches config/standard-version.yml)"
  ((PASSED++))
else
  oldest=$(printf '%s\n%s\n' "$RECORDED_VERSION" "$CURRENT_VERSION" | sort -V | head -1)
  if [ "$oldest" = "$RECORDED_VERSION" ]; then
    echo -e "  ${YELLOW}△${NC} project is on standard ${RECORDED_VERSION}, current is ${CURRENT_VERSION}"
    echo -e "    ${YELLOW}Refresh:${NC} bash scripts/install.sh . --update"
    ((WARNED++))
  else
    echo -e "  ${YELLOW}△${NC} .ai/.meta.yml records standard ${RECORDED_VERSION}, ahead of the vendored ${CURRENT_VERSION}"
    ((WARNED++))
  fi
fi

echo ""

# ── 4. Staleness Check ─────────────────────────────────────
echo -e "${BLUE}── Staleness Check ──${NC}"

if command -v git &>/dev/null && git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
  # Get last commit date for .ai/ folder
  ai_last_commit=$(git -C "$PROJECT_DIR" log -1 --format="%ci" -- ".ai/" 2>/dev/null || echo "")
  repo_last_commit=$(git -C "$PROJECT_DIR" log -1 --format="%ci" 2>/dev/null || echo "")

  if [ -n "$ai_last_commit" ] && [ -n "$repo_last_commit" ]; then
    ai_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$ai_last_commit" +%s 2>/dev/null || date -d "$ai_last_commit" +%s 2>/dev/null || echo "0")
    repo_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$repo_last_commit" +%s 2>/dev/null || date -d "$repo_last_commit" +%s 2>/dev/null || echo "0")
    now_epoch=$(date +%s)

    if [ "$ai_epoch" -gt 0 ]; then
      age_days=$(( (now_epoch - ai_epoch) / 86400 ))
      drift_days=$(( (repo_epoch - ai_epoch) / 86400 ))

      if [ "$age_days" -gt 90 ]; then
        echo -e "  ${RED}✗${NC} .ai/ last updated ${age_days} days ago (critical: >90 days)"
        ((FAILED++))
      elif [ "$age_days" -gt 30 ]; then
        echo -e "  ${YELLOW}△${NC} .ai/ last updated ${age_days} days ago (warning: >30 days)"
        ((WARNED++))
      else
        echo -e "  ${GREEN}✓${NC} .ai/ last updated ${age_days} days ago"
        ((PASSED++))
      fi

      if [ "$drift_days" -gt 14 ]; then
        echo -e "  ${YELLOW}△${NC} Repo has ${drift_days} days of commits since last .ai/ update"
        ((WARNED++))
      fi
    fi
  else
    echo -e "  ${YELLOW}△${NC} No git history for .ai/ (new folder?)"
    ((WARNED++))
  fi
else
  echo -e "  ${YELLOW}△${NC} Not a git repo — skipping staleness check"
  ((WARNED++))
fi

echo ""

# ── 5. Multi-Client Wiring ─────────────────────────────────
# .ai/ is the shared source; each IDE needs its own pointer + mirror.
# All warning-level (△): a project may legitimately target a subset of IDEs.
echo -e "${BLUE}── Multi-Client Wiring ──${NC}"

# Context pointers. AGENTS.md is the one authored file, read by Copilot (GitHub and VS Code),
# Codex and Cursor. CLAUDE.md imports it for Claude Code.
declare -a WIRING=(
  "AGENTS.md|Copilot, Codex, Cursor"
  "CLAUDE.md|Claude Code"
)
for entry in "${WIRING[@]}"; do
  path="${entry%%|*}"; label="${entry##*|}"
  if [ -f "${PROJECT_DIR}/${path}" ]; then
    echo -e "  ${GREEN}✓${NC} ${path} (${label})"
    ((PASSED++))
  else
    echo -e "  ${YELLOW}△${NC} ${path} — missing (${label} won't auto-load .ai/)"
    ((WARNED++))
  fi
done

# CLAUDE.md imports AGENTS.md rather than repeating it.
if [ -f "${PROJECT_DIR}/CLAUDE.md" ]; then
  if grep -q '@AGENTS.md' "${PROJECT_DIR}/CLAUDE.md" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} CLAUDE.md imports AGENTS.md"
    ((PASSED++))
  else
    echo -e "  ${YELLOW}△${NC} CLAUDE.md has no @AGENTS.md import (instructions will drift)"
    ((WARNED++))
  fi
fi

# Skills moved to .agents/skills in standard 2.0.0. Flag the 1.x location if it survives.
if [ -d "${PROJECT_DIR}/.github/skills" ]; then
  echo -e "  ${YELLOW}△${NC} .github/skills exists (standard 1.x): move its skills to .agents/skills and delete it"
  ((WARNED++))
fi

# Mirror parity: .agents/skills is the skill source, .github/* the agent and prompt source;
# .claude/* and .cursor/* must mirror them.
# fn: warn if source dir has entries but a mirror is empty/absent.
# kind = "md" (count *.md files) or "dir" (count subdirs). Predicate is hardcoded
# per-kind so no glob pattern passes through word-splitting (which would expand vs cwd).
# -L follows symlinks: both Claude mirrors are symlinks (see the Claude Code mirrors section
# of standards/agentic-project-standard.md), and a symlinked directory is -type l, not -type d,
# so without -L a perfectly in-sync mirror counts as 0.
count_entries() {
  local dir="$1" kind="$2"
  # Missing dir → 0. Guard prevents find's exit-1 aborting the $(...) under set -e + pipefail.
  if [ ! -d "$dir" ]; then echo 0; return; fi
  case "$kind" in
    md)  find -L "$dir" -maxdepth 1 -mindepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ' ;;
    dir) find -L "$dir" -maxdepth 1 -mindepth 1 -type d      2>/dev/null | wc -l | tr -d ' ' ;;
  esac
}
check_mirror() {
  local src="$1" mirror="$2" kind="$3" what="$4"
  local src_n mir_n
  src_n=$(count_entries "${PROJECT_DIR}/${src}" "$kind")
  if [ "${src_n:-0}" -eq 0 ]; then return; fi  # nothing to mirror (if-guard: safe under set -e)
  mir_n=$(count_entries "${PROJECT_DIR}/${mirror}" "$kind")
  if [ "${mir_n:-0}" -ge "$src_n" ]; then
    echo -e "  ${GREEN}✓${NC} ${what}: ${src} (${src_n}) → ${mirror} (${mir_n})"
    ((PASSED++))
  else
    echo -e "  ${YELLOW}△${NC} ${what}: ${src} has ${src_n} but ${mirror} has ${mir_n:-0} — mirror out of sync"
    ((WARNED++))
  fi
}
check_mirror ".github/agents"  ".claude/agents"   md   "Agents"
check_mirror ".agents/skills"  ".claude/skills"   dir  "Skills (Claude)"
check_mirror ".github/prompts" ".claude/commands" md   "Commands (Claude)"
check_mirror ".github/prompts" ".cursor/commands" md   "Commands (Cursor)"

echo ""

# ── 6. Reference Integrity ─────────────────────────────────
# A path this standard names must exist. Broken references are how a layout change (a renamed
# agent, a mirror that became a symlink) survives in prose long after the files moved, and they
# are the one class of rot no other check here catches.
#
# Scope, deliberately narrow:
#   - only backticked tokens, which is how every path in these files is written
#   - only paths under directories the standard itself owns (PREFIXES below), so a project's own
#     src/ layout, npm package names, URLs and bare filenames are never guessed at
#   - only files the standard owns and that stay in the repo for good
# Scanned: the .ai/ files, the two wiring files and the skills, which are the durable context a
# human or an agent reads every day. Not scanned, on purpose:
#   - .github/prompts/ and .github/agents/, which describe files a later phase creates and name
#     paths in the standards repository itself (templates/, scripts/) that a target repo never has
#   - .vscode/ and .cursor/ MCP config, which a project may legitimately not use
# Those two classes cannot be told apart from a real reference mechanically. They are checked in
# the standards repository instead, where every path they name is a path in that repository.
echo -e "${BLUE}── Reference Integrity ──${NC}"

REF_FILES=()
while IFS= read -r f; do REF_FILES+=("$f"); done < <(
  find -L "${AI_DIR}" "${PROJECT_DIR}/.agents/skills" -name '*.md' -type f 2>/dev/null || true
  ls "${PROJECT_DIR}/AGENTS.md" "${PROJECT_DIR}/CLAUDE.md" 2>/dev/null || true
)
if [ "${#REF_FILES[@]}" -gt 0 ]; then
check_references \
  ".ai .agents .claude .github/agents .github/prompts scripts standards AGENTS.md CLAUDE.md" \
  "${REF_FILES[@]}"
fi

echo ""

# ── Summary ────────────────────────────────────────────────
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
TOTAL=$((PASSED + WARNED + FAILED))
echo -e "  Results: ${GREEN}${PASSED} passed${NC} | ${YELLOW}${WARNED} warnings${NC} | ${RED}${FAILED} failed${NC} (${TOTAL} checks)"

if [ "$FAILED" -gt 0 ]; then
  echo -e "  Status: ${RED}NOT COMPLIANT${NC}"
  echo -e "  ${YELLOW}Hint:${NC} Run the Discovery Agent to generate missing files."
  exit 1
elif [ "$WARNED" -gt 0 ]; then
  echo -e "  Status: ${YELLOW}COMPLIANT WITH WARNINGS${NC}"
  echo -e "  ${YELLOW}Hint:${NC} Run the Maintainer Agent to address warnings."
  exit 0
else
  echo -e "  Status: ${GREEN}FULLY COMPLIANT${NC}"
  exit 0
fi
