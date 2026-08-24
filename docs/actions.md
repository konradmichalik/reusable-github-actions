# Relative `uses:` resolution inside a called reusable workflow

Resolved by [issue #37](https://github.com/konradmichalik/reusable-github-actions/issues/37) on 2026-08-24, via a real spike, not by reasoning about GitHub's documentation.

## Question

Inside a workflow invoked via `workflow_call` from another repository, does a step written as `uses: ./.github/actions/foo` resolve against **(a)** this repository (the one that defines the reusable workflow), or **(b)** the caller's repository?

## Method

Two throwaway repositories, both since removed from active use (the definer-side fixtures were deleted after the spike; the scratch consumer repository was archived rather than deleted, so the run links below stay live as evidence):

- This repository, on branch `spike/37-relative-uses-resolution`: a composite action `spike-echo` that prints a marker, a composite action `spike-wrapper` that calls `spike-echo` via `uses: ./.github/actions/spike-echo` (to test action-to-action nesting), and a workflow `spike.yml` with `on: workflow_call` and two jobs — one calling `spike-echo` directly from a step, one calling `spike-wrapper`.
- [`konradmichalik/spike-uses-resolution`](https://github.com/konradmichalik/spike-uses-resolution) (archived): a scratch consumer calling `spike.yml@spike/37-relative-uses-resolution` via `workflow_dispatch`.

Two runs:

1. **No conflict.** Scratch repo has no `.github/actions/spike-echo` or `spike-wrapper` of its own. [Run](https://github.com/konradmichalik/spike-uses-resolution/actions/runs/32714669323) — both jobs **failed**:
   ```
   ##[error]Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under
   '/home/runner/work/spike-uses-resolution/spike-uses-resolution/.github/actions/spike-echo'.
   Did you forget to run actions/checkout before running your local action?
   ```
2. **Conflict.** Scratch repo adds its own `.github/actions/spike-echo` and `spike-wrapper` at the identical relative paths, each printing a different marker. [Run](https://github.com/konradmichalik/spike-uses-resolution/actions/runs/32714826235) — both jobs **succeeded**, printing the scratch repo's marker, not this repository's.

## Answer

**(b), unambiguously, for both direct step references and action-to-action nesting.**

The mechanism: `actions/checkout` with no `repository:` input checks out `${{ github.repository }}`, which inside a called reusable workflow resolves to the **caller's** repository. `uses: ./path` then resolves purely against whatever is on disk in the job's workspace, which is that checkout. There is no special-casing for the fact that the workflow file itself lives elsewhere, and no special-casing for a composite action's own relative references resolving against where *it* was loaded from rather than the job workspace root.

## Consequences, decided

1. **Confirmed as a real, load-bearing constraint, not an assumption:** every action-to-action or workflow-to-action reference inside this repository's own workflows and composite actions must be fully qualified — `konradmichalik/reusable-github-actions/.github/actions/x@<version>` — never relative. Version-bump automation (issue #11a) is therefore a genuine prerequisite of the 0.2.0 action layer, not a precaution against a hypothetical.
2. **Confirmed as a real constraint:** a workflow here cannot exercise its own working-tree changes by calling itself relatively. Only this repository's own CI (`ci.yml`, `self-test.yml` once it exists) can test the branch pre-release, by virtue of running *in* this repository rather than being called *from* elsewhere.
3. **New risk, not anticipated by the original concept, found by testing the dangerous case explicitly rather than stopping at "does it work":** if a self-reference is ever accidentally left relative in a future action or workflow here (a review miss, not a hypothetical — nothing currently guards against it), the failure mode is not an error. It is **silent execution of whatever the calling consumer happens to have at that same path**, chosen non-deterministically by which consumer happens to call it and what they happen to keep at that path. This is worse than "broken": it is an unreviewed, consumer-controlled code-execution surface inside a workflow this project defines. Concretely: if this repository ever ships a composite action at `.github/actions/setup-php/` and a future PR introduces a step with the un-qualified `uses: ./.github/actions/setup-php` by mistake, any consumer who happens to also keep a directory at that exact path gets to decide what runs there instead, with zero warning to either party.

## Follow-up

A guard against consequence 3 is worth adding once the action layer exists in 0.2.0: a lint step (in `ci.yml`, alongside `actionlint`/`zizmor`) that fails if any `uses:` value under `.github/workflows/` or `.github/actions/` in this repository starts with `./`. Cheap, mechanical, and turns the dangerous silent case into the loud failing case at review time instead of at some future consumer's run time.
