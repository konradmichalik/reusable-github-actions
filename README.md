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

## CGL

Comprehensive code quality workflow that validates composer dependencies, runs linting (PHP, composer.json, editorconfig), performs static code analysis and checks rector migrations.

```yaml
name: CGL
on:
  push:
    branches:
      - '**'

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
    branches:
      - '**'

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
    branches:
      - '**'
        

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
    branches:
      - '**'

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
    branches:
      - '**'

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
