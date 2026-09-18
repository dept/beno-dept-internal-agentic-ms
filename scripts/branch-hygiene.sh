#!/usr/bin/env bash
# DEPT Agentic Standard: tiered stale-branch hygiene
# Usage: ./scripts/branch-hygiene.sh [--dry-run|--no-dry-run] [project-dir]
#
# Runs inside a full clone (fetch-depth: 0) with GH_TOKEN set, or locally against any repo
# checkout with `gh auth login` already done. Classifies every branch on origin into exactly
# one tier and acts on it (or reports what it would do, in dry run).
#
# Tiers, evaluated in this order (first match wins):
#   1. delete    merged into every existing env branch                 -> delete the branch
#   2. promote   merged into production, missing from a lower env      -> open a promotion PR
#   3. flag      merged into a lower env, missing from a higher one,
#                tip older than STALE_DAYS (default 60)                -> list in the report
#   4. archive   merged nowhere, no open PR, tip older than ARCHIVE_DAYS -> tag then delete
#   5. untouched everything else                                       -> counted only
#
# Not installed by the standard's installer (not in scripts/install.sh's ARTIFACTS). Copy
# templates/workflows/branch-hygiene.yml and this script into a repository by hand, the same way
# templates/workflows/dependabot-auto-merge.yml is offered, see prompts/migrate.prompt.md
# Phase 4d. Run the first pass as a dry run; it only prints the report and touches nothing.

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
#
# Every setting below is read from the environment and falls back to the default shown. In
# CI, templates/workflows/branch-hygiene.yml supplies them from repository variables
# (BRANCH_HYGIENE_ENV_BRANCHES, BRANCH_HYGIENE_STALE_DAYS, BRANCH_HYGIENE_ARCHIVE_DAYS,
# BRANCH_HYGIENE_KEEP_PATTERNS, BRANCH_HYGIENE_PROMOTE_MAX), each optional and each defaulting to the same value here, so
# a local run and a scheduled run of an unconfigured repository behave identically.
# ---------------------------------------------------------------------------

DRY_RUN="${DRY_RUN:-true}"
PROJECT_DIR="."

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-dry-run) DRY_RUN=false ;;
    *) PROJECT_DIR="$arg" ;;
  esac
done

cd "$PROJECT_DIR"

ENV_BRANCHES_RAW="${ENV_BRANCHES:-develop,test,acceptance,main}"
STALE_DAYS="${STALE_DAYS:-60}"
ARCHIVE_DAYS="${ARCHIVE_DAYS:-180}"
KEEP_PATTERNS_RAW="${KEEP_PATTERNS:-release/*,hotfix/*,keep/*,dependabot/*,renovate/*}"
# Tier 2 opens one pull request per branch per missing env, and the first run of a repository
# that has never been cleaned finds years of them at once. The cap bounds that first run to
# something a team can actually review; the rest are reported and picked up next month.
PROMOTE_MAX="${PROMOTE_MAX:-5}"
# Most tier 3 branches listed in the Slack digest. A Slack section block is rejected above
# 3000 characters and a neglected repository has dozens, so the rest are a count plus a link.
SLACK_MAX_LISTED="${SLACK_MAX_LISTED:-10}"
LABEL="branch-hygiene"

NOW_EPOCH=$(date -u +%s)

echo "== Branch hygiene =="
echo "dry_run=${DRY_RUN} stale_days=${STALE_DAYS} archive_days=${ARCHIVE_DAYS} promote_max=${PROMOTE_MAX}"

# ---------------------------------------------------------------------------
# Fetch + resolve the env chain
# ---------------------------------------------------------------------------

# CI checks out with a remote named "origin". A local clone can have it under any name
# (e.g. a fork remote), so fall back to the sole configured remote when "origin" is absent.
REMOTE="origin"
if ! git remote get-url origin >/dev/null 2>&1; then
  # `mapfile`/`readarray` is bash 4.0+; the macOS default bash is 3.2, so read line by line.
  declare -a remotes=()
  while IFS= read -r r; do
    [[ -n "$r" ]] && remotes+=("$r")
  done < <(git remote)
  if [[ ${#remotes[@]} -eq 1 ]]; then
    REMOTE="${remotes[0]}"
  else
    echo "No 'origin' remote and more than one remote configured; set REMOTE explicitly." >&2
    exit 1
  fi
fi

git fetch --prune "$REMOTE" >/dev/null 2>&1 || git fetch --prune "$REMOTE"

remote_branch_exists() {
  git show-ref --verify --quiet "refs/remotes/${REMOTE}/$1"
}

DEFAULT_BRANCH=$(git remote show "$REMOTE" 2>/dev/null | awk '/HEAD branch/{print $NF}' || true)
[[ -z "$DEFAULT_BRANCH" ]] && DEFAULT_BRANCH="main"

# Ordered, lowest to highest. `master` is an alias for `main`: only whichever of the two
# actually exists on origin is kept, in the position `main` would have occupied.
declare -a ENV_CHAIN=()
IFS=',' read -r -a env_list <<<"$ENV_BRANCHES_RAW"
for e in "${env_list[@]}"; do
  e="${e## }"; e="${e%% }"
  [[ -z "$e" ]] && continue
  if [[ "$e" == "main" ]] && ! remote_branch_exists "main" && remote_branch_exists "master"; then
    e="master"
  fi
  remote_branch_exists "$e" && ENV_CHAIN+=("$e")
done

if [[ ${#ENV_CHAIN[@]} -eq 0 ]]; then
  echo "No configured env branch exists on origin (ENV_BRANCHES=${ENV_BRANCHES_RAW}); nothing to do."
  exit 0
fi

# Negative array indices are bash 4.3+; the macOS default bash is 3.2, so index explicitly.
PRODUCTION="${ENV_CHAIN[$((${#ENV_CHAIN[@]} - 1))]}"
echo "env_chain=${ENV_CHAIN[*]} production=${PRODUCTION} default_branch=${DEFAULT_BRANCH}"

IFS=',' read -r -a KEEP_PATTERNS <<<"$KEEP_PATTERNS_RAW"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

matches_keep_pattern() {
  local b="$1" p
  for p in "${KEEP_PATTERNS[@]}"; do
    # shellcheck disable=SC2053
    [[ "$b" == $p ]] && return 0
  done
  for e in "${ENV_CHAIN[@]}"; do
    [[ "$b" == "$e" ]] && return 0
  done
  [[ "$b" == "$DEFAULT_BRANCH" ]] && return 0
  return 1
}

# One PR fetch for the whole run. GITHUB_TOKEN is limited to 1000 API requests per hour per
# repository, and a per-branch `gh pr list` on a 300-branch repo would spend that budget before
# the run finished. Lines are "STATE|head|base|author|number" (STATE is OPEN, MERGED or CLOSED).
PR_INDEX=$(gh pr list --state all --limit 5000 --json state,headRefName,baseRefName,author,number \
  --jq '.[] | "\(.state)|\(.headRefName)|\(.baseRefName)|\(.author.login // "")|\(.number)"' 2>/dev/null || true)

# $1 = state (or "" for any), $2 = head, $3 = base (or "" for any). The trailing \|* tolerates
# the author field appended to each line: without it an exact base match would fail because the
# line no longer ends at the base.
pr_exists() {
  local state="${1:-[A-Z]*}" head="$2" base="${3:-*}" line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # shellcheck disable=SC2053
    [[ "$line" == ${state}\|${head}\|${base}\|* ]] && return 0
  done <<<"$PR_INDEX"
  return 1
}

# GitHub login of the first PR whose head is this branch, empty if none carried an author. Used
# only to label the Slack digest; a tier 3 branch was merged into a lower env, so it almost
# always has a PR in the index.
pr_author() {
  local head="$1" s h b a n
  while IFS='|' read -r s h b a n; do
    [[ "$h" == "$head" ]] || continue
    [[ -n "$a" ]] && { echo "$a"; return 0; }
  done <<<"$PR_INDEX"
  return 1
}

# PR number of the first PR whose head is this branch, empty if none. Used to link the branch in
# the Slack digest; a tier 3 branch's PR is merged (closed), so the link points at a closed PR.
pr_number() {
  local head="$1" s h b a n
  while IFS='|' read -r s h b a n; do
    [[ "$h" == "$head" ]] || continue
    [[ -n "$n" ]] && { echo "$n"; return 0; }
  done <<<"$PR_INDEX"
  return 1
}

has_open_pr() {
  pr_exists OPEN "$1" ""
}

# "Merged into X": either the ancestor test passes, or a merged PR head=B base=X exists.
# The PR check exists because a squash or rebase merge rewrites commits, so the ancestor test
# alone misses every branch merged that way even though GitHub shows it merged.
merged_into() {
  local b="$1" target="$2"
  git merge-base --is-ancestor "${REMOTE}/${b}" "${REMOTE}/${target}" 2>/dev/null && return 0
  pr_exists MERGED "$b" "$target"
}

branch_tip_epoch() {
  git log -1 --format=%ct "${REMOTE}/$1"
}

branch_author() {
  git log -1 --format='%an' "${REMOTE}/$1"
}

branch_sha() {
  git rev-parse --short "${REMOTE}/$1"
}

age_days() {
  echo $(( (NOW_EPOCH - $1) / 86400 ))
}

# ---------------------------------------------------------------------------
# Enumerate candidate branches
# ---------------------------------------------------------------------------

declare -a ALL_BRANCHES=()
while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  # refs/remotes/<remote>/HEAD is the remote's symbolic default-branch pointer, not a branch;
  # its `refname:short` collapses to the bare remote name, so filter on the full ref instead.
  [[ "$ref" == "refs/remotes/${REMOTE}/HEAD" ]] && continue
  ALL_BRANCHES+=("${ref#refs/remotes/${REMOTE}/}")
done < <(git for-each-ref --format='%(refname)' "refs/remotes/${REMOTE}")

# Report rows: "tier|branch|sha|age|author|envs|action". The sha is what makes a tier 1
# deletion recoverable: those commits are already on the env branches, but finding the tip
# again after the branch ref is gone means digging through GitHub's reflog, which expires.
# Recorded here, the report (and the report issue) is the recovery record:
# `git branch <branch> <sha>`. Tier 4 does not need it, it tags before it deletes.
declare -a ROWS_DELETE=()
declare -a ROWS_PROMOTE=()
declare -a ROWS_FLAG=()
declare -a ROWS_ARCHIVE=()
UNTOUCHED_COUNT=0
PROMOTED_COUNT=0

LABEL_ENSURED=false
ensure_label() {
  [[ "$LABEL_ENSURED" == "true" ]] && return 0
  gh label create "$LABEL" --color "B60205" --description "Branch hygiene automation" --force >/dev/null 2>&1 || true
  LABEL_ENSURED=true
}

for b in "${ALL_BRANCHES[@]}"; do
  matches_keep_pattern "$b" && continue
  has_open_pr "$b" && continue

  tip_epoch=$(branch_tip_epoch "$b")
  age=$(age_days "$tip_epoch")
  author=$(branch_author "$b")
  sha=$(branch_sha "$b")

  declare -a merged_envs=()
  declare -a missing_envs=()
  for e in "${ENV_CHAIN[@]}"; do
    if merged_into "$b" "$e"; then
      merged_envs+=("$e")
    else
      missing_envs+=("$e")
    fi
  done
  envs_str="merged:${merged_envs[*]:-none} missing:${missing_envs[*]:-none}"

  merged_into_production=false
  for e in "${merged_envs[@]:-}"; do
    [[ "$e" == "$PRODUCTION" ]] && merged_into_production=true
  done

  if [[ ${#missing_envs[@]} -eq 0 ]]; then
    # Tier 1: delete, merged into every existing env branch.
    if [[ "$DRY_RUN" == "true" ]]; then
      ROWS_DELETE+=("$b|$sha|$age|$author|$envs_str|would delete")
    else
      git push "$REMOTE" --delete "$b" 2>&1 || true
      ROWS_DELETE+=("$b|$sha|$age|$author|$envs_str|deleted")
    fi
    continue
  fi

  if [[ "$merged_into_production" == "true" ]]; then
    # Tier 2: promote, merged into production but missing from a lower env.
    actions=""
    if [[ "$PROMOTED_COUNT" -ge "$PROMOTE_MAX" ]]; then
      ROWS_PROMOTE+=("$b|$sha|$age|$author|$envs_str|over PROMOTE_MAX (${PROMOTE_MAX}), not opened this run")
      continue
    fi
    PROMOTED_COUNT=$((PROMOTED_COUNT + 1))
    for e in "${missing_envs[@]}"; do
      [[ "$e" == "$PRODUCTION" ]] && continue
      title="chore(promote): ${b} into ${e}"
      if pr_exists "" "$b" "$e"; then
        actions="${actions}${e}:exists "
        continue
      fi
      if [[ "$DRY_RUN" == "true" ]]; then
        actions="${actions}${e}:would-open-pr "
      else
        ensure_label
        body="Found merged into ${PRODUCTION} (production) but absent from ${e}. Opened automatically by branch-hygiene."
        gh pr create --head "$b" --base "$e" --title "$title" --body "$body" --label "$LABEL" >/dev/null 2>&1 \
          && actions="${actions}${e}:opened " \
          || actions="${actions}${e}:failed "
      fi
    done
    ROWS_PROMOTE+=("$b|$sha|$age|$author|$envs_str|${actions}")
    continue
  fi

  if [[ ${#merged_envs[@]} -gt 0 && "$age" -gt "$STALE_DAYS" ]]; then
    # Tier 3: flag, merged into a lower env, missing from a higher one, stale.
    ROWS_FLAG+=("$b|$sha|$age|$author|$envs_str|listed for promote-or-revert")
    continue
  fi

  if [[ ${#merged_envs[@]} -eq 0 && "$age" -gt "$ARCHIVE_DAYS" ]]; then
    # Tier 4: archive, merged nowhere, stale beyond ARCHIVE_DAYS.
    if [[ "$DRY_RUN" == "true" ]]; then
      ROWS_ARCHIVE+=("$b|$sha|$age|$author|$envs_str|would tag archive/${b} and delete")
    else
      if git push "$REMOTE" "${REMOTE}/${b}:refs/tags/archive/${b}" 2>&1; then
        git push "$REMOTE" --delete "$b" 2>&1 || true
        ROWS_ARCHIVE+=("$b|$sha|$age|$author|$envs_str|tagged archive/${b}, deleted")
      else
        ROWS_ARCHIVE+=("$b|$sha|$age|$author|$envs_str|tag failed, branch kept")
      fi
    fi
    continue
  fi

  UNTOUCHED_COUNT=$((UNTOUCHED_COUNT + 1))
done

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

# $1 = title, $2.. = rows (may be zero rows). Never expand a possibly-empty array with a
# ":-" default into this: on bash 3.2 (the macOS default) that substitutes a single empty-string
# element instead of zero elements, so "$# -eq 0" below would never see the no-rows case. Callers
# guard the splat themselves instead (`[[ ${#ARR[@]} -gt 0 ]] && render_table ... "${ARR[@]}" ...`).
render_table() {
  local title="$1"; shift
  echo "### ${title}"
  if [[ $# -eq 0 ]]; then
    echo "_none_"
    echo ""
    return 0
  fi
  echo "| Branch | Tip | Age (days) | Last author | Envs | Action |"
  echo "|---|---|---|---|---|---|"
  local row branch sha age author envs action
  for row in "$@"; do
    IFS='|' read -r branch sha age author envs action <<<"$row"
    echo "| ${branch} | \`${sha}\` | ${age} | ${author} | ${envs} | ${action} |"
  done
  echo ""
}

REPORT=$(
  echo "# Branch hygiene report"
  echo ""
  echo "env_chain: ${ENV_CHAIN[*]} (production: ${PRODUCTION})"
  echo ""
  if [[ ${#ROWS_DELETE[@]} -gt 0 ]]; then
    render_table "Tier 1: delete (merged everywhere)" "${ROWS_DELETE[@]}"
  else
    render_table "Tier 1: delete (merged everywhere)"
  fi
  if [[ ${#ROWS_PROMOTE[@]} -gt 0 ]]; then
    render_table "Tier 2: promote (merged to production, missing from a lower env)" "${ROWS_PROMOTE[@]}"
  else
    render_table "Tier 2: promote (merged to production, missing from a lower env)"
  fi
  if [[ ${#ROWS_FLAG[@]} -gt 0 ]]; then
    render_table "Tier 3: flag, promote or revert (stale, partially merged)" "${ROWS_FLAG[@]}"
  else
    render_table "Tier 3: flag, promote or revert (stale, partially merged)"
  fi
  if [[ ${#ROWS_ARCHIVE[@]} -gt 0 ]]; then
    render_table "Tier 4: archive (merged nowhere, very stale)" "${ROWS_ARCHIVE[@]}"
  else
    render_table "Tier 4: archive (merged nowhere, very stale)"
  fi
  echo "untouched: ${UNTOUCHED_COUNT} branches"
  echo ""
  echo "To restore an archived branch: \`git checkout -b <branch> archive/<branch>\`"
  echo ""
  echo "To restore any other deleted branch, from the Tip column above:"
  echo "\`git branch <branch> <tip>\` then \`git push ${REMOTE} <branch>\`"
)

echo ""
echo "$REPORT"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "$REPORT" >>"$GITHUB_STEP_SUMMARY"
fi

# The issue carries tiers 3 and 4 only, never the full report. Tiers 1 and 2 are already
# acted on and need no human, and on a repository that has never been cleaned tier 1 alone
# runs to hundreds of rows: dtnl-lucardi produces 816, which at roughly 120 bytes a row is
# some 98 KB, and GitHub rejects an issue body over 65536 characters. The full report stays
# in the job summary, which allows 1 MB.
ISSUE_BODY=$(
  echo "Branches needing a human decision. The full report, including what was deleted and"
  echo "promoted automatically, is in the job summary of the run that wrote this."
  echo ""
  if [[ ${#ROWS_FLAG[@]} -gt 0 ]]; then
    render_table "Tier 3: promote or revert (stale, partially merged)" "${ROWS_FLAG[@]}"
  else
    render_table "Tier 3: promote or revert (stale, partially merged)"
  fi
  if [[ ${#ROWS_ARCHIVE[@]} -gt 0 ]]; then
    render_table "Tier 4: archived (merged nowhere, very stale)" "${ROWS_ARCHIVE[@]}"
  else
    render_table "Tier 4: archived (merged nowhere, very stale)"
  fi
  echo "Restore an archived branch: \`git checkout -b <branch> archive/<branch>\`"
)

# Belt and braces: a repository with thousands of stale branches can overrun the limit on
# tiers 3 and 4 alone. Truncate rather than let the API reject the whole thing.
if [[ ${#ISSUE_BODY} -gt 60000 ]]; then
  ISSUE_BODY="${ISSUE_BODY:0:60000}

_Truncated at 60000 characters. The complete report is in the job summary._"
fi

ISSUE_NUMBER=""

# ---------------------------------------------------------------------------
# Upsert the report issue (only outside dry run, and only when tier 3 or 4 has entries)
# ---------------------------------------------------------------------------

if [[ "$DRY_RUN" != "true" && ( ${#ROWS_FLAG[@]} -gt 0 || ${#ROWS_ARCHIVE[@]} -gt 0 ) ]]; then
  ensure_label
  existing=$(gh issue list --label "$LABEL" --state open --search "Branch hygiene report in:title" \
    --limit 1 --json number --jq '.[0].number' 2>/dev/null || true)
  # Neither gh call may kill the run under set -e: by this point tier 1 has already deleted
  # branches, so a repository with issues disabled, or a token without issues:write, must
  # degrade to "no issue" rather than abort with the deletions half-reported. The Slack digest
  # (ISSUE_NUMBER stays empty, so it just omits the issue link) and the job summary still carry
  # the full report.
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    if gh issue edit "$existing" --body "$ISSUE_BODY" >/dev/null 2>&1; then
      ISSUE_NUMBER="$existing"
      echo "Updated issue #${existing}"
    else
      echo "Could not update issue #${existing} (issues disabled or missing permission); the full report is in the job summary." >&2
    fi
  elif ISSUE_URL=$(gh issue create --title "Branch hygiene report" --label "$LABEL" --body "$ISSUE_BODY" 2>/dev/null); then
    ISSUE_NUMBER="${ISSUE_URL##*/}"
    echo "Created branch hygiene report issue #${ISSUE_NUMBER}"
  else
    echo "Could not create the report issue (issues disabled or missing permission); the full report is in the job summary." >&2
  fi
elif [[ "$DRY_RUN" == "true" && ( ${#ROWS_FLAG[@]} -gt 0 || ${#ROWS_ARCHIVE[@]} -gt 0 ) ]]; then
  echo "(dry run: would upsert the 'Branch hygiene report' issue, ${#ISSUE_BODY} characters, tiers 3 and 4 only)"
fi

# ---------------------------------------------------------------------------
# Slack digest (optional)
# ---------------------------------------------------------------------------

# Silent unless both SLACK_BOT_TOKEN and SLACK_CHANNEL are set. A repository without a Slack
# app configured must stay quiet rather than fail, which is why this is a warning and an
# early return, not an error. Same rule the stale pull request digest uses.
post_to_slack() {
  if [[ -z "${SLACK_BOT_TOKEN:-}" || -z "${SLACK_CHANNEL:-}" ]]; then
    echo "No SLACK_BOT_TOKEN or SLACK_CHANNEL; skipping the Slack digest."
    return 0
  fi

  # In Actions GITHUB_REPOSITORY is owner/name already. Locally, derive it from the remote
  # URL with parameter expansion rather than a regex: sed has no non-greedy quantifier, so
  # the obvious pattern silently matched nothing and the digest went out with a blank name.
  local repo="${GITHUB_REPOSITORY:-}"
  if [[ -z "$repo" ]]; then
    repo=$(git remote get-url "$REMOTE")
    repo="${repo%.git}"      # drop a trailing .git
    repo="${repo%/}"         # drop a trailing slash
    repo="${repo#*://*/}"    # https://host/owner/name -> owner/name
    repo="${repo#*:}"        # git@host:owner/name     -> owner/name
  fi
  local run_url=""
  [[ -n "${GITHUB_RUN_ID:-}" ]] && run_url="https://github.com/${repo}/actions/runs/${GITHUB_RUN_ID}"
  local issue_url=""
  [[ -n "$ISSUE_NUMBER" ]] && issue_url="https://github.com/${repo}/issues/${ISSUE_NUMBER}"

  # Tier 3 is the only tier a developer has to act on: tiers 1, 2 and 4 already happened.
  # So the message leads with the counts and then lists tier 3 alone, capped, because a
  # Slack section block is rejected above 3000 characters and lucardi has 69 of them.
  local flag_lines=""
  if [[ ${#ROWS_FLAG[@]} -gt 0 ]]; then
    local row branch sha age author envs action login num handle branch_disp shown=0
    for row in "${ROWS_FLAG[@]}"; do
      [[ "$shown" -ge "$SLACK_MAX_LISTED" ]] && break
      IFS='|' read -r branch sha age author envs action <<<"$row"
      # Link the branch to its PR and the owner to their GitHub profile, using Slack's
      # `<url|text>` link syntax. The @handle links to the person, not a Slack ping: a real
      # notification needs the person's Slack user id, which we cannot map a GitHub login to.
      # Slack does not render backticks inside link text, so a linked branch loses its code
      # font; an unlinked one (no PR found) keeps it.
      login=$(pr_author "$branch" || true)
      num=$(pr_number "$branch" || true)
      if [[ -n "$login" ]]; then handle="<https://github.com/${login}|@${login}>"; else handle="$author"; fi
      if [[ -n "$num" ]]; then branch_disp="<https://github.com/${repo}/pull/${num}|${branch}>"; else branch_disp="\`${branch}\`"; fi
      # Turn "merged:a b missing:c" into emoji badges: :white_check_mark: for the envs it is in,
      # :warning: for the ones it still needs. The envs string keeps its plain form in the issue
      # tables; only the Slack line is badged.
      local merged_part missing_part badges=""
      merged_part="${envs#merged:}"; merged_part="${merged_part%% missing:*}"
      missing_part="${envs#*missing:}"
      [[ "$merged_part" != "none" ]] && badges=":white_check_mark: ${merged_part}"
      [[ "$missing_part" != "none" ]] && badges="${badges:+${badges}  }:warning: ${missing_part}"
      flag_lines="${flag_lines}${branch_disp}  ${badges}  ${handle}  \`${age}d\`"$'\n'
      shown=$((shown + 1))
    done
  fi

  local payload
  payload=$(jq -n \
    --arg channel "$SLACK_CHANNEL" \
    --arg repo "$repo" \
    --arg dry "$DRY_RUN" \
    --arg flag_lines "$flag_lines" \
    --arg run_url "$run_url" \
    --arg issue_url "$issue_url" \
    --argjson deleted "${#ROWS_DELETE[@]}" \
    --argjson promoted "${#ROWS_PROMOTE[@]}" \
    --argjson flagged "${#ROWS_FLAG[@]}" \
    --argjson archived "${#ROWS_ARCHIVE[@]}" \
    --argjson untouched "$UNTOUCHED_COUNT" \
    --argjson max "$SLACK_MAX_LISTED" '
      ($dry == "true") as $isdry
      | (if $isdry then "would delete" else "deleted" end) as $d
      | (if $isdry then "would open" else "opened" end) as $p
      | (if $isdry then "would archive" else "archived" end) as $a
      | (if $isdry then "Branch hygiene dry run" else "Branch hygiene" end) as $title
      | {
          channel: $channel,
          text: "\($title) in \($repo): \($deleted) \($d), \($promoted) promotion PR\(if $promoted == 1 then "" else "s" end) \($p), \($flagged) need a decision, \($archived) \($a)",
          unfurl_links: false,
          blocks: (
            [ { type: "header",
                text: { type: "plain_text", emoji: true, text: $title } },
              { type: "context",
                elements: [ { type: "mrkdwn",
                  text: (["<https://github.com/\($repo)|\($repo)>"]
                         + (if $isdry then ["_dry run, nothing was changed_"] else [] end)
                         | join("  ·  ")) } ] },
              { type: "section",
                fields: [
                  { type: "mrkdwn", text: "*Merged everywhere*\n\($deleted) \($d)" },
                  { type: "mrkdwn", text: "*Awaiting promotion*\n\($promoted) PR\(if $promoted == 1 then "" else "s" end) \($p)" },
                  { type: "mrkdwn", text: "*Need a decision*\n\($flagged)" },
                  { type: "mrkdwn", text: "*Stale, no merge*\n\($archived) \($a)" }
                ] } ]
            + (if ($flag_lines | length) > 0 then
                 [ { type: "section",
                     text: { type: "mrkdwn",
                             text: ("*Promote or revert*\n" + ($flag_lines | rtrimstr("\n"))) } } ]
                 + (if $flagged > $max then
                      [ { type: "context", elements: [ { type: "mrkdwn",
                          text: "\($flagged - $max) more not shown" } ] } ]
                    else [] end)
               else [] end)
            + (if ($issue_url | length) > 0 or ($run_url | length) > 0 then
                 [ { type: "context", elements: [ { type: "mrkdwn",
                     text: ([ (if ($issue_url | length) > 0 then "<\($issue_url)|report issue>" else empty end),
                              (if ($run_url | length) > 0 then "<\($run_url)|full report>" else empty end) ]
                            | join("  ·  ")) } ] } ]
               else [] end)
          )
        }')

  if [[ "${SLACK_PAYLOAD_ONLY:-false}" == "true" ]]; then
    echo "$payload"
    return 0
  fi

  local response
  response=$(curl -sS -X POST https://slack.com/api/chat.postMessage \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    -H 'Content-type: application/json; charset=utf-8' \
    --data "$payload")

  # Slack answers HTTP 200 even when it refuses, so the ok field is the real status.
  if [[ "$(jq -r '.ok' <<<"$response")" != "true" ]]; then
    echo "Slack rejected the message: ${response}" >&2
    return 1
  fi
  echo "Posted the digest to ${SLACK_CHANNEL}."
}

post_to_slack

exit 0
