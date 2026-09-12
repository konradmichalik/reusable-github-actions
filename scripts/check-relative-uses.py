#!/usr/bin/env python3
"""Fails if a step-level `uses:` in this repository is a relative reference.

A relative `uses:` resolves differently depending on where it sits:

  jobs.<id>.uses: ./...             resolves at THIS commit. Documented, safe,
                                    and what self-release.yml relies on.
  ...steps[*].uses: ./...           resolves against the CALLER's checkout. If the
                                    caller happens to have a file at that path, it
                                    silently runs the caller's version instead.

The second case was verified empirically in #37; see docs/actions.md. This guard
turns it into a review-time failure instead of a future consumer's silent one.

Written in Python rather than grep on purpose. Two tools in this repository have
already shipped an unanchored `uses:` match and ended up matching their own
documentation (#70, #75). The distinction here is structural, not textual, so it
is parsed structurally.
"""
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("::error::PyYAML is required for this check", file=sys.stderr)
    sys.exit(2)


def step_uses(doc):
    """Yield (path, value) for every step-level `uses:` in a workflow or action."""
    if not isinstance(doc, dict):
        return
    for job_id, job in (doc.get("jobs") or {}).items():
        if not isinstance(job, dict):
            continue
        for i, step in enumerate(job.get("steps") or []):
            if isinstance(step, dict) and "uses" in step:
                yield f"jobs.{job_id}.steps[{i}]", step["uses"]
    runs = doc.get("runs")
    if isinstance(runs, dict):
        for i, step in enumerate(runs.get("steps") or []):
            if isinstance(step, dict) and "uses" in step:
                yield f"runs.steps[{i}]", step["uses"]


def main():
    targets = sorted(Path(".github/workflows").glob("*.yml"))
    targets += sorted(Path(".github/actions").glob("*/action.yml"))
    targets += sorted(Path(".github/actions").glob("*/action.yaml"))

    status = 0
    for path in targets:
        try:
            doc = yaml.safe_load(path.read_text())
        except yaml.YAMLError as exc:
            print(f"::error file={path}::could not parse: {exc}")
            status = 1
            continue
        for where, ref in step_uses(doc):
            if isinstance(ref, str) and ref.startswith("./"):
                print(
                    f"::error file={path}::{where} uses a relative reference "
                    f"({ref}). A step-level relative `uses:` resolves against the "
                    f"caller's checkout, not this repository. Use the fully "
                    f"qualified form: konradmichalik/reusable-github-actions/"
                    f"<path>@<sha>. See docs/actions.md."
                )
                status = 1
    return status


if __name__ == "__main__":
    sys.exit(main())
