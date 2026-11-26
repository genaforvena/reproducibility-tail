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
with its reason in the funnel (next section) so the filter can be audited.

## Sampling frames and the funnel

A scoreboard built from whatever the scout found tractable measures the reachable tail,
the most reproducible corner of it, not the tail. A quota of "older work" only asks the
scout to try harder inside a pool it picked. The remedy is to take the choice away:

1. **Frame.** The scout names a sampling frame and lists every item in it in
   `queue/frames/NAME.json` (a library index such as the Computer Physics Communications
   program library, a Netlib or TOMS index, one journal's volumes, a full arXiv listing for a
   category and years). The frame, with its description and source, is the denominator.
2. **Draw.** `tools/frame_sample.py` draws a seeded random order of N items. A frame is
   drawn once and never redrawn to taste. When the draw is used up, `--extend K` appends K more
   items (seeded from what is left; the earlier order never changes), so the count can grow
   but the choice never passes to the scout.
3. **Account.** Candidates are considered in that order, none skipped, and each is one line
   of `queue/funnel.jsonl`: `registered` (becomes a queue entry), `rejected` with a reason
   from a fixed list, or `unreachable`. `checks/funnel.py` fails on a skipped or repeated
   item, a reason outside the list or a missing detail.
4. **Report.** The ledger leads with the funnel: candidates considered per frame, attempted,
   unreachable, rejected by reason, and each stack's share among those considered against
   those attempted, so the survivorship is visible, not assumed away.

`unreachable` is a recorded outcome, not a filter event. It means the code or data is gone
(`unreachable-code`, `unreachable-data`) and the paper does not describe the method well enough
to rebuild it. It must cite at least two fallbacks actually tried (Software Heritage, the
Wayback Machine, Zenodo, an author page, the publisher's supplement, contact with an
author) and the evidence. A paper whose code is gone but whose method is described is not
unreachable: it is attempted as `reimplemented`, with the lost original recorded as
`original_attempt` `not-possible`, and counted as such in the ledger.

Reasons for `rejected`: `paywalled`, `figure-only`, `no-numeric-claim`, `claim-not-located`,
`no-method-description`, `stochastic-no-seed` (results depend on randomness and neither seed nor
code is available), `no-code`, `runtime` (over the cost cap), `machine-dependent`,
`restricted-data`, `gpu`, `other` (needs a `detail`; the ledger flags it when it passes 15%).
Every line also records the paper's `stack`: `Fortran`, `C/C++`, `R`, `Python`, `MATLAB/Octave`,
`Julia`, `Java`, `other`, or `not-stated` when the paper names no language, so the survivorship
table by stack means something. A withdrawn claim moves to `queue/withdrawn/`, never deleted. Frames should cover the older and stranger stacks deliberately (Fortran
or C numerical libraries, Python 2, MATLAB) next to the easy ones; the funnel then shows how
reachable each is, which is itself a finding.

## Verdicts

`reproduced`, `partial`, `not-reproduced (cause: X)`, `blocked`. A
`not-reproduced` verdict is published only after a second pass with a different seed
or environment confirms it. Wording is "could not reproduce under conditions X" with
the evidence linked. Contact with authors (issues, pull requests) is drafted by the
rerun mind and sent only after a human has reviewed the tone.

## Filling gaps in the artifact

Old artifacts are often incomplete: the command, seed or analysis behind a claim is
missing, a plotting library is gone, or the code simulates but never computes the
reported quantity. The rerun mind fills such gaps itself, and labels what it did:

- Every verdict carries a **basis**: `original` (the authors' code produced the value),
  `patched` (the authors' code plus build or dependency fixes, such as a stub for a
  removed plotting library), or `reimplemented` (new code written by the rerun mind from
  the paper's own description of the method). The ledger shows the basis.
- New code lives under `reports/<paper-id>/impl/`, is CC0, and is kept apart from
  the authors' files so the two stay distinguishable. It is written from the paper's
  text and the authors' code as a specification, and the registered claim and tolerance
  stay untouched.
- A `reimplemented` match is weaker evidence than an `original` one: it shows the
  paper's description is sufficient and consistent, not that the shipped code works. A
  `reimplemented` mismatch is never published as "not reproduced" by itself, because
  the fault may be the new code. It needs a second, independent reimplementation or a
  documented cross-check (for example an analytic limit) before it counts.
- If the paper's description is too ambiguous to implement, or a needed value (a seed,
  a parameter) is genuinely unstated, the verdict is `blocked` and names the exact
  missing specification. Guessing the missing value until the number matches is
  forbidden. An unstated seed is a finding, not a licence to search seeds.
- Effort stays bounded by the scout's cost estimate plus a fixed implementation
  allowance of one wake's worth of work; beyond that the verdict is `blocked` with
  the partial implementation preserved.

## Gates

A result counts only when it passes these gates. Most are checked by a script
(`checks/gates.py`), so a mind's opinion is never the evidence.

| gate | condition | decided by |
|---|---|---|
| G0 admission | the value is located in readable text, the tolerance and its reason are fixed, the claim cannot be met without running the method, and it is labelled deterministic or stochastic with a seed. The queue entry is not edited after a run. | scout; script checks the entry is unchanged since the run |
| G1 original first | the authors' own artifact was tried in the sandbox before anything was patched or rewritten. A failed attempt has a log; "not possible" (no code exists) has a reason. | script |
| G2 fidelity | for `patched` or `reimplemented`: each new piece cites the paper's section or equation, and parameters were checked against the paper itself, not only against a replication | rerun, recorded in the report |
| G3 replay | `recipe.sh` from a clean directory gives the same value twice, or within a stated Monte Carlo error | script |
| G4 verdict | the verdict is computed from the recorded values and the registered tolerance | script (`tools/build_ledger.py`) |
| G5 independence | a fresh replay confirms it; a `reimplemented` mismatch also needs a second route (analytic limit or second implementation) | scheduled replay, or a fresh rerun wake |
| G6 publication | `not-reproduced` is double-confirmed with a cause named; wording is "could not reproduce under these conditions"; contact with authors waits for a person | script plus a person |

G5 is a scheduled duty, not a promise. `tools/replay.py --id ID` wipes the paper's scratch
directory, runs `recipe.sh` from nothing, reads the `VALUE <name> <number>` lines the recipe
prints (one per claimed value) and compares them with the record: the replay agrees only
if the registered tolerance still holds and the number equals the recorded one (exact to 1e-6
relative unless the value carries `replay_abs`). It appends a `kind: clean` entry to
`replayed` and sets `gates.G5`. The `replay-due` duty is RED for any reproduced result with
no clean replay in the last 7 days, and for one whose newest clean replay changed; the
ledger's "last replay" column shows only clean replays.

G1 makes `reimplemented` an exception: the authors' code comes first. When a toolchain is
missing (R, Fortran, Octave), install it inside the sandbox during the fetch step (for
example micromamba) and try again before concluding the original cannot run.

## Result record and grades

Each report ends with `reports/<id>/result.json`, written by `rerun`:

- `paper` (`short`, `title`, `year`, `doi`), `field` and `stack` (free text, for the report), and `field_class`
  (`biology`, `epidemiology`, `ecology`, `physics`, `astronomy`, `chemistry`, `statistics`, `numerics`,
  `other`) and `stack_class` (`Fortran`, `C/C++`, `R`, `Python`, `MATLAB/Octave`, `Julia`, `Java`, `other`,
  `not-stated`; the language of the paper's own code, not of the rerun) that the ledger counts by
- `claim`: `text` and `values`, a list of `{name, paper, tol_abs, ours}`; `ours` is null when blocked
- `basis` (`original`, `patched`, `reimplemented`), `verdict`, `cause` (see below), `attempt`
- `queue_commit`: the commit of `queue/<id>.json` the run was made against
- `original_attempt`: `{tried, outcome, reason, log}`. `outcome` is how the authors' artifact behaved when run
  as documented: `succeeded` (it ran), `partial` (it ran only through a workaround, or for part of the claim),
  `failed` (it did not run) or `not-possible` (no code exists). The basis must fit it: `original` needs
  `succeeded`; `patched` needs `partial` or `failed`; `reimplemented` needs `failed` or `not-possible`. So a
  per-fit driver around a call that halts is `patched`, never `original`
- `gates`: `G1`, `G2`, `G3`, `G5`, `G6` each `pass`, `fail` or `na`, and `cross_check`
- `recipe` and `evidence` (paths), `replayed`: a list of `{utc, value, ok}`

Grades are computed, not chosen. A: the authors' code, run clean. B: the authors' code with
build fixes. C: reimplemented with an independent cross-check. D: reimplemented only.
X: not reproduced, with a diagnosed cause. "-": blocked or not yet run.

`cause` for anything not reproduced: `dependency-rot`, `missing-code`, `missing-data`,
`unstated-parameter`, `numerical-discrepancy`, `nondeterminism`, `platform`, `other`.

## Presentation

`ledger.md` is generated by `tools/build_ledger.py` from the result records and is never
edited by hand; a duty fails when it differs from the generated text. It holds a scoreboard
(papers by grade, field, stack and decade), one table row per claimed value (paper, field,
year, stack, claim, paper value with tolerance, our value, difference, margin, basis,
gates, grade, verdict, last replay). Margin is the difference as a share of the
tolerance fixed before the run; 80% or more is flagged ⚠, because a different
environment could flip such a result and a table of why papers stopped reproducing.

## Safety

Old research code is untrusted. Every run happens in a sandbox with a read-only root,
writes only to a scratch directory, network only during dependency fetch, and hard
caps on memory, CPU, time and disk.
