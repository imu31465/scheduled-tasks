#!/usr/bin/env bash
# pandra_mark.sh — append SHAs to tested-shas.txt on the pandra-tested
# branch of this (scheduled-tasks) repository.
#
# The marker branch is the "already tested" ledger of the pandra-ci
# mirror: the detect step skips any SHA listed there.  Pushes use the
# job's GITHUB_TOKEN (workflow needs contents: write), so no PAT is
# stored anywhere.
#
# Usage: pandra_mark.sh <sha> [sha ...]
# Env:   GITHUB_TOKEN, GITHUB_REPOSITORY
set -euo pipefail

shas=("$@")
[ "${#shas[@]}" -eq 0 ] && { echo "nothing to mark"; exit 0; }

remote="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

git -C "$work" init -q
git -C "$work" fetch -q --depth 1 "$remote" pandra-tested
git -C "$work" checkout -q FETCH_HEAD
git -C "$work" config user.name 'pandra-ci bot'
git -C "$work" config user.email 'actions@github.com'

added=0
for sha in "${shas[@]}"; do
  if grep -qx "$sha" "$work/tested-shas.txt" 2>/dev/null; then
    echo "already marked: $sha"
  else
    echo "$sha" >> "$work/tested-shas.txt"
    echo "marking: $sha"
    added=$((added + 1))
  fi
done
[ "$added" -eq 0 ] && { echo "no new marks"; exit 0; }

# keep the ledger bounded (most recent 1000 entries)
tail -n 1000 "$work/tested-shas.txt" > "$work/tested-shas.txt.tmp" && mv "$work/tested-shas.txt.tmp" "$work/tested-shas.txt"

git -C "$work" add tested-shas.txt
git -C "$work" commit -q -m "pandra-ci: mark ${added} SHA(s) tested"
git -C "$work" push -q "$remote" "HEAD:refs/heads/pandra-tested"
echo "pushed marker branch (+${added})"
