#!/usr/bin/env bash
# pandra_detect.sh — find Pandra commits that still need the mirror-CI suite.
#
# Candidates (deduped, main first, then open PRs by number):
#   * the tip of Pandra's main branch
#   * the head of every OPEN pull request whose head SHA also points at a
#     branch inside imu31465/Pandra (same-repo PRs; fork PRs never match a
#     refs/heads/* SHA and are skipped — the read-only deploy key could not
#     fetch them anyway)
# "Open" is detected WITHOUT any API token: GitHub only keeps a
# refs/pull/N/merge ref while PR N is open.
# A candidate that already appears in the marker file (tested-shas.txt on
# the pandra-tested branch) is skipped.
#
# Env:
#   PANDRA_GIT    ssh URL of Pandra (default git@github.com:imu31465/Pandra.git)
#   TESTED_FILE   path to tested-shas.txt (default: tested-shas.txt)
#   MAX           max SHAs to output (default 3)
# Outputs (GITHUB_OUTPUT):
#   count  number of untested SHAs selected
#   shas   JSON array of SHAs, e.g. ["abc...","def..."]
#   labels JSON array of parallel labels, e.g. ["main","pr-42"]
set -euo pipefail

PANDRA_GIT="${PANDRA_GIT:-git@github.com:imu31465/Pandra.git}"
TESTED_FILE="${TESTED_FILE:-tested-shas.txt}"
MAX="${MAX:-3}"

mapfile -t REFS < <(git ls-remote "$PANDRA_GIT" 'refs/heads/*' 'refs/pull/*/head' 'refs/pull/*/merge')

main_sha=""
branch_shas=""
merge_prs=""
for line in "${REFS[@]}"; do
  sha="${line%%$'\t'*}"
  ref="${line##*$'\t'}"
  case "$ref" in
    refs/heads/main) main_sha="$sha" ;;
    refs/heads/*)    branch_shas+="$sha"$'\n' ;;
    */merge)         merge_prs+="$(echo "$ref" | cut -d/ -f3)"$'\n' ;;
  esac
done
branch_set=$(printf '%s' "$branch_shas" | sort -u)

# tested SHAs (may not exist yet on a fresh marker branch)
tested=""
if [ -f "$TESTED_FILE" ]; then
  tested=$(grep -vE '^#|^[[:space:]]*$' "$TESTED_FILE" || true)
fi

is_tested() { printf '%s\n' "$tested" | grep -qx "$1"; }
is_branch() { printf '%s\n' "$branch_set" | grep -qx "$1"; }

shas_json='[]'
labels_json='[]'
count=0
add() { # add <sha> <label>
  local sha="$1" label="$2"
  [ "$count" -ge "$MAX" ] && return 0
  is_tested "$sha" && return 0
  # skip if this sha is already in this run's selection
  printf '%s' "$shas_json" | jq -e --arg s "$sha" 'index($s) != null' >/dev/null && return 0
  shas_json=$(printf '%s' "$shas_json" | jq -c --arg s "$sha" '. + [$s]')
  labels_json=$(printf '%s' "$labels_json" | jq -c --arg l "$label" '. + [$l]')
  count=$((count + 1))
  echo "candidate: $label $sha" >&2
}

if [ -n "$main_sha" ]; then add "$main_sha" "main"; fi
for pr in $(printf '%s' "$merge_prs" | sort -n); do
  head_sha=$(printf '%s\n' "${REFS[@]}" | awk -v n="$pr" -F'\t' '$2 == "refs/pull/" n "/head" {print $1}')
  [ -z "$head_sha" ] && continue
  if is_branch "$head_sha"; then
    add "$head_sha" "pr-$pr"
  else
    echo "skip pr-$pr: fork PR (head $head_sha matches no branch)" >&2
  fi
done

{
  echo "count=$count"
  echo "shas=$(printf '%s' "$shas_json" | jq -c .)"
  echo "labels=$(printf '%s' "$labels_json" | jq -c .)"
} >> "${GITHUB_OUTPUT:-/dev/null}"
echo "selected $count SHA(s)" >&2
