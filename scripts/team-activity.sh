#!/usr/bin/env bash
# Lists who has recently worked on a repository, to fill or refresh the `## Team` table in
# project-context.md.
#
#   bash scripts/team-activity.sh <org/repo> [--days N] [--branch B]
#   bash scripts/team-activity.sh --self-test
#
# Reads GitHub with `gh` (needs read access to contents and pull requests): commit authors on
# the branch, pull request authors and reviewers, and the members of any team named in
# CODEOWNERS. Bots are dropped. Prints a markdown table sorted by last activity, with a
# suggested role per person. Suggestions are a starting point for a human, never the answer:
# activity says who touches the code, not who the client manager or delivery lead is.
set -euo pipefail

days=180 repo="" branch=""

# Input: TSV lines "kind<TAB>login<TAB>name<TAB>date", kind in commit|pr|review|owner.
# Output: TSV "key<TAB>login (- when unlinked)<TAB>commits<TAB>prs<TAB>reviews<TAB>last<TAB>role", newest first.
aggregate() {
  awk -F'\t' '
    $2 ~ /\[bot\]$/ || $3 ~ /\[bot\]$/ || tolower($2) ~ /^(dependabot|renovate|github-actions|copilot)/ { next }
    {
      # ponytail: an unlinked email is keyed by git name, so one person with a linked and an
      # unlinked email shows as two rows; a human merges them when confirming the table.
      key = ($2 != "") ? $2 : "~" $3
      if (key == "~") next
      login[key] = $2
      if ($1 == "commit") c[key]++
      else if ($1 == "pr") p[key]++
      else if ($1 == "review") r[key]++
      else if ($1 == "owner") o[key] = 1
      if ($4 > last[key]) last[key] = $4
      seen[key] = 1
    }
    END {
      top = ""; topn = 0
      for (k in seen) if (r[k] > topn || (r[k] == topn && topn > 0 && k < top)) { topn = r[k]; top = k }
      for (k in seen) {
        if (k == top && topn >= 3) role = "Tech lead (candidate: most reviews)"
        else if (c[k] + p[k] > 0) role = "Developer"
        else if (r[k] > 0) role = "Reviewer"
        else role = "Code owner, no recent activity"
        printf "%s\t%s\t%d\t%d\t%d\t%s\t%s\n", k, (login[k] == "" ? "-" : login[k]), c[k], p[k], r[k], (last[k] == "" ? "-" : substr(last[k], 1, 10)), role
      }
    }' | sort -t$'\t' -k6,6r
}

self_test() {
  local out
  out=$(printf '%s\n' \
    $'commit\talice\tAlice\t2026-10-01T10:00:00Z' \
    $'commit\talice\tAlice\t2026-11-01T10:00:00Z' \
    $'pr\talice\t\t2026-11-02T10:00:00Z' \
    $'review\tbob\t\t2026-11-03T10:00:00Z' \
    $'review\tbob\t\t2026-11-04T10:00:00Z' \
    $'review\tbob\t\t2026-11-05T10:00:00Z' \
    $'review\tcarol\t\t2026-09-01T10:00:00Z' \
    $'owner\tdave\t\t' \
    $'commit\t\tUnlinked Person\t2026-08-01T10:00:00Z' \
    $'commit\tdependabot[bot]\t\t2026-11-10T10:00:00Z' \
    $'commit\t\trenovate[bot]\t2026-11-10T10:00:00Z' \
    $'review\terin\t\t2026-11-06T10:00:00Z' \
    $'review\terin\t\t2026-11-06T10:00:00Z' \
    $'review\terin\t\t2026-11-06T10:00:00Z' \
    $'review\tcopilot-pull-request-reviewer\t\t2026-11-10T10:00:00Z' | aggregate)
  grep -q $'^bob\tbob\t0\t0\t3\t2026-11-05\tTech lead' <<<"$out" || { echo "FAIL tech lead: $out" >&2; exit 1; }
  grep -q $'^alice\talice\t2\t1\t0\t2026-11-02\tDeveloper$' <<<"$out" || { echo "FAIL developer: $out" >&2; exit 1; }
  grep -q $'^carol\tcarol\t0\t0\t1\t2026-09-01\tReviewer$' <<<"$out" || { echo "FAIL reviewer: $out" >&2; exit 1; }
  grep -q $'^dave\tdave\t0\t0\t0\t-\tCode owner, no recent activity$' <<<"$out" || { echo "FAIL owner: $out" >&2; exit 1; }
  grep -q $'^~Unlinked Person\t-\t1\t' <<<"$out" || { echo "FAIL unlinked: $out" >&2; exit 1; }
  ! grep -qi 'bot\|copilot' <<<"$out" || { echo "FAIL bots kept: $out" >&2; exit 1; }
  grep -q $'^erin\terin\t0\t0\t3\t2026-11-06\tReviewer$' <<<"$out" || { echo "FAIL tie-break: $out" >&2; exit 1; }
  [[ $(head -1 <<<"$out" | cut -f1) == erin ]] || { echo "FAIL order: $out" >&2; exit 1; }
  echo "team-activity self-test: ok"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) days="$2"; shift 2 ;;
    --branch) branch="$2"; shift 2 ;;
    --self-test) self_test; exit 0 ;;
    -*) echo "team-activity: unknown option $1" >&2; exit 2 ;;
    *) repo="$1"; shift ;;
  esac
done

if [[ ! "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ || ! "$days" =~ ^[0-9]+$ ]]; then
  echo "usage: team-activity.sh <org/repo> [--days N] [--branch B] | --self-test" >&2
  exit 2
fi
command -v gh >/dev/null || { echo "team-activity: gh CLI not found" >&2; exit 1; }

since=$(date -u -v-"${days}"d +%Y-%m-%d 2>/dev/null || date -u -d "${days} days ago" +%Y-%m-%d)
[[ -n "$branch" ]] || branch=$(gh api "repos/$repo" --jq .default_branch)

raw=$(mktemp); trap 'rm -f "$raw"' EXIT

# Commits on the branch. A commit whose email is not linked to a GitHub account has no login;
# it is kept under the git author name.
gh api --paginate "repos/$repo/commits?sha=$branch&since=${since}T00:00:00Z&per_page=100" \
  --jq '.[] | ["commit", (.author.login // ""), .commit.author.name, .commit.author.date] | @tsv' >>"$raw"

# Pull requests touched in the window: authors of those opened in it, and reviews submitted in it
# by someone other than the author (replies on your own pull request are reviews too).
gh pr list -R "$repo" --state all --search "updated:>=$since" --limit 500 \
  --json author,createdAt,reviews \
  --jq ".[] | (select(.createdAt >= \"$since\") | [\"pr\", .author.login, \"\", .createdAt] | @tsv),
              (.author.login as \$a | .reviews[] | select(.submittedAt >= \"$since\" and .author.login != \$a) | [\"review\", .author.login, \"\", .submittedAt] | @tsv)" >>"$raw"

# Members of teams named in CODEOWNERS. Listing team members needs org read access the token
# may lack; a failure is noted, not fatal.
owners_note=""
for f in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do
  co=$(gh api "repos/$repo/contents/$f?ref=$branch" --jq .content 2>/dev/null | base64 -d 2>/dev/null) || continue
  for team in $(grep -v '^#' <<<"$co" | grep -oE '@[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' | sort -u); do
    org=${team#@}; org=${org%%/*}; slug=${team#*/}
    if members=$(gh api --paginate "orgs/$org/teams/$slug/members" --jq '.[].login' 2>/dev/null); then
      while read -r m; do [[ -n "$m" ]] && printf 'owner\t%s\t\t\n' "$m" >>"$raw"; done <<<"$members"
    else
      owners_note+=" ${team} (members not readable)"
    fi
  done
  break
done

rows=$(aggregate <"$raw")

echo "Activity on \`$repo\` branch \`$branch\` since $since (pull requests on all branches)."
echo
echo "| Name | GitHub | Commits | PRs | Reviews | Last active | Suggested role |"
echo "|---|---|---|---|---|---|---|"
while IFS=$'\t' read -r key login c p r last role; do
  [[ -n "$key" ]] || continue
  if [[ "$login" != "-" ]]; then
    name=$(gh api "users/$login" --jq '.name // ""' 2>/dev/null || true)
    echo "| ${name:-$login} | @$login | $c | $p | $r | $last | $role |"
  else
    echo "| ${key#\~} | - (email not linked) | $c | $p | $r | $last | $role |"
  fi
done <<<"$rows"
[[ -z "$owners_note" ]] || { echo; echo "CODEOWNERS:${owners_note}"; }
