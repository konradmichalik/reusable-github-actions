<div align="center">

# Reusable GitHub Actions

[![License](https://img.shields.io/github/license/konradmichalik/reusable-github-actions)](LICENSE)
[![Workflows](https://img.shields.io/badge/workflows-10-green)]()
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
- [Tests (deprecated)](#tests-deprecated)
- [Release](#release)
- [Release TYPO3](#release-typo3)
- [Security](#security)
- [OpenSSF Scorecard](#openssf-scorecard)
- [Pages](#pages)

## Pinning

Pin every reference to a **full 40-character commit SHA**, with the version as a
trailing comment:

```yaml
jobs:
    cgl:
        uses: konradmichalik/reusable-github-actions/.github/workflows/cgl.yml@ac6ac4d7829d8e8f85956c7474ee3ff99b98c9ed # 0.0.1
```

The comment is not decoration. Renovate reads it as the current version, and rewrites
the SHA **and** the comment together when a new release lands. Drop it and Renovate
marks the reference `unversioned-reference` and stops updating it — you get an opaque
hash nobody can date and nothing to bump it.

Two details that matter, both verified against Renovate's
[github-actions manager](https://docs.renovatebot.com/modules/manager/github-actions/)
rather than assumed:

- **The version must start the comment.** `# 0.1.0` works, `# pinned to 0.1.0` does
  not — the leading prose stops it matching, and the reference silently degrades.
- **No Renovate configuration is required.** The manager recognises a job-level
  `uses:` as a reusable workflow on its own, and unprefixed tags like `0.1.0` are
  handled the same as `v`-prefixed ones. Nothing needs adding to your `renovate.json`.

**Not a tag, and there is no floating major.** A tag can be repointed at different
code after you reviewed it; released tags here are never moved, and no `v1`-style
moving tag is offered at all. With SHA pins plus Renovate a floating major buys
nothing an automated bump does not already give you, and a tag that can move would
defeat the audit trail pinning exists to provide — if `v1` can mean something else
tomorrow, pinning to `v1` today was never a pin.

To roll back, revert your pin. That is a one-line change in your own repository, and
the previous commit still exists because tags are immutable.

Full policy — what counts as a breaking change, the support window, the release
procedure — in [`docs/stability.md`](docs/stability.md).

> [!NOTE]
> The examples below use `@main` for readability. Real callers should pin. The
> inventory of who currently references what lives in [`docs/inventory.md`](docs/inventory.md).

## Caller trigger convention

Trigger CI-style workflows (`cgl.yml`, `cgl-test.yml`, `tests-php.yml`, `tests-typo3.yml`, `security.yml`) with:

```yaml
on:
  push:
    branches: [main, 'renovate/**']
  pull_request: ~
```

`renovate/**` is not decoration. Renovate automerges pin bumps by pushing a branch
and waiting for that branch to go green — no pull request involved. Without a `push`
trigger matching its branches, nothing runs there, the branch stays `pending`, and the
bump stalls for a day before falling back to a pull request. See
[Automerge](#automerge).

**Not** `push` with `branches: ['**']`. That pattern, seen across several consumers of this layer, runs the full matrix on every push to every branch, and then a *second* time when a pull request from that branch is opened or updated: the branch-push event and the pull request event both fire and both trigger the workflow. They don't run the literal same commit — `push` runs the commit as pushed, `pull_request` runs GitHub's synthetic merge of it into the target branch — but for a feature branch with no conflicting changes on the target, that difference rarely matters in practice, and the two runs are overlapping validation of the same branch update, paid for twice. For a workflow with an 18-job matrix, that is 18 duplicate jobs on every PR update.

`push: [main]` plus `pull_request` avoids the duplication: feature-branch work is validated once, by the pull request event; `main` itself is validated on every push to it (merges, direct commits). This is also why [OpenSSF Scorecard](#openssf-scorecard) needs its own, different trigger below — its guard exists specifically because `push: ['**']` would otherwise add a guaranteed-red check to every feature branch.

**Verified, not assumed:** none of this layer's 39 consumers has a branch protection rule or ruleset that depends on a check running on a direct push to a non-default branch. The one consumer with a `required_status_checks` rule (`move-elevator/typo3-login-warning`, gating `cgl / cgl`) requires it on the `pull_request` event, which this convention still provides — switching away from `push: ['**']` does not remove that check, only the redundant duplicate of it. Rulesets are unavailable on private repositories on the free plan, which by itself already rules out branch-scoped protection rules for four of the 39.

The concept behind this repository claimed the convention change "removes the need for a preparation workflow entirely". That does not hold up: the one real reference implementation of a `preparation` workflow found in a comparable third-party layer exists to gate execution on fork pull requests where secrets are unavailable, not to deduplicate push-vs-PR runs, and is unrelated to this convention. Independent of that, no workflow inside *this* repository could ever fix caller-side event duplication regardless of its design: GitHub evaluates a caller's own trigger conditions, and therefore whether a run happens at all, before any `uses:` reference in that caller is even resolved. The fix has to happen in the caller's `on:` block, which is exactly what this convention is.

## Automerge

Pin bumps of this layer **automerge on patch and minor**, via the shared
[`konradmichalik/renovate-config`](https://github.com/konradmichalik/renovate-config)
preset every consumer already extends. Major bumps never automerge.

That is defensible because a release here is signed off before it exists: the canary
exercises all ten workflows against `main`, and the release notes name every
consumer-visible change. It is not a blanket "trust the robot" — it is trust in a
specific, observed gate.

### How it merges, and what gates it

Renovate uses **branch** automerge: it pushes a branch, waits for that branch to go
green, then fast-forwards your default branch. **No pull request is created.**

The gate is therefore the checks that run on a push to that branch — which is exactly
why the [trigger convention](#caller-trigger-convention) above includes `renovate/**`.
Get that wrong and the failure is quiet rather than dangerous:

| Situation | What happens |
|---|---|
| Checks run and pass | Merged, no PR |
| Checks run and fail | No merge; Renovate opens a PR so you can see it |
| **No checks run at all** | GitHub reports the branch as `pending`, Renovate treats that as not-green and **refuses to merge**. After ~25 hours it gives up and opens a PR |

The third row is the one worth knowing: nothing unsafe happens, but the bump silently
does nothing for a day and then turns into manual work. Verified against GitHub's
combined-status API, which returns `{"state":"pending","total_count":0}` for a commit
with no checks.

> [!IMPORTANT]
> On that fallback pull request, GitHub's own auto-merge takes over
> (`platformAutomerge`). Renovate's documentation warns that if a repository has **no
> required status checks configured**, GitHub may merge such a pull request regardless
> of test results. At the time of writing exactly one consumer of this layer has
> required status checks. So the `renovate/**` trigger is not a nicety — for most
> repositories here it is the only thing standing between a bump and an unverified
> merge.

### Expected volume

One branch per consumer per release, not one per reference: the shared preset groups
them. A release of this layer therefore produces up to 41 branches, most of which
merge themselves without ever becoming a pull request.

## Concurrency

Most workflows cancel their own superseded runs, so you do not need a `concurrency`
block in the caller:

| Workflow | Handled by | Cancels superseded runs |
|---|---|---|
| `cgl.yml`, `cgl-test.yml` | the workflow | yes |
| `security.yml` | the workflow | yes |
| `scorecard.yml` | the workflow | no — a run publishes to the OpenSSF results API |
| `release.yml`, `release-typo3.yml` | the workflow | no — see below |
| `tests-php.yml`, `tests-typo3.yml`, `tests.yml` | **the caller** | up to you |

Releases are never cancelled mid-flight. `release-typo3.yml` spreads artefact build,
GitHub release and `tailor ter:publish` across three jobs, and a cancellation between
them leaves a version published to TER with no GitHub release, or the reverse.

The three **test workflows deliberately do not manage concurrency**, and this is the
one case where you should set it yourself:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

A reusable workflow cannot see its caller's matrix values, so if you ever call a test
workflow more than once from a single caller matrix, a group defined inside it would
be identical for every call — and they would cancel or queue each other. Only the
caller can build a group that includes the matrix key.

For the same reason, the groups the other workflows define include their **own** name,
not just caller context:

```yaml
group: ${{ github.workflow }}-cgl-${{ github.ref }}
```

Without that discriminator, a caller invoking `cgl.yml`, `cgl-test.yml` and
`security.yml` from one workflow file gives all three an identical group — because
`github.workflow` and `github.ref` are the caller's, and a reusable workflow has no
expression that identifies which callee it is. With `cancel-in-progress: true` they
then cancel each other. This is not hypothetical: it happened on the canary the first
time these blocks shipped.

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

Matrix testing workflow that runs tests across multiple PHP versions with both highest and lowest dependencies. Includes coverage reporting to Coveralls.

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
`coverage-dir`|input| false    |Directory your `test:coverage` script writes `clover.xml` to. Defaults to `.build/coverage`.
`coveralls`|input| false    |Upload coverage to Coveralls. Defaults to `true`.

## Tests TYPO3

Matrix testing workflow that runs tests across multiple PHP and TYPO3 versions with both highest and lowest dependencies. Includes coverage reporting to Coveralls.

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
`coverage-dir`|input| false    |Directory your `test:coverage` script writes `clover.xml` to. Defaults to `.Build/coverage`.
`coveralls`|input| false    |Upload coverage to Coveralls. Defaults to `true`.

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

### Testing TYPO3 12.4 requires an audit setting

If your matrix includes TYPO3 **12.4** — which the default `typo3-versions` does —
your repository needs this in its own `composer.json`:

```json
{
    "config": {
        "audit": {
            "block-insecure": false
        }
    }
}
```

Without it the job fails at dependency install, not at test time:

```
Root composer.json requires typo3/cms-core ^12.4, found typo3/cms-core[v12.4.0, ...,
v12.4.45] but these were not loaded, because they are affected by security advisories
```

Every currently published `12.4` release carries an open security advisory, and
Composer refuses to resolve a package in that state. Pinning the matrix to `^12.4`
leaves it nothing else to pick, so the lane cannot install at all.

> [!IMPORTANT]
> `--no-audit` does **not** help here, and this is the part that costs people an
> afternoon. It suppresses the separate `composer audit` *report*; the block above
> happens earlier, during dependency resolution, and is governed only by
> `config.audit.block-insecure`.

This is a deliberate choice not to set the flag inside the workflow. Doing so would
disable Composer's security-advisory filter for every consumer, including those who
never test 12.4 and have no reason to lower that guard. The `13.4` and `14.x` lines
are unaffected and need nothing.

Coverage goes to [Coveralls](https://coveralls.io) and nowhere else. The workflow
uploads the `clover.xml` that your own `test:coverage` composer script produces.

Your script decides where that file lands — usually via `phpunit.xml` — so tell the
workflow if it is not the default. The defaults differ per workflow and match each
one's existing convention: `.build/coverage` for `tests-php.yml`, `.Build/coverage`
for `tests-typo3.yml`. On Linux those are two different directories.

```yaml
with:
    coverage-dir: '.Build/coverage'
```

If the repository is not enabled on Coveralls, turn the upload off rather than
letting it fail:

```yaml
with:
    coveralls: false
```

The whole reporting job is skipped when it is off, and on pull requests from forks,
where the upload cannot succeed and a failure would mark an otherwise fine
contribution red.

> [!NOTE]
> CodeClimate reporting used to be listed here as an option enabled by a
> `CC_TEST_REPORTER_ID` secret. It never actually ran — the secret was never
> declared in the reusable workflows, so it never reached them — and it could not
> run today regardless: Code Climate's coverage API was shut down on 2025-07-18 and
> the product moved to Qlty. The step has been removed. If you set that secret on a
> repository, it is inert and can be deleted.

## Tests (deprecated)

> [!WARNING]
> `tests.yml` is **deprecated** and will be **removed in 0.3.0**. It is superseded by
> [Tests TYPO3](#tests-typo3). It is documented here only so its remaining callers can
> find the migration path — do not adopt it for anything new.

Migration is a one-line change in your caller:

```diff
 jobs:
     tests:
-        uses: konradmichalik/reusable-github-actions/.github/workflows/tests.yml@<ref>
+        uses: konradmichalik/reusable-github-actions/.github/workflows/tests-typo3.yml@<ref>
```

Nothing else changes. The two workflows take identical inputs, and their job names are
identical too, so composed check-run names stay the same and any branch protection rule
referencing them keeps matching.

Runs of `tests.yml` emit a warning annotation and a job-summary notice pointing here.

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

### Accepted tag format

Both release workflows validate the tag and refuse to release anything that does not
match exactly:

```
N.N.N       each part 1 to 3 digits
```

| Tag | | Why |
|---|---|---|
| `1.2.3` | accepted | |
| `0.0.1` | accepted | |
| `v1.2.3` | rejected | **no `v` prefix.** Deliberate: Composer and TER both take the bare version, so a `v` would have to be stripped somewhere, and "somewhere" is where mistakes live |
| `1.2` | rejected | all three parts are required |
| `1.2.3-rc1` | rejected | no pre-release suffixes; this layer has no pre-release process |
| `1.0.1000` | rejected | the 1-3 digit bound, which is a deliberate limit and not an oversight |

A tag that does not match fails the run with an annotation naming the tag, rather
than the bare `exit 1` it used to be.

The caller's own trigger is usually `tags: ['*']`, so this check is what stops a
stray tag from cutting a release. Both workflows validate identically, against
`github.ref_name`.

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

Input|Type| Required |Description
-|-|----------|-
`publish-results`|input| false    |Publish results to the public OpenSSF endpoint and badge. Defaults to `true`, and is ignored on private repositories.

Publishing is decided by repository visibility first: a **private** repository never
publishes, because doing so would push its supply-chain posture to a public endpoint
and the run fails outright when it tries. The scoring itself and the SARIF upload to
code scanning still happen, so a private repository gets the analysis without the
disclosure. Set `publish-results: false` to opt a *public* repository out of the
badge as well.

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

## Pages

Builds a [VitePress](https://vitepress.dev) docs site and deploys it to GitHub Pages.

```yaml
name: Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  pages:
    uses: konradmichalik/reusable-github-actions/.github/workflows/pages.yml@main
    permissions:
      contents: read
      pages: write
      id-token: write
```

Input|Type| Required |Description
-|-|----------|-
`node-version`|input| false    |Node.js version. Defaults to `22`.
`install-command`|input| false    |Command that installs npm dependencies. Defaults to `npm ci`.
`build-script`|input| false    |npm script that builds the site. Defaults to `docs:build`.
`output-dir`|input| false    |Directory holding the built site. Defaults to `docs/.vitepress/dist`.
`copy-paths`|input| false    |Newline-separated `source destination` pairs copied into the build output after the build. Each destination is relative to `output-dir`.

> [!IMPORTANT]
> The caller **must** grant all three permissions shown above. Omit one and the run
> does not fail inside a job — it is rejected at admission with `startup_failure` and
> **zero jobs listed**, which gives you nothing to read. Permissions only narrow down
> the call chain, so the reusable workflow cannot grant what the caller withheld.

`npm ci` needs a committed lockfile, same as it does anywhere else.

### Project sites need a base path

On a project site — `<user>.github.io/<repo>/` rather than a custom domain or a
user/org root site — the built assets live under a sub-path, and VitePress does not
detect that on its own. The workflow exposes it as `PAGES_BASE_PATH`; read it in
`docs/.vitepress/config.*`:

```js
const base = process.env.PAGES_BASE_PATH || '/'

export default {
  // configure-pages reports the path without a trailing slash
  // ("/my-repo"), while Vite expects base to end with one.
  base: base.endsWith('/') ? base : `${base}/`,
}
```

The normalisation is not cosmetic. Verified on a live deployment: the value arrives
as `/reusable-github-actions-canary`, no trailing slash. Passing it through unchanged
gives Vite a base it does not expect, and the breakage shows up as asset URLs that
are subtly wrong rather than as a build error.

Skip this only if your site is served from a domain root.

## ⭐ License

This project is licensed under [GNU General Public License 3.0 (or later)](LICENSE).
