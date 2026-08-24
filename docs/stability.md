# Stability policy

This is the contract between this repository and everything that consumes it. It exists because, until it did, every commit reached every consumer instantly with no review gate, no rollback and no way to test a change before it went live. See `docs/canary.md` for the pre-release testing side of that problem and `docs/actions.md` for why a workflow here cannot test itself against a caller.

## Versioning

Semantic versioning, `MAJOR.MINOR.PATCH`, applied to the reusable workflows and actions this repository provides, not to this repository's own tooling (`ci.yml`, `scripts/`, the canary).

A change is **breaking** (major bump) if it does any of the following to a workflow or action a consumer already calls:

- Removes an input, a secret, or the workflow/action itself
- Changes an input's default value
- Makes a previously optional secret required, or adds a newly required input
- Renames a job. A job's name is part of a check-run name (`<workflow> / <job>`), and a branch protection rule or ruleset referencing that name by string stops matching silently, not loudly, when it changes. Confirmed relevant: at least one real consumer (`move-elevator/typo3-login-warning`) has a required-check rule keyed on a job name today
- Changes behaviour a consumer could reasonably have depended on: what previously succeeded now fails, or vice versa, for the same input

A change is **not breaking** on its own: adding a new optional input, adding a new workflow or action, fixing a bug whose old behaviour was never the documented contract, or tightening validation to reject something that was never supposed to be accepted (though this still needs a heads-up, see "What a breaking change looks like" below).

## Pinning contract

Consumers pin every `uses:` reference to a full commit SHA with a trailing version comment:

```yaml
uses: konradmichalik/reusable-github-actions/.github/workflows/cgl-test.yml@<sha> # 0.1.0
```

Not a tag, not a floating major (`@v1`, `@main`). Renovate bumps the SHA and keeps the comment in sync; see `scripts/pin-references.sh` for the tool that performs the initial pin and re-pins on each release. The auto-merge strategy for those Renovate PRs is decided separately in #42, since it changes the maintenance-cost trade-off pinning creates and deserves its own decision rather than being assumed here.

## Immutable tags

A released tag is never moved, ever, including to fix a mistake in that release. A broken release is fixed forward with a new patch tag.

This is also why there is no floating major tag (`v1`, `v0`) on offer, unlike some comparable projects. With SHA pins plus Renovate, a floating major buys nothing a consumer doesn't already get from the automated bump, and a tag that can move defeats the audit trail SHA pinning exists to provide in the first place: if `v1` can point at a different commit tomorrow, pinning to `v1` today was never actually a pin.

## Rollback

A consumer rolls back by reverting their own pin, a one-line change in their own repository (the previous SHA, restored). Nothing to request or coordinate here: the previous release's commit still exists, untouched, because tags are immutable.

## Support window

One maintained line: the latest minor release. No parallel major-version support, no backport branches. This matches the project's own stated scope (personal-use layer, not a general-purpose product) rather than promising a support model nobody, including the maintainer, would sustain. A security-relevant fix lands in a new patch release of the current minor; there is no older line it also needs to land in.

## Release procedure

The standing procedure for any release that contains a breaking change, not only this milestone's first one. Written once here so it does not need re-deciding under time pressure next time.

1. **Freeze.** Tag the current `main` as a marker release with **no functional change** — a pure freeze point, not a real release
2. **Pin.** Every known consumer gets pinned to the freeze tag (`scripts/find-consumers.sh` produces the list, `scripts/pin-references.sh` performs the pin). From this point, nothing that happens on `main` reaches anyone
3. **Change.** The breaking work happens and merges to `main`, behind the freeze, with nobody watching it happen because nobody is exposed to it
4. **Release.** Tag the real release. The release notes name every consumer-visible behaviour change explicitly — not "see changelog", an actual list, because that list is the thing a consumer bumping their pin needs to decide whether now is a good time
5. **Bump, deliberately.** Consumers are bumped from the freeze tag to the real release one at a time, starting with whatever this repository's own canary is at the time (`docs/canary.md`), not all at once and not automatically. Automated bumps (Renovate) take over only after this first deliberate bump confirms the release is sound

Steps 1 and 2 cost one extra tag and one extra pin sweep over doing this in a single pass. That is the price of never letting a consumer see an in-progress breaking change; see the milestone that first used this procedure for the reasoning in full.

## What a breaking change looks like, from a consumer's side

Before: `uses: .../cgl-test.yml@<old-sha> # 0.1.0`. A Renovate PR (or a manual bump, if auto-merge is off for this workflow, see #42) opens proposing `@<new-sha> # 0.2.0`. The PR description names the breaking change from the release notes. The consumer merges it when ready, and not before; nothing forces the bump.
