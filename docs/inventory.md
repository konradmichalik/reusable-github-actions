# Consumer inventory

Generated. Do not edit by hand: re-run

```sh
scripts/find-consumers.sh | scripts/render-inventory.sh > docs/inventory.md
```

and commit the result. `find-consumers.sh` exits non-zero and names every
repository it could not inspect, so a run that exits 0 is the only one whose
output is complete enough to drive a pin rollout.

Authoritative as of 2026-09-12, produced by walking `.github/workflows/*.yml`
of every non-archived repository under each owner directly via the GitHub contents
API. GitHub's code search index was checked first and found to be non-exhaustive
(known consumers were absent from its results), so this list does not rely on it.

## Summary

- **40** consumer repositories, **135** `uses:` references
- **135** of those references are still on `@main`
- Owners: konradmichalik, move-elevator, xima-media
- **4** private: konradmichalik/tally, konradmichalik/typo3-bot-inspect, konradmichalik/typo3-translation-validator, move-elevator/typo3-pulse

## References by workflow

| Workflow | References |
|---|---|
| `cgl-test.yml` | 23 |
| `release-typo3.yml` | 20 |
| `security.yml` | 18 |
| `scorecard.yml` | 18 |
| `tests-typo3.yml` | 16 |
| `release.yml` | 15 |
| `cgl.yml` | 13 |
| `tests.yml` | 6 |
| `tests-php.yml` | 6 |

## Legacy `jackd248/reusable-github-actions` references

`jackd248` is this project's own former GitHub username before a rename to
`konradmichalik`, not a third-party fork. The reference still resolves today via
GitHub's username-rename redirect, which is not something to rely on: if someone
else ever registers that username, these references break silently.
4 reference(s) need rewriting to `konradmichalik/reusable-github-actions`.

| Consumer | Caller file | Referenced workflow |
|---|---|---|
| konradmichalik/composer-dependency-age | `.github/workflows/cgl.yml` | `cgl.yml` |
| konradmichalik/console-style-kit | `.github/workflows/cgl.yml` | `cgl.yml` |
| move-elevator/composer-translation-deepl | `.github/workflows/cgl.yml` | `cgl.yml` |
| move-elevator/composer-translation-deepl | `.github/workflows/release.yml` | `release.yml` |

## Deprecated `tests.yml` callers

See #39. `tests.yml` is superseded by `tests-typo3.yml` and scheduled for removal
in `0.3.0`. Migration is a one-line change of the `uses:` path.

- `konradmichalik/typo3-letter-avatar`
- `konradmichalik/typo3-mcp-server-content-planner`
- `xima-media/xima-typo3-content-planner`
- `xima-media/xima-typo3-frontend-edit`
- `xima-media/xima-typo3-internal-news`
- `xima-media/xima-typo3-recent-updates`

## Full detail

| Consumer | Visibility | Caller file | Referenced workflow | Ref |
|---|---|---|---|---|
| konradmichalik/annotaitr | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/composer-dependency-age | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main (legacy owner)` |
| konradmichalik/console-style-kit | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main (legacy owner)` |
| konradmichalik/db-sync-tool | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/php-color | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| konradmichalik/php-color | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/php-color | public | `.github/workflows/tests.yml` | `tests-php.yml` | `main` |
| konradmichalik/php-cs-fixer-preset | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| konradmichalik/php-cs-fixer-preset | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/php-cs-fixer-preset | public | `.github/workflows/tests.yml` | `tests-php.yml` | `main` |
| konradmichalik/php-doc-block-header-fixer | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| konradmichalik/php-doc-block-header-fixer | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/php-doc-block-header-fixer | public | `.github/workflows/tests.yml` | `tests-php.yml` | `main` |
| konradmichalik/php-ico-file-loader | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| konradmichalik/php-ico-file-loader | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/php-ico-file-loader | public | `.github/workflows/tests.yml` | `tests-php.yml` | `main` |
| konradmichalik/php-sync-tool | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| konradmichalik/phpstan-typo3-preset | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/revkit | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/tally | private | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| konradmichalik/tally | private | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/tally | private | `.github/workflows/tests.yml` | `tests-php.yml` | `main` |
| konradmichalik/ttt | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| konradmichalik/ttt | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| konradmichalik/ttt | public | `.github/workflows/tests.yml` | `tests-php.yml` | `main` |
| konradmichalik/typo3-ai-mate | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-ai-mate | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-ai-mate | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-ai-mate | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-ai-mate | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-backend-themes | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-backend-themes | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-backend-themes | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-bot-inspect | private | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-bot-inspect | private | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-bot-inspect | private | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-bot-inspect | private | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-bot-inspect | private | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-dump-server | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-dump-server | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-dump-server | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-dump-server | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-dump-server | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-environment-indicator | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-environment-indicator | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-environment-indicator | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-environment-indicator | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-environment-indicator | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-file-sync | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-file-sync | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-file-sync | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-file-sync | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-file-sync | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-letter-avatar | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-letter-avatar | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-letter-avatar | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-letter-avatar | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-letter-avatar | public | `.github/workflows/tests.yml` | `tests.yml` | `main` |
| konradmichalik/typo3-mcp-server-content-planner | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-mcp-server-content-planner | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-mcp-server-content-planner | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-mcp-server-content-planner | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-mcp-server-content-planner | public | `.github/workflows/tests.yml` | `tests.yml` | `main` |
| konradmichalik/typo3-pagetree-facets | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-pagetree-facets | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-pagetree-facets | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-pagetree-facets | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-pagetree-facets | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-request-profiler | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-request-profiler | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-request-profiler | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-request-profiler | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-request-profiler | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-routing | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-routing | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-routing | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-routing | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-routing | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-routing-mcp | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-routing-mcp | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-routing-mcp | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-routing-mcp | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-routing-mcp | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-solr-dashboard-widgets | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-solr-dashboard-widgets | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-solr-dashboard-widgets | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| konradmichalik/typo3-solr-dashboard-widgets | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| konradmichalik/typo3-solr-dashboard-widgets | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| konradmichalik/typo3-translation-validator | private | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| konradmichalik/typo3-translation-validator | private | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| konradmichalik/typo3-translation-validator | private | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| move-elevator/composer-translation-deepl | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main (legacy owner)` |
| move-elevator/composer-translation-deepl | public | `.github/workflows/release.yml` | `release.yml` | `main (legacy owner)` |
| move-elevator/composer-translation-validator | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| move-elevator/composer-translation-validator | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| move-elevator/deployer-tools | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| move-elevator/deployer-tools | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| move-elevator/typo3-image-compression | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| move-elevator/typo3-image-compression | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| move-elevator/typo3-image-compression | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| move-elevator/typo3-image-compression | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| move-elevator/typo3-image-compression | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| move-elevator/typo3-login-warning | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| move-elevator/typo3-login-warning | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| move-elevator/typo3-login-warning | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| move-elevator/typo3-login-warning | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| move-elevator/typo3-login-warning | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| move-elevator/typo3-pulse | private | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| move-elevator/typo3-pulse | private | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| move-elevator/typo3-pulse | private | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| move-elevator/typo3-pulse | private | `.github/workflows/security.yml` | `security.yml` | `main` |
| move-elevator/typo3-pulse | private | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| move-elevator/typo3-repeatable-form-elements | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| move-elevator/typo3-repeatable-form-elements | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| move-elevator/typo3-repeatable-form-elements | public | `.github/workflows/tests.yml` | `tests-typo3.yml` | `main` |
| move-elevator/typo3-styleguide | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| move-elevator/typo3-styleguide | public | `.github/workflows/release.yml` | `release.yml` | `main` |
| move-elevator/typo3-styleguide | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| move-elevator/typo3-styleguide | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| move-elevator/typo3-toolbox | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| xima-media/xima-typo3-content-planner | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| xima-media/xima-typo3-content-planner | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| xima-media/xima-typo3-content-planner | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| xima-media/xima-typo3-content-planner | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| xima-media/xima-typo3-content-planner | public | `.github/workflows/tests.yml` | `tests.yml` | `main` |
| xima-media/xima-typo3-frontend-edit | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| xima-media/xima-typo3-frontend-edit | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| xima-media/xima-typo3-frontend-edit | public | `.github/workflows/scorecard.yml` | `scorecard.yml` | `main` |
| xima-media/xima-typo3-frontend-edit | public | `.github/workflows/security.yml` | `security.yml` | `main` |
| xima-media/xima-typo3-frontend-edit | public | `.github/workflows/tests.yml` | `tests.yml` | `main` |
| xima-media/xima-typo3-internal-news | public | `.github/workflows/cgl.yml` | `cgl-test.yml` | `main` |
| xima-media/xima-typo3-internal-news | public | `.github/workflows/release.yml` | `release-typo3.yml` | `main` |
| xima-media/xima-typo3-internal-news | public | `.github/workflows/tests.yml` | `tests.yml` | `main` |
| xima-media/xima-typo3-recent-updates | public | `.github/workflows/cgl.yml` | `cgl.yml` | `main` |
| xima-media/xima-typo3-recent-updates | public | `.github/workflows/tests.yml` | `tests.yml` | `main` |
