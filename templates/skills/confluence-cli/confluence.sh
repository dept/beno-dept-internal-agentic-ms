#!/usr/bin/env bash
set -euo pipefail
# Confluence Cloud from the terminal via the REST API (curl + jq).
# There is no dedicated binary and no Atlassian MCP — this wraps the v1 content API.
#
# Auth (set in your shell / ~/.zshrc; never hardcode):
#   export CONFLUENCE_SITE="https://dept-nl.atlassian.net"   # no trailing slash, no /wiki
#   export CONFLUENCE_EMAIL="you@deptagency.com"
#   export CONFLUENCE_TOKEN="<API token from id.atlassian.com/manage-profile/security/api-tokens>"
#
# Usage:
#   confluence.sh me                          # verify auth
#   confluence.sh find   <SPACE> <title>      # page id + version for an exact title
#   confluence.sh get    <id>                 # page metadata (title, version, space)
#   confluence.sh body   <id> > page.html     # current storage-format body
#   confluence.sh create <SPACE> <parentId> <title> <bodyFile>
#   confluence.sh title  <id> <newTitle>      # rename (auto-bumps version)
#   confluence.sh setbody<id> <bodyFile>      # replace body (auto-bumps version, keeps title)
#   confluence.sh rm     <id>                 # delete (trash)

API="${CONFLUENCE_SITE:?set CONFLUENCE_SITE}/wiki/rest/api"
AUTH="${CONFLUENCE_EMAIL:?set CONFLUENCE_EMAIL}:${CONFLUENCE_TOKEN:?set CONFLUENCE_TOKEN}"
J=(curl -sf -u "$AUTH" -H "Content-Type: application/json")

# Fetch title + current version for a page (used by every update to bump the version).
_meta() { "${J[@]}" "$API/content/$1?expand=version"; }

cmd="${1:-}"; shift || true
case "$cmd" in
  me)
    "${J[@]}" "$API/space?limit=1" >/dev/null && echo "auth OK for $CONFLUENCE_EMAIL @ $CONFLUENCE_SITE" ;;
  find)
    # exact-title lookup within a space
    "${J[@]}" --data-urlencode "spaceKey=$1" --data-urlencode "title=$2" \
      --data-urlencode "expand=version" -G "$API/content" \
      | jq -r '.results[]? | "\(.id)\tv\(.version.number)\t\(.title)"' ;;
  get)   _meta "$1" | jq '{id, title, version: .version.number, space: .space.key}' ;;
  body)  "${J[@]}" "$API/content/$1?expand=body.storage" | jq -r '.body.storage.value' ;;
  create)
    space="$1"; parent="$2"; title="$3"; bodyfile="$4"
    jq -n --arg t "$title" --arg s "$space" --arg p "$parent" --rawfile b "$bodyfile" \
      '{type:"page", title:$t, space:{key:$s}, ancestors:[{id:$p}],
        body:{storage:{value:$b, representation:"storage"}}}' \
      | "${J[@]}" -X POST "$API/content" -d @- \
      | jq -r '"created \(.id): \(.title)"' ;;
  title)
    id="$1"; new="$2"; ver=$(_meta "$id" | jq -r '.version.number'); next=$((ver + 1))
    jq -n --arg id "$id" --arg t "$new" --argjson v "$next" \
      '{id:$id, type:"page", title:$t, version:{number:$v}}' \
      | "${J[@]}" -X PUT "$API/content/$id" -d @- \
      | jq -r '"retitled \(.id) -> \(.title) (v\(.version.number))"' ;;
  setbody)
    id="$1"; bodyfile="$2"; m=$(_meta "$id"); ver=$(echo "$m" | jq -r '.version.number')
    title=$(echo "$m" | jq -r '.title'); next=$((ver + 1))
    jq -n --arg id "$id" --arg t "$title" --argjson v "$next" --rawfile b "$bodyfile" \
      '{id:$id, type:"page", title:$t, version:{number:$v},
        body:{storage:{value:$b, representation:"storage"}}}' \
      | "${J[@]}" -X PUT "$API/content/$id" -d @- \
      | jq -r '"updated body \(.id) (v\(.version.number))"' ;;
  rm)    "${J[@]}" -X DELETE "$API/content/$1" && echo "deleted $1" ;;
  *) echo "unknown command: $cmd (see header for usage)" >&2; exit 1 ;;
esac
