#!/usr/bin/env bash
set -euo pipefail

# Rebuild the Claude Code mirrors from their sources.
#
# Claude Code reads `.claude/skills/` and `.claude/agents/`; every other harness reads
# `.agents/skills/` and `.github/agents/`. Both mirrors used to be maintained by hand and both
# drifted in real projects, so neither is authored any more:
#
#   .claude/skills            -> ../.agents/skills                   one relative symlink
#   .claude/agents/<n>.md     -> ../../.github/agents/<n>.agent.md   one relative symlink per agent
#
# Idempotent: run it after adding or deleting a skill or an agent, and on every
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

# ── Agents: one symlink per agent, same as skills ──────────────────────────────
# Both harnesses treat agent frontmatter the same way: `tools:` is optional and omitting it means
# the agent has every available tool, and each ignores keys it does not know. The standard's agents
# do not restrict tools, so the source carries no `tools:` line and one file is valid for both.
# A symlink may be named differently from its target, so `<role>.md` pointing at
# `<role>.agent.md` in another directory is fine.
link_agent() {
  local name="$1"
  local mirror="${ROOT}/.claude/agents/${name}.md"
  local link_target="../../.github/agents/${name}.agent.md"

  if [[ -L "$mirror" ]]; then
    if [[ "$(readlink "$mirror")" == "$link_target" ]]; then
      echo -e "  ${GREEN}✓${NC} .claude/agents/${name}.md -> ${link_target}"
      return 0
    fi
    rm "$mirror"
  elif [[ -f "$mirror" ]]; then
    # A hand-maintained copy from an older standard. If its body matches the source, nothing is
    # lost by replacing it with the link. If it does not, the two have drifted and only a human
    # can say which text is right, so it stays where it is and is reported.
    if body_matches "$mirror" "${ROOT}/.github/agents/${name}.agent.md"; then
      rm "$mirror"
      echo -e "  ${YELLOW}△${NC} .claude/agents/${name}.md was a copy with the same body, replaced by a symlink"
    else
      echo -e "  ${RED}✗${NC} .claude/agents/${name}.md has drifted from .github/agents/${name}.agent.md. Nothing was changed: reconcile the two bodies into the .github/ source, delete the copy, and run this script again"
      return 0
    fi
  fi

  mkdir -p "${ROOT}/.claude/agents"
  if ln -s "$link_target" "$mirror" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} .claude/agents/${name}.md -> ${link_target} (created)"
  else
    cp "${ROOT}/.github/agents/${name}.agent.md" "$mirror"
    echo -e "  ${YELLOW}△${NC} .claude/agents/${name}.md copied, this checkout cannot create symlinks, so re-run this script after every agent change"
  fi
  CHANGED=$((CHANGED + 1))
}

# Everything after the frontmatter block, which is the whole of an agent definition.
body_matches() {
  local a b
  a="$(awk 'BEGIN{fm=0} NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm {print}' "$1")"
  b="$(awk 'BEGIN{fm=0} NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm {print}' "$2")"
  [[ "$a" == "$b" ]]
}

# Legacy names from before the standard settled on the role name alone. The old file has to go,
# not sit beside the new one: two files whose frontmatter carries the same `name:` register as two
# agents under one name, which is exactly the duplicate that bit a client repository
# (`.claude/agents/maintainer-agent.md` next to `.claude/agents/maintainer.md`).
rename_legacy_sources() {
  local src_dir="$1"
  local src base target

  for src in "$src_dir"/*.md; do
    [[ -f "$src" ]] || continue
    base="$(basename "$src")"
    case "$base" in
      *-agent.agent.md) target="${base%-agent.agent.md}.agent.md" ;;   # support-agent.agent.md
      *.agent.md)       continue ;;
      *-agent.md)       target="${base%-agent.md}.agent.md" ;;         # support-agent.md
      *)                target="${base%.md}.agent.md" ;;               # support.md, no extension
    esac
    if [[ -e "${src_dir}/${target}" ]]; then
      echo -e "  ${YELLOW}△${NC} .github/agents/${base} and .github/agents/${target} both exist, left alone: delete the one you do not want"
      continue
    fi
    mv "$src" "${src_dir}/${target}"
    echo -e "  ${YELLOW}△${NC} .github/agents/${base} renamed to ${target} (the standard names an agent by its role alone)"
    CHANGED=$((CHANGED + 1))
  done
}

sync_agents() {
  local src_dir="${ROOT}/.github/agents"
  local mirror_dir="${ROOT}/.claude/agents"
  local src name legacy_of

  [[ -d "$src_dir" ]] || return 0
  rename_legacy_sources "$src_dir"
  mkdir -p "$mirror_dir"

  for src in "$src_dir"/*.agent.md; do
    [[ -f "$src" ]] || continue
    link_agent "$(basename "$src" .agent.md)"
  done

  local mirrored
  for mirrored in "$mirror_dir"/*.md; do
    [[ -e "$mirrored" ]] || continue
    name="$(basename "$mirrored" .md)"
    if [[ -f "${src_dir}/${name}.agent.md" ]]; then continue; fi

    # A mirror left over from the old `<role>-agent` naming, whose renamed source is now linked.
    # It is a stale copy of a file we still have, and leaving it registers the agent twice.
    legacy_of="${name%-agent}"
    if [[ "$legacy_of" != "$name" && -f "${src_dir}/${legacy_of}.agent.md" ]]; then
      if [[ -L "$mirrored" ]] || body_matches "$mirrored" "${src_dir}/${legacy_of}.agent.md"; then
        rm "$mirrored"
        echo -e "  ${YELLOW}△${NC} .claude/agents/${name}.md removed: stale copy of .claude/agents/${legacy_of}.md (it would register a second agent under the same name)"
        CHANGED=$((CHANGED + 1))
      else
        echo -e "  ${RED}✗${NC} .claude/agents/${name}.md is the old name of ${legacy_of} and its body has drifted. Nothing was changed: reconcile it into .github/agents/${legacy_of}.agent.md and delete it, or it registers a second agent under the same name"
      fi
      continue
    fi

    # Anything else that exists only in the mirror is reported, never deleted: it may be a
    # Claude-only subagent a project added on purpose. Removing the pair is the operator's call.
    echo -e "  ${YELLOW}△${NC} .claude/agents/${name}.md has no .github/agents/${name}.agent.md source, left in place"
  done
}

echo "Rebuilding Claude Code mirrors in ${ROOT}"
sync_skills
sync_agents
echo "  ${CHANGED} mirror(s) written"
