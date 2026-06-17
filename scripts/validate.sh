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

# Check .ai/ directory exists
if [ ! -d "$AI_DIR" ]; then
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

# agent-registry.md should reference discovery agent
if [ -f "${AI_DIR}/agent-registry.md" ]; then
  if grep -qi 'discovery' "${AI_DIR}/agent-registry.md" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} agent-registry.md references Discovery Agent"
    ((PASSED++))
  else
    echo -e "  ${YELLOW}△${NC} agent-registry.md — no Discovery Agent reference"
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
