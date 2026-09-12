#!/bin/sh
# Renders the tab-separated output of find-consumers.sh as docs/inventory.md.
#
# Split from find-consumers.sh so the scan stays a plain data source, and so a
# formatting change never means re-running a scan that takes minutes and makes
# hundreds of API calls.
#
# Usage:
#   scripts/find-consumers.sh | scripts/render-inventory.sh > docs/inventory.md
#
# Reads the six columns find-consumers.sh emits, in that order:
#   consumer<TAB>caller-file<TAB>referenced-repo<TAB>referenced-path<TAB>ref<TAB>visibility

set -eu

rows=$(mktemp)
trap 'rm -f "$rows"' EXIT INT TERM
cat > "$rows"

if [ ! -s "$rows" ]; then
  echo "error: no input on stdin" >&2
  exit 1
fi

references=$(wc -l < "$rows" | tr -d ' ')
consumers=$(cut -f1 "$rows" | sort -u | wc -l | tr -d ' ')
owners=$(cut -f1 "$rows" | cut -d/ -f1 | sort -u | paste -sd, - | sed 's/,/, /g')
unpinned=$(awk -F'\t' '$5=="main"' "$rows" | wc -l | tr -d ' ')
private_list=$(awk -F'\t' 'tolower($6)=="private" {print $1}' "$rows" | sort -u)
private_count=$(printf '%s' "$private_list" | grep -c . || true)

cat <<HEADER
# Consumer inventory

Generated. Do not edit by hand: re-run

\`\`\`sh
scripts/find-consumers.sh | scripts/render-inventory.sh > docs/inventory.md
\`\`\`

and commit the result. \`find-consumers.sh\` exits non-zero and names every
repository it could not inspect, so a run that exits 0 is the only one whose
output is complete enough to drive a pin rollout.

Authoritative as of $(date +%Y-%m-%d), produced by walking \`.github/workflows/*.yml\`
of every non-archived repository under each owner directly via the GitHub contents
API. GitHub's code search index was checked first and found to be non-exhaustive
(known consumers were absent from its results), so this list does not rely on it.

## Summary

- **$consumers** consumer repositories, **$references** \`uses:\` references
- **$unpinned** of those references are still on \`@main\`
- Owners: $owners
HEADER

if [ "$private_count" -gt 0 ]; then
  printf -- '- **%s** private: %s\n' "$private_count" "$(printf '%s' "$private_list" | paste -sd, - | sed 's/,/, /g')"
fi

cat <<'SECTION'

## References by workflow

| Workflow | References |
|---|---|
SECTION
awk -F'\t' '{n=split($4,p,"/"); print p[n]}' "$rows" | sort | uniq -c | sort -rn |
  awk '{printf "| `%s` | %d |\n", $2, $1}'

legacy=$(awk -F'\t' '$3 ~ /^jackd248\// {n=split($4,p,"/"); printf "| %s | `%s` | `%s` |\n", $1, $2, p[n]}' "$rows" | sort)
if [ -n "$legacy" ]; then
  legacy_count=$(printf '%s\n' "$legacy" | grep -c .)
  cat <<SECTION

## Legacy \`jackd248/reusable-github-actions\` references

\`jackd248\` is this project's own former GitHub username before a rename to
\`konradmichalik\`, not a third-party fork. The reference still resolves today via
GitHub's username-rename redirect, which is not something to rely on: if someone
else ever registers that username, these references break silently.
$legacy_count reference(s) need rewriting to \`konradmichalik/reusable-github-actions\`.

| Consumer | Caller file | Referenced workflow |
|---|---|---|
$legacy
SECTION
fi

deprecated=$(awk -F'\t' '{n=split($4,p,"/"); if (p[n]=="tests.yml") print "- `" $1 "`"}' "$rows" | sort -u)
if [ -n "$deprecated" ]; then
  cat <<SECTION

## Deprecated \`tests.yml\` callers

See #39. \`tests.yml\` is superseded by \`tests-typo3.yml\` and scheduled for removal
in \`0.3.0\`. Migration is a one-line change of the \`uses:\` path.

$deprecated
SECTION
fi

cat <<'SECTION'

## Full detail

| Consumer | Visibility | Caller file | Referenced workflow | Ref |
|---|---|---|---|---|
SECTION
awk -F'\t' '{
  n = split($4, p, "/")
  ref = $5
  if ($3 ~ /^jackd248\//) ref = ref " (legacy owner)"
  printf "| %s | %s | `%s` | `%s` | `%s` |\n", $1, tolower($6), $2, p[n], ref
}' "$rows" | sort
