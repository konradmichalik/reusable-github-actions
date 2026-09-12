# Canary

[`konradmichalik/reusable-github-actions-canary`](https://github.com/konradmichalik/reusable-github-actions-canary), built for [issue #48](https://github.com/konradmichalik/reusable-github-actions/issues/48).

A reusable workflow cannot test the working tree of the repository that defines it (see `docs/actions.md`). Linters (`actionlint`, `zizmor`) answer "is this valid", not "does this still work". The canary is the only pre-release signal for the workflow layer: a throwaway consumer that deliberately stays on `@main`, calls every one of the nine reusable workflows, and is allowed to be red without costing anyone attention, because nobody depends on it.

Excluded on purpose from `docs/inventory.md` and from `scripts/find-consumers.sh`'s output (see the `excluded_repos` list in that script) — pinning the canary would defeat its purpose.

## Before merging a change to a reusable workflow

Point the canary's caller workflows at the branch under test (edit the `@main` refs in `konradmichalik/reusable-github-actions-canary/.github/workflows/*.yml` temporarily, or dispatch with a ref override), run `canary.yml` via `workflow_dispatch`, and confirm it is green before merging. Full detail on what calls what, and why the release path is split into two separate manually-dispatched files rather than one automatic one, is in that repository's own README.

## What the first real run found

Standing up the canary and getting it green surfaced five real things, none of them hypothetical:

1. **`typo3/cms-core` cannot currently be installed as a "highest dependency" for `tests-typo3.yml` or `tests.yml`.** Every published `^12.4`/`^13.4` release is affected by at least one open security advisory, and Composer's audit-blocking behaviour refuses to resolve any of them — `--no-audit` in the workflow's `composer-options` does not disable this, it only suppresses the separate `composer audit` report. Filed as its own issue; this is a live, currently-active break for every real consumer's "highest" lane, not a canary artefact.
2. **The Coveralls step's missing guard (#29) is not theoretical.** The canary's `tests-php.yml` run failed exactly as that issue predicts: no `if:`, no token, the step just runs and fails (`Failed to download coveralls binary or checksum`).
3. **`cgl-test.yml`'s integration contract was underdocumented.** `composer cgl lint:composer` invokes a script literally named `cgl`, forwarding its argument, not "the same script with a prefix". Real consumers define this themselves (a working example: `"cgl": "@composer -d Tests/CGL --"`, sandboxing tool versions in a nested `Tests/CGL` project). Worth adding to the README once `cgl.yml`/`cgl-test.yml` are merged per #32/#39, so a new consumer doesn't have to reverse-engineer this from a failure.
4. **`release-typo3.yml` requires a `packaging_exclude.php` file to exist,** or `tailor create-artefact` hard-fails (`VersionService.php line 220`). Real consumers already have one; it isn't documented anywhere in this repository's own README as a prerequisite.
5. **`release.yml` and `release-typo3.yml` both work end-to-end** when exercised against a real tag: the first succeeds outright, the second correctly fails only at the final TER-publish step against a deliberately-fake token (a real HTTP 500 from TER's own API, not a local error) — confirming the artefact build, tag validation and GitHub release steps all function correctly before that point.

Items 1 and 2 are tracked as issues. Items 3 and 4 are documentation gaps, worth folding into the README the next time it's touched.
