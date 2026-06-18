#!/usr/bin/env bash
set -euo pipefail

# Run Graphify before DEPT Discovery.
#
# This keeps Graphify as a non-blocking accelerator:
# - if graphify is already installed, use it
# - otherwise prefer uv, then pipx, then python3 -m pip to install graphifyy
# - if install fails, exit non-zero so the caller can decide whether to continue
#
# Usage:
#   ./scripts/graphify-bootstrap.sh /path/to/project
#   ./scripts/graphify-bootstrap.sh . --update
#   ./scripts/graphify-bootstrap.sh . --wiki

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <project-dir> [graphify args...]"
  exit 1
fi

PROJECT_DIR="$1"
shift || true

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: project directory not found: $PROJECT_DIR"
  exit 1
fi

GRAPHIFY_RUNNER=(graphify)

ensure_graphify() {
  if command -v graphify >/dev/null 2>&1; then
    GRAPHIFY_RUNNER=(graphify)
    return 0
  fi

  echo "graphify not found; attempting install..."

  if command -v uv >/dev/null 2>&1; then
    echo "Installing with uv: uv tool install graphifyy"
    uv tool install graphifyy
    GRAPHIFY_RUNNER=(graphify)
    return 0
  fi

  if command -v pipx >/dev/null 2>&1; then
    echo "Installing with pipx: pipx install graphifyy"
    pipx install graphifyy
    GRAPHIFY_RUNNER=(graphify)
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    echo "Installing with Python user site: python3 -m pip install --user graphifyy"
    python3 -m pip install --user graphifyy
    GRAPHIFY_RUNNER=(python3 -m graphify)
    return 0
  fi

  cat <<'EOF'
ERROR: graphify command not found, and no supported installer is available.

Recommended install methods from upstream:
  uv tool install graphifyy
  pipx install graphifyy

Fallback (less preferred):
  python3 -m pip install --user graphifyy

After install, re-run this script.
EOF
  return 1
}

ensure_graphify

cd "$PROJECT_DIR"

EXTRA_ARGS=("$@")
if [[ ${#EXTRA_ARGS[@]} -eq 0 ]]; then
  EXTRA_ARGS=(--wiki)
fi

echo "Running Graphify in: $(pwd)"
echo "Command: ${GRAPHIFY_RUNNER[*]} . ${EXTRA_ARGS[*]}"

"${GRAPHIFY_RUNNER[@]}" . "${EXTRA_ARGS[@]}"

if [[ -f .gitignore ]]; then
  if ! grep -qx 'graphify-out/' .gitignore 2>/dev/null; then
    printf '\ngraphify-out/\n' >> .gitignore
    echo "Added graphify-out/ to .gitignore"
  fi
else
  printf 'graphify-out/\n' > .gitignore
  echo "Created .gitignore with graphify-out/"
fi

echo ""
echo "Graphify completed. If successful, Discovery can now consume:"
echo "  - graphify-out/GRAPH_REPORT.md"
echo "  - graphify-out/wiki/index.md"
echo "  - graphify-out/graph.json"
echo ""
echo "Next step: run Phase 2 Discovery"
echo "  @workspace /02-discover"
