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
#   .claude/commands/<n>.md   generated from .github/prompts/<n>.prompt.md
#   .cursor/commands/<n>.md   generated from the same source
#
# The command mirrors are the one pair that cannot be a symlink, and the reason is frontmatter.
# An agent file carries `description` and `name` only, which both harnesses accept, so one file
# serves both and the mirror is a link. A prompt does not: `agent:` binds it to a Copilot agent
# and `model:` names a Copilot model, and neither means anything to Claude Code or Cursor — a
# link would hand them a model id they cannot resolve. The mirror therefore keeps the body
# verbatim and rewrites the frontmatter down to the keys every harness understands. Because it
# is generated rather than authored, it still cannot drift: this script rewrites it from source.
#
# Idempotent: run it after adding or deleting a skill, an agent or a prompt, and on every
# `scripts/install.sh . --update` refresh, which calls it for you — that's the standards repo's
# own installer, run against this project (or via the documented curl one-liner), not a script
# vendored into this repository: there is no local `scripts/install.sh` here to look for.
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
# Drift this script refuses to resolve on its own (a copied mirror whose body the source does not
# have, a stale legacy name that has diverged). It is reported and left alone, which used to mean
# the script printed a red line and still exited 0: an installer or a CI job saw success and the
# mirror stayed broken. Counted here and turned into a non-zero exit at the end, so a caller that
# wants to know can ask. scripts/install.sh deliberately tolerates it and prints a notice instead
# of aborting a half-finished install.
UNRECONCILED=0

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
      # `-e` alone follows a symlink and is false for one whose target is gone, so a dangling
      # symlink left over in an old copied mirror would be skipped here and then silently lost
      # to the `rm -rf "$mirror"` below. `-L` also matches the link itself, target or no target.
      [[ -e "$entry" || -L "$entry" ]] || continue
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
      echo -e "  ${RED}✗${NC} .claude/agents/${name}.md has content the .github/agents/${name}.agent.md source does not. Nothing was changed: fold anything worth keeping into the .github/ source (a copy that only points at that source is worth nothing, delete it), then delete the copy and run this script again"
      UNRECONCILED=$((UNRECONCILED + 1))
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
    # `-e` alone follows a symlink and is false for one whose target is gone, so a deleted source
    # agent's now-broken mirror link would skip this loop silently instead of being reported below.
    # `-L` also matches the link itself, target or no target.
    [[ -e "$mirrored" || -L "$mirrored" ]] || continue
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
        UNRECONCILED=$((UNRECONCILED + 1))
      fi
      continue
    fi

    # Anything else that exists only in the mirror is reported, never deleted: it may be a
    # Claude-only subagent a project added on purpose. Removing the pair is the operator's call.
    echo -e "  ${YELLOW}△${NC} .claude/agents/${name}.md has no .github/agents/${name}.agent.md source, left in place"
  done
}

# ── Commands: generated from the prompt source, for Claude Code and Cursor ─────
# Frontmatter keys a mirror keeps. An allow-list, not a deny-list: the source is Copilot's, so
# anything not named here is Copilot-facing until proven otherwise, and a key that means nothing
# to the target harness is better dropped than passed through. `name` is harmless in both,
# `description` and `argument-hint` are what they render in the slash-command palette.
MIRROR_KEEP_KEYS=" name description argument-hint "

# The standard's own bootstrap prompts are installed under different names by scripts/install.sh
# (migrate.prompt.md -> ms-migration.md, 01-install.prompt.md -> ms-install.md, and so on), so
# identity naming does not apply to them and generating <basename>.md here would put a second,
# wrongly-named copy of each into the palette. install.sh owns those five; this function owns
# everything a project authors itself. Phase 5 of the migrate prompt deletes them anyway.
BOOTSTRAP_PROMPTS=" migrate 01-install 02-discover 03-integrate 04-stack-tooling "

# Body verbatim, frontmatter filtered to MIRROR_KEEP_KEYS. A folded or multi-line value belongs to
# the key above it, so continuation lines (leading whitespace, no `key:` of their own) follow that
# key's verdict instead of being tested as keys themselves and silently dropped.
render_command_mirror() {
  awk -v keep="$MIRROR_KEEP_KEYS" '
    BEGIN { fm = 0; keeping = 0 }
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm && $0 == "---"      { fm = 0; print; next }
    fm {
      if ($0 ~ /^[[:space:]]/ || $0 !~ /^[A-Za-z_][A-Za-z0-9_-]*:/) {
        if (keeping) print
        next
      }
      key = $0; sub(/:.*/, "", key)
      keeping = (index(keep, " " key " ") > 0)
      if (keeping) print
      next
    }
    { print }
  ' "$1"
}

write_command_mirror() {
  local src="$1" mirror="$2" rendered
  rendered="$(render_command_mirror "$src")"

  if [[ -f "$mirror" ]] && [[ "$(cat "$mirror")" == "$rendered" ]]; then
    echo -e "  ${GREEN}✓${NC} ${mirror#"${ROOT}/"}"
    return 0
  fi

  mkdir -p "$(dirname "$mirror")"
  printf '%s\n' "$rendered" > "$mirror"
  echo -e "  ${GREEN}✓${NC} ${mirror#"${ROOT}/"} (written from ${src#"${ROOT}/"})"
  CHANGED=$((CHANGED + 1))
}

sync_commands() {
  local src_dir="${ROOT}/.github/prompts"
  local src name

  [[ -d "$src_dir" ]] || return 0

  for src in "$src_dir"/*.prompt.md; do
    [[ -f "$src" ]] || continue
    name="$(basename "$src" .prompt.md)"
    [[ "$BOOTSTRAP_PROMPTS" == *" ${name} "* ]] && continue
    write_command_mirror "$src" "${ROOT}/.claude/commands/${name}.md"
    write_command_mirror "$src" "${ROOT}/.cursor/commands/${name}.md"
  done

  # A mirror with no source is reported, never deleted — same policy as the agent mirrors. It may
  # be a command a project wrote for one harness on purpose, and removing it is the operator's call.
  local mirror_dir mirrored
  for mirror_dir in "${ROOT}/.claude/commands" "${ROOT}/.cursor/commands"; do
    [[ -d "$mirror_dir" ]] || continue
    for mirrored in "$mirror_dir"/*.md; do
      [[ -f "$mirrored" ]] || continue
      name="$(basename "$mirrored" .md)"
      [[ -f "${src_dir}/${name}.prompt.md" ]] && continue
      [[ "$name" == ms-* ]] && continue   # installed by scripts/install.sh, not from .github/prompts
      echo -e "  ${YELLOW}△${NC} ${mirrored#"${ROOT}/"} has no ${src_dir#"${ROOT}/"}/${name}.prompt.md source, left in place"
    done
  done
}

echo "Rebuilding Claude Code mirrors in ${ROOT}"
sync_skills
sync_agents
sync_commands
echo "  ${CHANGED} mirror(s) written"
if [[ "$UNRECONCILED" -gt 0 ]]; then
  echo "  ${UNRECONCILED} mirror(s) need manual reconciliation (see the lines marked above)"
  exit 1
fi
