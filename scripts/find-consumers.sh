#!/bin/sh
# Finds every repository that references this project's reusable workflows,
# across every owner passed in, and writes one row per reference to stdout.
#
# GitHub's code search index is not exhaustive (verified: repositories known
# to reference this project were absent from `gh search code` results), so
# this walks `.github/workflows/*.yml` of every non-archived repository
# directly via the contents API instead of trusting the search index.
#
# Usage:
#   scripts/find-consumers.sh [owner ...]
#
# Requires: gh (authenticated), jq
#
# Output columns (tab-separated), one row per `uses:` reference found:
#   owner/repo<TAB>caller-file<TAB>referenced-owner/repo<TAB>referenced-workflow-path<TAB>ref
#
# referenced-owner is reported as-is, including the legacy "jackd248" name,
# so callers of this script can detect which repositories still use it.
# referenced-workflow-path is the actual file inside this project being
# called (e.g. cgl-test.yml), which does not always match caller-file's own
# name: a consumer's own `cgl.yml` commonly calls this project's
# `cgl-test.yml`, so caller-file alone would misreport which reusable
# workflow is actually in use.

set -eu

owners="$*"
if [ -z "$owners" ]; then
  owners="konradmichalik move-elevator xima-media"
fi

reference_pattern='(konradmichalik|jackd248)/reusable-github-actions'

for owner in $owners; do
  repos=$(gh repo list "$owner" -L 500 --json name,isArchived --jq '.[] | select(.isArchived==false) | .name')

  echo "$repos" | while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    slug="$owner/$repo"

    files=$(gh api "repos/$slug/contents/.github/workflows" --jq '.[]? | select(.type=="file") | select(.name | test("\\.ya?ml$")) | .name' 2>/dev/null) || continue
    [ -z "$files" ] && continue

    echo "$files" | while IFS= read -r file; do
      [ -z "$file" ] && continue
      content=$(gh api "repos/$slug/contents/.github/workflows/$file" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null) || continue

      echo "$content" | grep -E "uses:.*${reference_pattern}" | while IFS= read -r line; do
        referenced_owner_repo=$(echo "$line" | grep -oE "${reference_pattern}")
        workflow_path=$(echo "$line" | sed -E 's#.*reusable-github-actions/([^@[:space:]]*)@.*#\1#')
        ref=$(echo "$line" | sed -E 's#.*reusable-github-actions/[^@[:space:]]*@([^[:space:]]*).*#\1#')
        printf '%s\t.github/workflows/%s\t%s\t%s\t%s\n' "$slug" "$file" "$referenced_owner_repo" "$workflow_path" "$ref"
      done
    done
  done
done
