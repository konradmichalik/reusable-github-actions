# AGENTS.md

## Project overview

Reusable GitHub Actions workflows for PHP projects (TYPO3 extensions, PHP libraries, PHP CLI tools). Consumers call them with `workflow_call`. The scope is deliberate: no JavaScript-specific workflows will be added. `release.yml` contains no PHP and stays usable by any repository that tags.

The repository is a stability contract for its consumers. Read `docs/stability.md` before changing any workflow input, secret, default or job name.

## Structure

- `.github/workflows/`: the reusable workflows (`cgl.yml`, `cgl-test.yml`, `tests.yml` deprecated, `tests-php.yml`, `tests-typo3.yml`, `release.yml`, `release-typo3.yml`, `security.yml`, `scorecard.yml`, `pages.yml`) plus this repository's own `ci.yml` and `self-release.yml` (not callable by consumers)
- `scripts/`: `check-relative-uses.py`, `pin-references.sh`, `find-consumers.sh`, `render-inventory.sh`
- `docs/`: `stability.md` (versioning and pinning contract), `canary.md` (pre-release testing), `actions.md` (why a workflow cannot test itself), `inventory.md` (consumer inventory)
- `zizmor.yml`: zizmor ignores, each tied to an open issue
- `renovate.json`: extends the shared `konradmichalik/renovate-config` preset

## Development commands

There is no build step. The workflows are validated by CI and by the canary repository `konradmichalik/reusable-github-actions-canary`.

```bash
actionlint
zizmor .github/workflows/
shellcheck -s sh scripts/*.sh
python3 scripts/check-relative-uses.py
```

## Testing

A reusable workflow cannot test the working tree of the repository that defines it, so there is no unit test suite. Linters answer whether a workflow is valid, the canary answers whether it still works. A release is not tagged until the canary has exercised every workflow against the commit being tagged.

## Code style and linting

CI (`.github/workflows/ci.yml`, on pushes to `main` and pull requests) runs:

- `actionlint`
- `zizmor` on `.github/workflows/`
- `shellcheck -s sh scripts/*.sh`
- `scripts/check-relative-uses.py`: step-level `uses: ./...` is forbidden because it resolves against the caller's checkout
- a check that every third-party action is pinned to a full 40-character commit SHA (local `./` and `sha256:` refs are exempt)

Rules that follow from this:

- Pin every action to a full commit SHA with a trailing version comment
- Keep workflow permissions minimal (`permissions: {}` at top level, grant per job) and set `persist-credentials: false` on checkout
- Scripts are POSIX `sh`
- `.editorconfig`: UTF-8, LF, 4 spaces (2 for YAML), final newline

## Stability rules

- Semantic versioning applies to the reusable workflows. Removing an input or secret, changing a default, adding a required input, renaming a job or changing behaviour consumers depend on is a breaking change
- Released tags are never moved. Fix forward with a new patch tag. There is no floating major tag
- Consumers pin `uses:` to a commit SHA with a version comment
- Caller trigger convention for CI-style workflows: `push` on `main` and `renovate/**`, plus `pull_request`. Never `push` on all branches

## Git workflow

- Commit format: `<type>: <description>` with `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`
- No co-author trailers
