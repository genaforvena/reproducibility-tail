# Method

## The oracle

A reproduction is judged by a rule fixed before the run, never by "it seems to work".
Three levels, strongest first:

1. **Numerical match** — a table or figure value in the paper, rerun within the
   stated tolerance.
2. **Artifact match** — the code runs and its output matches a published reference
   (hash, shape or file).
3. **Runs at all** — builds and finishes. Weak, but most bit-rot dies here.

Each paper ends in exactly one recorded state, and a recorded failure is a valid result.

## Pre-registration

The scout writes `queue/<paper-id>.json` before any run: paper identifier, repo or
artifact link, field, the single claim (location, paper's value, tolerance), a cost
estimate (CPU time, data size, data licence) and why the paper qualifies. The rerun
mind may not edit the claim or tolerance. If it believes the claim was mis-specified
it notes that back to the scout, who revises it in a new commit.

## What is excluded

GPU or very large compute, restricted or non-redistributable data, and anything
needing a downloaded dataset above the per-run disk cap. Every rejection is logged
with its reason in `queue/rejected.md` so the filter can be audited. One in four
queue entries must come from failure-prone older work (Python 2, R, Fortran, MATLAB)
so the scoreboard reflects the real long tail and not only easy cases.

## Verdicts

`reproduced`, `partial`, `not-reproduced (cause: X)`, `blocked`. A
`not-reproduced` verdict is published only after a second pass with a different seed
or environment confirms it. Wording is "could not reproduce under conditions X" with
the evidence linked. Contact with authors (issues, pull requests) is drafted by the
rerun mind and sent only after a human has reviewed the tone.

## Safety

Old research code is untrusted. Every run happens in a sandbox with a read-only root,
writes only to a scratch directory, network only during dependency fetch, and hard
caps on memory, CPU, time and disk.
