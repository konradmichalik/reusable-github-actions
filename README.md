<div align="center">

# Reusable GitHub Actions

[![License](https://img.shields.io/github/license/konradmichalik/reusable-github-actions)](LICENSE)
[![Workflows](https://img.shields.io/badge/workflows-8-green)]()
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/konradmichalik/reusable-github-actions/badge)](https://securityscorecards.dev/viewer/?uri=github.com/konradmichalik/reusable-github-actions)

</div>

This repository provides useful GitHub Action workflows.

> [!IMPORTANT]
> This package is intended for use in my personal projects only. It is not designed for general use.

## 🧩 Workflows

- [CGL](#cgl)
- [CGL (Test)](#cgl-test)
- [Tests](#tests)
- [Tests TYPO3](#tests-typo3)
- [Release](#release)
- [Release TYPO3](#release-typo3)
- [Security](#security)
- [OpenSSF Scorecard](#openssf-scorecard)

## Caller trigger convention

Trigger CI-style workflows (`cgl.yml`, `cgl-test.yml`, `tests-php.yml`, `tests-typo3.yml`, `security.yml`) with:

```yaml
on:
  push:
    branches: [main]
  pull_request: ~
```

**Not** `push` with `branches: ['**']`. That pattern, seen across several consumers of this layer, runs the full matrix on every push to every branch, and then a *second* time when a pull request from that branch is opened or updated: the branch-push event and the pull request event both fire and both trigger the workflow. They don't run the literal same commit — `push` runs the commit as pushed, `pull_request` runs GitHub's synthetic merge of it into the target branch — but for a feature branch with no conflicting changes on the target, that difference rarely matters in practice, and the two runs are overlapping validation of the same branch update, paid for twice. For a workflow with an 18-job matrix, that is 18 duplicate jobs on every PR update.

`push: [main]` plus `pull_request` avoids the duplication: feature-branch work is validated once, by the pull request event; `main` itself is validated on every push to it (merges, direct commits). This is also why [OpenSSF Scorecard](#openssf-scorecard) needs its own, different trigger below — its guard exists specifically because `push: ['**']` would otherwise add a guaranteed-red check to every feature branch.

**Verified, not assumed:** none of this layer's 39 consumers has a branch protection rule or ruleset that depends on a check running on a direct push to a non-default branch. The one consumer with a `required_status_checks` rule (`move-elevator/typo3-login-warning`, gating `cgl / cgl`) requires it on the `pull_request` event, which this convention still provides — switching away from `push: ['**']` does not remove that check, only the redundant duplicate of it. Rulesets are unavailable on private repositories on the free plan, which by itself already rules out branch-scoped protection rules for four of the 39.

The concept behind this repository claimed the convention change "removes the need for a preparation workflow entirely". That does not hold up: the one real reference implementation of a `preparation` workflow found in a comparable third-party layer exists to gate execution on fork pull requests where secrets are unavailable, not to deduplicate push-vs-PR runs, and is unrelated to this convention. Independent of that, no workflow inside *this* repository could ever fix caller-side event duplication regardless of its design: GitHub evaluates a caller's own trigger conditions, and therefore whether a run happens at all, before any `uses:` reference in that caller is even resolved. The fix has to happen in the caller's `on:` block, which is exactly what this convention is.

## CGL

Comprehensive code quality workflow that validates composer dependencies, runs linting (PHP, composer.json, editorconfig), performs static code analysis and checks rector migrations.

```yaml
name: CGL
on:
  push:
    branches: [main]
  pull_request: ~

jobs:
    cgl:
        uses: konradmichalik/reusable-github-actions/.github/workflows/cgl.yml@main
```

Input|Type| Required |Description
-|-|----------|-
`php-version`|input| false    |PHP version to use for the CGL check. Defaults to `8.3`.

## CGL (Test)

Comprehensive code quality workflow that validates composer dependencies, runs linting (PHP, composer.json, editorconfig), performs static code analysis and checks rector migrations.

```yaml
name: CGL
on:
  push:
    branches: [main]
  pull_request: ~

jobs:
    cgl:
        uses: konradmichalik/reusable-github-actions/.github/workflows/cgl-test.yml@main
```

Input|Type| Required |Description
-|-|----------|-
`php-version`|input| false    |PHP version to use for the CGL check. Defaults to `8.3`.

## Tests

Matrix testing workflow that runs tests across multiple PHP versions with both highest and lowest dependencies. Includes optional coverage reporting to CodeClimate and Coveralls.

```yaml
name: Tests
on:
  push:
    branches: [main]
  pull_request: ~

jobs:
    tests:
        uses: konradmichalik/reusable-github-actions/.github/workflows/tests-php.yml@main
```

Input|Type| Required |Description
-|-|----------|-
`php-versions`|input| false    |PHP versions as JSON array. Defaults to `["8.2", "8.3", "8.4"]`.
`dependencies`|input| false    |Dependencies as JSON array. Defaults to `["highest", "lowest"]`.

## Tests TYPO3

Matrix testing workflow that runs tests across multiple PHP and TYPO3 versions with both highest and lowest dependencies. Includes optional coverage reporting to CodeClimate and Coveralls.

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request: ~

jobs:
    tests:
        uses: konradmichalik/reusable-github-actions/.github/workflows/tests-typo3.yml@main
```

Input|Type| Required |Description
-|-|----------|-
`php-versions`|input| false    |PHP versions as JSON array. Defaults to `["8.2", "8.3", "8.4"]`.
`typo3-versions`|input| false    |TYPO3 versions as JSON array. Defaults to `["11.5", "12.4", "13.4"]`.
`dependencies`|input| false    |Dependencies as JSON array. Defaults to `["highest", "lowest"]`.

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request: ~

jobs:
    tests:
        uses: konradmichalik/reusable-github-actions/.github/workflows/tests-typo3.yml@main
        with:
            php-versions: '["8.2", "8.3", "8.4"]'
            typo3-versions: '["11.5", "12.4", "13.4"]'
            dependencies: '["highest", "lowest"]'
```

### Optional Coverage Reporting

The Tests workflow includes optional coverage reporting to external services:

- **CodeClimate**: Set `CC_TEST_REPORTER_ID` secret to enable

If these secrets are not configured, the coverage steps will be skipped without causing workflow failures.

## Release

Automated release workflow that creates a new release on GitHub.

```yaml
name: Release

on:
  push:
    tags:
      - '*'

jobs:
  release:
        uses: konradmichalik/reusable-github-actions/.github/workflows/release.yml@main
        permissions:
          contents: write
```

> [!NOTE]
> The caller job must grant `contents: write` so the reusable can create the GitHub release. This is only required explicitly if the repository's default workflow token is set to read-only (recommended hardening).

## Release TYPO3

Automated release workflow for TYPO3 extension that creates a new release on GitHub and upload the extension artifact to the TER.

```yaml
name: Release

on:
  push:
    tags:
      - '*'

jobs:
  release:
        uses: konradmichalik/reusable-github-actions/.github/workflows/release-typo3.yml@main
        permissions:
          contents: write
        secrets:
          typo3-api-token: ${{ secrets.TYPO3_API_TOKEN }}
        with:
          typo3-extension-key: 'your_extension_key'
```

> [!NOTE]
> The caller job must grant `contents: write` so the reusable can create the GitHub release. This is only required explicitly if the repository's default workflow token is set to read-only (recommended hardening).

Input|Type| Required |Description
-|-|----------|-
`typo3-extension-key`|input| true    |TYPO3 extension key (as used in TER and GitHub repository name).
`vendor-bundling`|input| false    |Bundle non-TYPO3 vendor libraries for classic mode before packaging. Requires `eliashaeussler/typo3-vendor-bundler` in `require-dev` and a `bundle` composer script. Defaults to `false`.
`typo3-api-token`|secret| true    |TYPO3 API token with permission to upload to TER.

## Security

Secret scanning via [gitleaks](https://github.com/gitleaks/gitleaks). Runs on pushes and pull requests and fails the job if secrets are detected. Free for public and personal repositories (no `GITLEAKS_LICENSE` required).

```yaml
name: Security
on:
  push:
    branches:
      - main
  pull_request: ~

jobs:
  security:
    uses: konradmichalik/reusable-github-actions/.github/workflows/security.yml@main
    permissions:
      contents: read
```

## OpenSSF Scorecard

Supply-chain posture scoring via [OpenSSF Scorecard](https://github.com/ossf/scorecard) (branch protection, pinned actions, token permissions and more). Results are uploaded to the repository's code scanning dashboard.

> [!NOTE]
> Requires **Code Scanning** available (Settings → Advanced Security → Code scanning) for the SARIF upload — free on public repositories, needs GitHub Advanced Security on private ones. The published Scorecard badge requires a public repository.

> [!IMPORTANT]
> Trigger this workflow **only on the default branch**, on a schedule, and via manual dispatch — as shown below. The `scorecard-action` supports the default branch only and hard-fails on any other ref, so a wildcard trigger such as `push: branches: ['**']` would add a guaranteed-red check to every feature-branch push. The reusable now skips itself (neutral, not failed) on non-default branches as a safety net, but using the recommended trigger avoids the unnecessary runs entirely.

```yaml
name: OpenSSF Scorecard
on:
  push:
    branches:
      - main
  schedule:
    - cron: '0 0 * * 0'
  workflow_dispatch:

jobs:
  scorecard:
    uses: konradmichalik/reusable-github-actions/.github/workflows/scorecard.yml@main
    permissions:
      contents: read
      security-events: write
      id-token: write
      actions: read
```

## ⭐ License

This project is licensed under [GNU General Public License 3.0 (or later)](LICENSE).
