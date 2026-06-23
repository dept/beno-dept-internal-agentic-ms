#!/usr/bin/env bash
# DEPT Agentic Standard — .ai/ Folder Scaffold
# Deterministic directory/file creation — no LLM required.
#
# This script creates the full .ai/ folder structure from templates,
# wires IDE configurations (Copilot, Claude Code, VS Code),
# and generates .meta.yml with project metadata.
#
# Usage:
#   ./scripts/scaffold.sh [project-dir] [--templates-dir /path/to/templates]
#
# Examples:
#   ./scripts/scaffold.sh                          # scaffold current dir
#   ./scripts/scaffold.sh /path/to/my-project      # scaffold a specific project
#   ./scripts/scaffold.sh . --templates-dir ~/dept-agentic-standards/templates
#
# The script is idempotent: existing files are never overwritten.

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ── Defaults ───────────────────────────────────────────────
PROJECT_DIR="."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="${REPO_DIR}/templates"
CONFIG_DIR="${REPO_DIR}/config"
CREATED=0
SKIPPED=0

# ── Argument Parsing ──────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --templates-dir)
      TEMPLATES_DIR="$2"
      shift 2
      ;;
    --config-dir)
      CONFIG_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [project-dir] [--templates-dir DIR] [--config-dir DIR]"
      echo ""
      echo "Scaffold the .ai/ folder structure for a project."
      echo ""
      echo "Arguments:"
      echo "  project-dir          Target project directory (default: current dir)"
      echo "  --templates-dir DIR  Path to dept-agentic-standards/templates/"
      echo "  --config-dir DIR     Path to dept-agentic-standards/config/"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help for usage information."
      exit 1
      ;;
    *)
      PROJECT_DIR="$1"
      shift
      ;;
  esac
done

AI_DIR="${PROJECT_DIR}/.ai"

# ── Banner ─────────────────────────────────────────────────
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DEPT Agentic Standard — Scaffold${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  Project:   ${BLUE}$(cd "$PROJECT_DIR" 2>/dev/null && pwd || echo "$PROJECT_DIR")${NC}"
echo -e "  Templates: ${BLUE}${TEMPLATES_DIR}${NC}"
echo ""

# ── Validate prerequisites ─────────────────────────────────
# Verify templates directory exists
if [ ! -d "$TEMPLATES_DIR" ]; then
  echo -e "${RED}ERROR:${NC} Templates directory not found: ${TEMPLATES_DIR}"
  echo -e "${YELLOW}Hint:${NC} Use --templates-dir /path/to/dept-agentic-standards/templates"
  exit 1
fi

# Verify project directory exists (or can be created)
if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${YELLOW}NOTE:${NC} Project directory does not exist, creating: ${PROJECT_DIR}"
  mkdir -p "$PROJECT_DIR"
fi

# ── Helper: copy file if it doesn't exist ──────────────────
# Idempotent copy — never overwrites existing files.
# Arguments: $1=source, $2=destination, $3=display label
copy_if_new() {
  local src="$1"
  local dest="$2"
  local label="$3"

  # Ensure parent directory exists
  mkdir -p "$(dirname "$dest")"

  if [ -f "$dest" ]; then
    echo -e "  ${YELLOW}⊘${NC} ${label} — already exists, skipping"
    SKIPPED=$((SKIPPED + 1))
  else
    cp "$src" "$dest"
    echo -e "  ${GREEN}✓${NC} ${label}"
    CREATED=$((CREATED + 1))
  fi
}

# ── 1. Create .ai/ directory and copy 9 required templates ─
echo -e "${BLUE}── Creating .ai/ structure ──${NC}"
mkdir -p "$AI_DIR"

# The 9 required .ai/ context files, mapping template → output name.
# Using parallel arrays for POSIX compatibility (no associative arrays).
TEMPLATE_NAMES=(
  "project-context.template.md"
  "architecture.template.md"
  "runbooks.template.md"
  "dependencies.template.md"
  "cms.template.md"
  "operational-context.template.md"
  "coding-standards.template.md"
  "agent-registry.template.md"
  "onboarding.template.md"
)

OUTPUT_NAMES=(
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

for i in "${!TEMPLATE_NAMES[@]}"; do
  template="${TEMPLATE_NAMES[$i]}"
  target="${OUTPUT_NAMES[$i]}"
  if [ -f "${TEMPLATES_DIR}/${template}" ]; then
    copy_if_new "${TEMPLATES_DIR}/${template}" "${AI_DIR}/${target}" ".ai/${target}"
  else
    echo -e "  ${RED}✗${NC} Template not found: ${template}"
  fi
done

echo ""

# ── 2. Generate .ai/.meta.yml ──────────────────────────────
# Fills in placeholders from the meta template with actual values:
#   - STANDARD_VERSION from config/standard-version.yml
#   - TIMESTAMP with current ISO 8601 UTC timestamp
#   - PROJECT_NAME from the target directory name
#   - AGENT_VERSION as "scaffold-1.0"
echo -e "${BLUE}── Generating .meta.yml ──${NC}"

META_FILE="${AI_DIR}/.meta.yml"
if [ -f "$META_FILE" ]; then
  echo -e "  ${YELLOW}⊘${NC} .ai/.meta.yml — already exists, skipping"
  SKIPPED=$((SKIPPED + 1))
else
  # Parse standard version from config (default fallback: 1.0.0)
  STANDARD_VERSION="1.0.0"
  VERSION_FILE="${CONFIG_DIR}/standard-version.yml"
  if [ -f "$VERSION_FILE" ]; then
    # Handles both quoted and unquoted version values:
    #   version: "1.0.0"  or  version: 1.0.0
    parsed=$(grep -E '^\s*version:' "$VERSION_FILE" | head -1 | sed 's/.*version:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//' | tr -d '[:space:]')
    if [ -n "$parsed" ]; then
      STANDARD_VERSION="$parsed"
    fi
  fi

  # ISO 8601 UTC timestamp
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Project name from directory basename
  PROJECT_NAME=$(basename "$(cd "$PROJECT_DIR" && pwd)")

  if [ -f "${TEMPLATES_DIR}/meta.template.yml" ]; then
    # Substitute placeholders in the meta template
    sed -e "s/{{STANDARD_VERSION}}/${STANDARD_VERSION}/g" \
        -e "s/{{AGENT_VERSION}}/scaffold-1.0/g" \
        -e "s/{{TIMESTAMP}}/${TIMESTAMP}/g" \
        -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
        "${TEMPLATES_DIR}/meta.template.yml" > "$META_FILE"
  else
    # Fallback: generate meta file inline if template is missing
    cat > "$META_FILE" << EOF
# .ai/.meta.yml — Auto-generated by scaffold.sh
# This file tracks provenance and standard compliance.

meta:
  standard_version: "${STANDARD_VERSION}"
  generated_by: "scaffold-1.0"
  generated_at: "${TIMESTAMP}"
  last_maintained: null
  last_maintained_by: null
  project_name: "${PROJECT_NAME}"
  files_generated:
    - project-context.md
    - architecture.md
    - runbooks.md
    - dependencies.md
    - cms.md
    - operational-context.md
    - coding-standards.md
    - agent-registry.md
    - onboarding.md
  validation:
    last_validated: null
    result: null
    issues: []
EOF
  fi
  echo -e "  ${GREEN}✓${NC} .ai/.meta.yml (v${STANDARD_VERSION})"
  CREATED=$((CREATED + 1))
fi

echo ""

# ── 3. Wire IDE configurations ─────────────────────────────
# These files instruct AI coding assistants to read the .ai/ folder.
echo -e "${BLUE}── Wiring IDE configurations ──${NC}"

# GitHub Copilot — custom instructions
if [ -f "${TEMPLATES_DIR}/copilot-instructions.template.md" ]; then
  copy_if_new "${TEMPLATES_DIR}/copilot-instructions.template.md" \
    "${PROJECT_DIR}/.github/copilot-instructions.md" \
    ".github/copilot-instructions.md"
else
  echo -e "  ${YELLOW}△${NC} copilot-instructions.template.md not found — skipping"
fi

# Claude Code — CLAUDE.md project instructions
if [ -f "${TEMPLATES_DIR}/CLAUDE.template.md" ]; then
  copy_if_new "${TEMPLATES_DIR}/CLAUDE.template.md" \
    "${PROJECT_DIR}/CLAUDE.md" \
    "CLAUDE.md"
else
  echo -e "  ${YELLOW}△${NC} CLAUDE.template.md not found — skipping"
fi

# VS Code / GitHub Copilot Chat — ai-context instructions
if [ -f "${TEMPLATES_DIR}/ai-context.instructions.template.md" ]; then
  copy_if_new "${TEMPLATES_DIR}/ai-context.instructions.template.md" \
    "${PROJECT_DIR}/.github/instructions/ai-context.instructions.md" \
    ".github/instructions/ai-context.instructions.md"
else
  echo -e "  ${YELLOW}△${NC} ai-context.instructions.template.md not found — skipping"
fi

echo ""

# ── 4. Copy agent templates ────────────────────────────────
# Optional agent definition files for GitHub Copilot Agents.
echo -e "${BLUE}── Agent templates ──${NC}"

if [ -f "${TEMPLATES_DIR}/agents/support-agent.template.md" ]; then
  copy_if_new "${TEMPLATES_DIR}/agents/support-agent.template.md" \
    "${PROJECT_DIR}/.github/agents/support-agent.md" \
    ".github/agents/support-agent.md"
else
  echo -e "  ${YELLOW}△${NC} No agent templates found — skipping"
fi

echo ""

# ── Summary ────────────────────────────────────────────────
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}${CREATED} files created${NC} | ${YELLOW}${SKIPPED} skipped${NC} (already existed)"
echo ""
echo -e "  ${BLUE}Next steps:${NC}"
echo -e "  1. Run the ${GREEN}Discovery Agent${NC} to fill templates"
echo -e "     with real project data (architecture, dependencies, etc.)"
echo -e "  2. Review and commit the generated .ai/ folder"
echo -e "  3. Run ${GREEN}scripts/validate.sh ${PROJECT_DIR}${NC} to verify compliance"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
