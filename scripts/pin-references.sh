#!/bin/sh
# Rewrites every `uses: <owner>/reusable-github-actions/...@<ref>` reference
# in a workflow file to a full commit SHA with a trailing version comment.
#
# Runs twice by design (see issue #47): wave 1 pins `@main` to the freeze tag
# `0.0.1`, wave 2 re-pins the `0.0.1` SHA to the `0.1.0` SHA once the fixes
# behind the freeze have landed. Both are "already has some ref, replace it
# with another", so the same rewrite handles an unpinned `@main` and an
# already-pinned-but-outdated SHA identically: it does not care what the
# previous ref was, only what file and line matched the reference pattern.
#
# Also rewrites the legacy `jackd248/reusable-github-actions` owner to
# `konradmichalik/reusable-github-actions` in the same pass, since `jackd248`
# is this project's former GitHub username and not a repository to keep
# pinning against.
#
# Usage:
#   scripts/pin-references.sh <version> [--write] [file ...]
#
#   <version>   A tag of konradmichalik/reusable-github-actions, e.g. 0.1.0
#   --write     Apply changes. Without it, prints a diff and changes nothing
#   file ...    Workflow files to rewrite. Defaults to every *.yml and
#               *.yaml under .github/workflows in the current directory
#
# Requires: gh (authenticated), git (for the diff in dry-run mode)
#
# Exit codes:
#   0   ran to completion (dry-run or write)
#   1   usage error
#   2   could not resolve <version> to a commit SHA
#   3   a matched file could not be parsed; reported on stderr, run continues

set -eu

repo="konradmichalik/reusable-github-actions"
reference_pattern='(konradmichalik|jackd248)/reusable-github-actions'

version="${1:-}"
if [ -z "$version" ]; then
  echo "usage: $0 <version> [--write] [file ...]" >&2
  exit 1
fi
shift

write=false
if [ "${1:-}" = "--write" ]; then
  write=true
  shift
fi

ref_json=$(gh api "repos/$repo/git/ref/tags/$version" 2>/dev/null) || ref_json=""
if [ -z "$ref_json" ]; then
  echo "error: could not resolve tag '$version' on $repo to a commit SHA" >&2
  exit 2
fi
sha=$(echo "$ref_json" | jq -r '.object.sha')
obj_type=$(echo "$ref_json" | jq -r '.object.type')
if [ "$obj_type" = "tag" ]; then
  # Annotated tag object, not a commit yet: dereference once more.
  sha=$(gh api "repos/$repo/git/tags/$sha" --jq '.object.sha')
fi
comment="$version"

files="$*"
if [ -z "$files" ]; then
  files=$(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null)
fi

if [ -z "$files" ]; then
  echo "no workflow files found" >&2
  exit 0
fi

parse_failures=0

for file in $files; do
  [ -f "$file" ] || continue

  if ! grep -qE "uses:.*${reference_pattern}" "$file"; then
    continue
  fi

  tmp=$(mktemp)
  # Matches `uses: <owner>/reusable-github-actions/<path>@<anything>` and
  # rewrites owner, sha and trailing version comment in one pass. Anything
  # already on the line after the ref (a pre-existing comment, trailing
  # whitespace) is dropped and replaced, so re-running never accumulates
  # duplicate comments.
  if ! sed -E \
    "s#(uses: )(konradmichalik|jackd248)(/reusable-github-actions/[^@[:space:]]*)@[^[:space:]]*.*#\\1konradmichalik\\3@${sha} \\# ${comment}#" \
    "$file" > "$tmp"; then
    echo "error: could not parse $file, skipped" >&2
    parse_failures=$((parse_failures + 1))
    rm -f "$tmp"
    continue
  fi

  if cmp -s "$file" "$tmp"; then
    rm -f "$tmp"
    continue
  fi

  if [ "$write" = true ]; then
    mv "$tmp" "$file"
    echo "rewrote $file"
  else
    echo "--- $file (dry run, no changes written) ---"
    diff -u "$file" "$tmp" || true
    rm -f "$tmp"
  fi
done

if [ "$parse_failures" -gt 0 ]; then
  exit 3
fi
