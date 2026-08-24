#!/usr/bin/env bash
set -euo pipefail

# Rebuild the Claude Code mirrors from their sources.
#
# Claude Code reads `.claude/skills/` and `.claude/agents/`; every other harness reads
# `.agents/skills/` and `.github/agents/`. Both mirrors used to be maintained by hand and both
# drifted in real projects, so neither is authored any more:
#
#   .agents/skills/            -> .claude/skills            a relative symlink, nothing to re-copy
#   .github/agents/<n>.agent.md -> .claude/agents/<n>.md    a derived file, regenerated every run
#
# Idempotent: run it after adding, editing or deleting a skill or an agent, and on every
# `scripts/install.sh . --update` refresh, which calls it for you.
#
# Usage:
#   ./scripts/mirror-claude.sh                  # current directory
#   ./scripts/mirror-claude.sh /path/to/project

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"

CHANGED=0

# ── Skills: one symlink instead of a copy per skill ────────────────────────────
# A copied mirror has to be re-copied on every source edit, and when it is not, the two
# diverge silently. A symlink cannot.
sync_skills() {
  local src="${ROOT}/.agents/skills"
  local mirror="${ROOT}/.claude/skills"
  local link_target="../.agents/skills"

  [[ -d "$src" ]] || return 0

  if [[ -L "$mirror" ]]; then
    if [[ "$(readlink "$mirror")" == "$link_target" ]]; then
      echo -e "  ${GREEN}✓${NC} .claude/skills -> ${link_target}"
      return 0
    fi
    echo -e "  ${YELLOW}△${NC} .claude/skills pointed at $(readlink "$mirror"), repointing"
    rm "$mirror"
  elif [[ -d "$mirror" ]]; then
    # A copied mirror from an older standard. Nothing in it may be lost silently: an entry the
    # source does not have is moved into the source, an entry that drifted from the source is
    # reported before the source copy wins.
    local entry name
    for entry in "$mirror"/* "$mirror"/.[!.]*; do
      [[ -e "$entry" ]] || continue
      name="$(basename "$entry")"
      if [[ ! -e "${src}/${name}" ]]; then
        mv "$entry" "${src}/${name}"
        echo -e "  ${YELLOW}△${NC} ${name}: existed only in the mirror, moved into .agents/skills/ (nothing deleted)"
      elif ! diff -rq "$entry" "${src}/${name}" >/dev/null 2>&1; then
        echo -e "  ${YELLOW}△${NC} ${name}: mirror copy had drifted from .agents/skills/${name}, the source wins"
      fi
    done
    rm -rf "$mirror"
  elif [[ -e "$mirror" ]]; then
    echo -e "  ${RED}✗${NC} .claude/skills exists and is neither a directory nor a symlink, leaving it alone"
    return 1
  fi

  mkdir -p "${ROOT}/.claude"
  if ln -s "$link_target" "$mirror" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} .claude/skills -> ${link_target} (created)"
  else
    # No symlink support (a Windows checkout without developer mode). Fall back to the old
    # copy so the mirror still exists, and say so: this project has to re-run the script
    # after every skill change.
    cp -R "$src" "$mirror"
    echo -e "  ${YELLOW}△${NC} .claude/skills copied, this checkout cannot create symlinks, so re-run this script after every skill change"
  fi
  CHANGED=$((CHANGED + 1))
}

# ── Agents: a derived file, not a second hand-maintained one ───────────────────
# The two cannot be a symlink: Claude Code subagent frontmatter is `name` + `description`
# (+ optional `model`), while the .github source also carries the Copilot `tools:` list.
# So the body is copied verbatim and only the frontmatter is rewritten, deterministically.
# Claude Code subagents inherit every available tool, so dropping `tools:` loses nothing.
derive_agent() {
  local src="$1" dest="$2"

  awk '
    NR == 1 && $0 == "---" { print; infm = 1; next }
    infm && $0 == "---" {
      # Canonical field order, so the output does not depend on the source ordering.
      if (name != "")  print name
      if (desc != "")  print desc
      if (model != "") print model
      print "---"
      infm = 0
      next
    }
    infm && /^name:/        { name  = $0; next }
    infm && /^description:/ { desc  = $0; next }
    infm && /^model:/       { model = $0; next }
    infm { next }   # tools:, its continuation lines and any other harness-only field
    { print }
  ' "$src" > "${dest}.tmp"

  if [[ -f "$dest" ]] && cmp -s "${dest}.tmp" "$dest"; then
    rm "${dest}.tmp"
    echo -e "  ${GREEN}✓${NC} ${dest#$ROOT/} (up to date)"
    return 0
  fi

  local verb="derived"
  if [[ -f "$dest" ]]; then verb="re-derived, it had drifted"; fi
  mv "${dest}.tmp" "$dest"
  echo -e "  ${GREEN}↻${NC} ${dest#$ROOT/} (${verb})"
  CHANGED=$((CHANGED + 1))
}

sync_agents() {
  local src_dir="${ROOT}/.github/agents"
  local mirror_dir="${ROOT}/.claude/agents"
  local src name

  [[ -d "$src_dir" ]] || return 0
  mkdir -p "$mirror_dir"

  for src in "$src_dir"/*.agent.md; do
    [[ -f "$src" ]] || continue
    name="$(basename "$src" .agent.md)"
    derive_agent "$src" "${mirror_dir}/${name}.md"
  done

  # An agent that exists only in the mirror is reported, never deleted: it may be a Claude-only
  # subagent a project added on purpose. Removing the pair is the operator's call.
  local mirrored
  for mirrored in "$mirror_dir"/*.md; do
    [[ -f "$mirrored" ]] || continue
    name="$(basename "$mirrored" .md)"
    if [[ -f "${src_dir}/${name}.agent.md" ]]; then continue; fi
    echo -e "  ${YELLOW}△${NC} .claude/agents/${name}.md has no .github/agents/${name}.agent.md source, left in place"
  done
}

echo "Rebuilding Claude Code mirrors in ${ROOT}"
sync_skills
sync_agents
echo "  ${CHANGED} mirror(s) written"
