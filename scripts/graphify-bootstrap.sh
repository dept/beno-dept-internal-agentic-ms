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
#   ./scripts/graphify-bootstrap.sh .

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

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

GRAPHIFY_RUNNER=(graphify)
TEMP_GRAPHIFYIGNORE_MARKER_BEGIN="# --- DEPT graphify no-LLM fallback: begin ---"
TEMP_GRAPHIFYIGNORE_MARKER_END="# --- DEPT graphify no-LLM fallback: end ---"
NO_LLM_CODE_ONLY_MODE=0

load_graphify_env() {
  local env_file loaded_any=0

  for env_file in \
    "$PROJECT_DIR/.env" \
    "$PROJECT_DIR/.env.local" \
    "$PROJECT_DIR/.env.graphify" \
    "$PROJECT_DIR/.env.graphify.local"
  do
    if [[ -f "$env_file" ]]; then
      set -a
      # shellcheck disable=SC1090
      if source "$env_file"; then
        echo "Loaded Graphify environment from ${env_file#$PROJECT_DIR/}"
        loaded_any=1
      else
        echo "WARNING: failed to source ${env_file#$PROJECT_DIR/}; continuing with existing environment" >&2
      fi
      set +a
    fi
  done

  return $loaded_any
}

graphify_package_spec() {
  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    printf '%s' 'graphifyy[openai]'
  elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    printf '%s' 'graphifyy[anthropic]'
  elif [[ -n "${GOOGLE_API_KEY:-}" || -n "${GEMINI_API_KEY:-}" ]]; then
    printf '%s' 'graphifyy[gemini]'
  else
    printf '%s' 'graphifyy'
  fi
}

graphify_backend_module() {
  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    printf '%s' 'openai'
  elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    printf '%s' 'anthropic'
  elif [[ -n "${GOOGLE_API_KEY:-}" || -n "${GEMINI_API_KEY:-}" ]]; then
    printf '%s' 'google.genai'
  else
    printf '%s' ''
  fi
}

has_graphify_llm_key() {
  [[ -n "${GOOGLE_API_KEY:-}" ]] || \
  [[ -n "${GEMINI_API_KEY:-}" ]] || \
  [[ -n "${ANTHROPIC_API_KEY:-}" ]] || \
  [[ -n "${OPENAI_API_KEY:-}" ]] || \
  [[ -n "${MOONSHOT_API_KEY:-}" ]] || \
  [[ -n "${DEEPSEEK_API_KEY:-}" ]]
}

repo_has_semantic_files() {
  find "$PROJECT_DIR" \
    \( -path '*/.git/*' -o -path '*/node_modules/*' -o -path '*/dist/*' -o -path '*/build/*' -o -path '*/.next/*' -o -path '*/coverage/*' \) -prune -o \
    -type f \( \
      -iname '*.md' -o -iname '*.markdown' -o -iname '*.mdx' -o \
      -iname '*.pdf' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \
    \) -print -quit | grep -q .
}

ensure_graphifyignore() {
  local ignore_file entry added_any=0
  ignore_file="$PROJECT_DIR/.graphifyignore"

  if [[ ! -f "$ignore_file" ]]; then
    cat > "$ignore_file" <<'EOF'
# Additional Graphify excludes for DEPT migration pre-pass.
# Graphify already respects .gitignore; this file narrows the scan further.
.history/
.ai/
graphify-out/
node_modules/
dist/
build/
.next/
coverage/
.turbo/
.cache/
.vercel/
EOF
    echo "Created .graphifyignore with DEPT defaults"
    return 0
  fi

  for entry in \
    .history/ \
    .ai/ \
    graphify-out/ \
    node_modules/ \
    dist/ \
    build/ \
    .next/ \
    coverage/ \
    .turbo/ \
    .cache/ \
    .vercel/
  do
    if ! grep -qxF "$entry" "$ignore_file" 2>/dev/null; then
      printf '%s\n' "$entry" >> "$ignore_file"
      added_any=1
    fi
  done

  if [[ $added_any -eq 1 ]]; then
    echo "Updated .graphifyignore with missing DEPT defaults"
  fi
}

remove_temp_no_llm_exclusions() {
  local ignore_file="$PROJECT_DIR/.graphifyignore"

  [[ -f "$ignore_file" ]] || return 0
  python3 - <<'PY' "$ignore_file" "$TEMP_GRAPHIFYIGNORE_MARKER_BEGIN" "$TEMP_GRAPHIFYIGNORE_MARKER_END"
from pathlib import Path
import sys

path = Path(sys.argv[1])
begin = sys.argv[2]
end = sys.argv[3]
text = path.read_text(encoding='utf-8')
marker_block = f"\n{begin}\n"
start = text.find(marker_block)
if start == -1:
    if text.startswith(begin + "\n"):
        start = 0
    else:
        raise SystemExit(0)
end_idx = text.find("\n" + end, start)
if end_idx == -1:
    raise SystemExit(0)
end_idx = text.find("\n", end_idx + 1)
if end_idx == -1:
    end_idx = len(text)
updated = (text[:start] + text[end_idx:]).rstrip()
if updated:
    updated += "\n"
path.write_text(updated, encoding='utf-8')
PY
}

enable_no_llm_code_only_mode() {
  local ignore_file="$PROJECT_DIR/.graphifyignore"

  ensure_graphifyignore
  remove_temp_no_llm_exclusions

  cat >> "$ignore_file" <<EOF

$TEMP_GRAPHIFYIGNORE_MARKER_BEGIN
# Added temporarily by scripts/graphify-bootstrap.sh so Graphify can run
# without an LLM API key. Remove this block (or rerun with a key) when you
# want Graphify to include docs, papers, and images again.
**/*.md
**/*.markdown
**/*.mdx
**/*.pdf
**/*.png
**/*.jpg
**/*.jpeg
**/*.webp
**/*.gif
$TEMP_GRAPHIFYIGNORE_MARKER_END
EOF

  NO_LLM_CODE_ONLY_MODE=1
}

cleanup_graphify_bootstrap() {
  if [[ "$NO_LLM_CODE_ONLY_MODE" -eq 1 ]]; then
    remove_temp_no_llm_exclusions
  fi
}

ensure_graphify() {
  local package_spec
  package_spec="$(graphify_package_spec)"

  if command -v graphify >/dev/null 2>&1; then
    GRAPHIFY_RUNNER=(graphify)
    return 0
  fi

  echo "graphify not found; attempting install..."

  if command -v uv >/dev/null 2>&1; then
    echo "Installing with uv: uv tool install $package_spec"
    uv tool install "$package_spec"
    GRAPHIFY_RUNNER=(graphify)
    return 0
  fi

  if command -v pipx >/dev/null 2>&1; then
    echo "Installing with pipx: pipx install $package_spec --force"
    pipx install "$package_spec" --force
    GRAPHIFY_RUNNER=(graphify)
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    echo "uv not found and pipx not found; installing pipx first via python3 -m pip install --user pipx"
    python3 -m pip install --user pipx
    if python3 -m pipx --version >/dev/null 2>&1; then
      echo "Installing with pipx module: python3 -m pipx install $package_spec --force"
      python3 -m pipx install "$package_spec" --force
      if command -v graphify >/dev/null 2>&1; then
        GRAPHIFY_RUNNER=(graphify)
        return 0
      fi
    fi

    echo "Falling back to Python user site: python3 -m pip install --user $package_spec"
    python3 -m pip install --user "$package_spec"
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

install_graphify_backend_dependency_if_needed() {
  local package_spec backend_module graphify_path graphify_python
  package_spec="$(graphify_package_spec)"
  backend_module="$(graphify_backend_module)"

  [[ -n "$backend_module" ]] || return 0
  command -v graphify >/dev/null 2>&1 || return 0

  graphify_path="$(command -v graphify)"
  graphify_python="$(python3 - <<'PY' "$graphify_path"
from pathlib import Path
import sys
p = Path(sys.argv[1])
try:
    first = p.read_text(errors='ignore').splitlines()[0]
except Exception:
    print('')
    raise SystemExit
print(first[2:].strip() if first.startswith('#!') else '')
PY
)"

  if [[ -n "$graphify_python" ]] && [[ -x "$graphify_python" ]] && "$graphify_python" - <<'PY' "$backend_module" >/dev/null 2>&1
import importlib.util, sys
sys.exit(0 if importlib.util.find_spec(sys.argv[1]) else 1)
PY
  then
    return 0
  fi

  echo "graphify is installed but missing backend dependency '$backend_module'; reinstalling with $package_spec"

  if command -v uv >/dev/null 2>&1; then
    uv tool install "$package_spec" --force
    return 0
  fi

  if command -v pipx >/dev/null 2>&1; then
    pipx install "$package_spec" --force
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    if python3 -m pipx --version >/dev/null 2>&1; then
      python3 -m pipx install "$package_spec" --force
      return 0
    fi
    python3 -m pip install --user "$package_spec"
    return 0
  fi
}

load_graphify_env || true
ensure_graphify
install_graphify_backend_dependency_if_needed

cd "$PROJECT_DIR"

ensure_graphifyignore

if ! has_graphify_llm_key && repo_has_semantic_files; then
  cat <<'EOF'
No supported Graphify LLM API key detected.

Continuing in code-only fallback mode:
- code extraction will still run
- docs / papers / images will be excluded for this run only

For full semantic extraction, set one of:
  GOOGLE_API_KEY or GEMINI_API_KEY
  ANTHROPIC_API_KEY
  OPENAI_API_KEY
  MOONSHOT_API_KEY
  DEEPSEEK_API_KEY

Tip: put the key in .env, .env.local, .env.graphify, or .env.graphify.local,
or export it in your shell before running this helper.
EOF
  enable_no_llm_code_only_mode
fi

trap cleanup_graphify_bootstrap EXIT

EXTRA_ARGS=("$@")

run_graphify() {
  # Wrapped with `|| true` at call sites so a non-zero exit (e.g. a semantic
  # backend failure) does not abort the script under `set -e` before salvage.
  if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    "${GRAPHIFY_RUNNER[@]}" . "${EXTRA_ARGS[@]}"
  else
    "${GRAPHIFY_RUNNER[@]}" .
  fi
}

echo "Running Graphify in: $(pwd)"
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  echo "Command: ${GRAPHIFY_RUNNER[*]} . ${EXTRA_ARGS[*]}"
else
  echo "Command: ${GRAPHIFY_RUNNER[*]} ."
fi

run_graphify || true

# Salvage a semantic/LLM-backend failure. A present-but-broken API key (wrong
# key, exhausted quota → HTTP 429, unreachable backend) is worse than no key:
# it skips the code-only fallback above AND fails semantic extraction, so the
# initial run can finish without writing graph.json — leaving Discovery with
# nothing. If that happened, drop the keys, force code-only mode, and rerun so
# the AST graph is still produced.
if [[ ! -f graphify-out/graph.json ]] && [[ "$NO_LLM_CODE_ONLY_MODE" -eq 0 ]]; then
  echo ""
  echo "No graphify-out/graph.json after the initial run — likely a semantic/LLM"
  echo "backend failure (bad key, exhausted quota, or unreachable provider)."
  echo "Retrying in code-only fallback mode so the AST graph is still generated..."
  unset OPENAI_API_KEY ANTHROPIC_API_KEY GOOGLE_API_KEY GEMINI_API_KEY MOONSHOT_API_KEY DEEPSEEK_API_KEY
  enable_no_llm_code_only_mode
  run_graphify || true
fi

if [[ -f graphify-out/graph.json ]] && [[ ! -f graphify-out/GRAPH_REPORT.md ]]; then
  echo ""
  echo "Graphify extracted graph data but has not generated GRAPH_REPORT.md yet."
  echo "Running cluster-only step to finalize GRAPH_REPORT.md and graph.html ..."
  "${GRAPHIFY_RUNNER[@]}" cluster-only .
fi

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
echo "  - graphify-out/graph.json"
if [[ -d graphify-out/cache/ast ]]; then
  echo "  - graphify-out/cache/ast/ (expected AST cache, useful for incremental reruns)"
fi
echo ""
echo "Use these artifacts as Discovery's short-term structural context, then translate verified findings into durable .ai/ files."
echo ""
echo "Next step: run Phase 2 Discovery"
echo "  @workspace /02-discover"
