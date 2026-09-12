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
#   owner/repo<TAB>caller-file<TAB>referenced-owner/repo<TAB>referenced-workflow-path<TAB>ref<TAB>visibility
#
# Exit codes:
#   0   every repository under every owner was inspected successfully
#   1   usage or environment error
#   4   at least one repository could not be inspected; each is named on
#       stderr. The output is INCOMPLETE and must not be used to drive a
#       pin rollout, because a repository missing from it looks exactly
#       like a repository that does not reference this project.
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

# Throwaway repositories that intentionally reference this project without
# being real consumers: the canary (issue #48, always on @main by design)
# and any scratch spike repository (issue #37, #43 and future spikes).
# Pinning these would be wrong on two counts: the canary's whole purpose is
# to stay unpinned, and spike repositories are meant to be archived or
# deleted, not tracked as ongoing consumers.
excluded_repos='reusable-github-actions-canary spike-uses-resolution spike-pages-workflow'

is_excluded() {
  for excluded in $excluded_repos; do
    [ "$1" = "$excluded" ] && return 0
  done
  return 1
}

# The repository walk runs inside pipeline subshells, so a failure counter in
# a shell variable would not survive back to the parent. Failures are appended
# to this file instead and evaluated once at the end.
failures=$(mktemp)
api_error=$(mktemp)
trap 'rm -f "$failures" "$api_error"' EXIT INT TERM

# Records one inspection failure, both for the operator to see immediately and
# for the exit-code check at the end. A silently dropped repository is
# indistinguishable from one that does not reference this project, which is
# precisely the failure this script must never produce.
record_failure() {
  echo "warning: $1" >&2
  echo "$1" >> "$failures"
}

for owner in $owners; do
  if ! repos=$(gh repo list "$owner" -L 500 --json name,isArchived,visibility --jq '.[] | select(.isArchived==false) | [.name, .visibility] | @tsv' 2>"$api_error"); then
    record_failure "could not list repositories of owner '$owner': $(tr '\n' ' ' < "$api_error")"
    continue
  fi
  if [ -z "$repos" ]; then
    record_failure "owner '$owner' returned no repositories, which is never correct for a configured owner"
    continue
  fi

  echo "$repos" | while IFS="$(printf '\t')" read -r repo repo_visibility; do
    [ -z "$repo" ] && continue
    is_excluded "$repo" && continue
    slug="$owner/$repo"

    if ! files=$(gh api "repos/$slug/contents/.github/workflows" --jq '.[]? | select(.type=="file") | select(.name | test("\\.ya?ml$")) | .name' 2>"$api_error"); then
      # A 404 is the expected, legitimate answer for a repository that simply
      # has no .github/workflows directory. Anything else (rate limit, network,
      # permissions) means we do not know whether this repository is a consumer.
      if ! grep -q 'HTTP 404' "$api_error"; then
        record_failure "could not list workflows of $slug: $(tr '\n' ' ' < "$api_error")"
      fi
      continue
    fi
    [ -z "$files" ] && continue

    echo "$files" | while IFS= read -r file; do
      [ -z "$file" ] && continue
      if ! encoded=$(gh api "repos/$slug/contents/.github/workflows/$file" --jq '.content' 2>"$api_error"); then
        record_failure "could not read $slug/.github/workflows/$file: $(tr '\n' ' ' < "$api_error")"
        continue
      fi
      if ! content=$(echo "$encoded" | base64 -d 2>/dev/null); then
        record_failure "could not decode $slug/.github/workflows/$file"
        continue
      fi

      echo "$content" | grep -E "uses:.*${reference_pattern}" | while IFS= read -r line; do
        referenced_owner_repo=$(echo "$line" | grep -oE "${reference_pattern}")
        workflow_path=$(echo "$line" | sed -E 's#.*reusable-github-actions/([^@[:space:]]*)@.*#\1#')
        ref=$(echo "$line" | sed -E 's#.*reusable-github-actions/[^@[:space:]]*@([^[:space:]]*).*#\1#')
        printf '%s\t.github/workflows/%s\t%s\t%s\t%s\t%s\n' "$slug" "$file" "$referenced_owner_repo" "$workflow_path" "$ref" "$repo_visibility"
      done
    done
  done
done

if [ -s "$failures" ]; then
  echo "" >&2
  echo "error: $(wc -l < "$failures" | tr -d ' ') repository inspection(s) failed, listed above." >&2
  echo "The output above is INCOMPLETE. Re-run until this exits 0 before using it to pin consumers." >&2
  exit 4
fi
