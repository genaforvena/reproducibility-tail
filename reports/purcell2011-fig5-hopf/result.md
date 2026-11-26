# purcell2011-fig5-hopf: result

**Verdict: blocked** (claim mis-specified for the artifact; no run; no value produced).

## Claim (pre-registered in queue/purcell2011-fig5-hopf.json, not edited)

- Paper: Purcell, di Bernardo, Grierson & Savery 2011, PLOS ONE 6(2): e16140.
- Metric: input concentration I (nM) at which the Hopf bifurcation occurs, target about 7 nM, tolerance 0.5 nM (6.5 to 7.5 nM).
- Code: baioc/re-multif (ReScience C 8.1 replication), commit 3ab84df2d34f67dd66929848fc154fef2185d10a. The SHA matches the scout's `git ls-remote` HEAD.

## Why it is blocked

The artifact does not compute a Hopf bifurcation value. `recipe.sh` checks this at the pinned SHA:

- No "hopf" in `src/` or `experiments.py`. The only mention is prose in `doc/content.tex` ("Self-induced Oscillator"): the replication measures output period against input concentration between the saddle-node and Hopf points. It reports no Hopf input value.
- `src/run_experiment.m` runs time simulations only. It contains no continuation or stability analysis.
- The replication's Figure 5 is a time series at I = 5 nM (Experiment 2). The registered location (the 2011 paper's Figure 5 caption) does not match it.

Getting the registered number would need a new bifurcation calculation for the 2011 model, not a run of this artifact. The scout must decide how to re-specify the claim (see note-to-scout.md). I have not chosen a friendlier claim.

## Environment checks done (no code run)

- Host: Ubuntu 24.04. `octave` is not installed. apt offers 8.4.0, but the README requires 5.2 or 6.2 with `signal` 1.4.1 and `control` 3.2.0. Those would need network installs. I did not start that, because the claim does not match the code.
- Replication repo cloned into scratch with `git clone` (not run) and checked out at the pinned SHA.

## Exact commands

    reports/purcell2011-fig5-hopf/recipe.sh [scratch-dir]

Evidence: `recipe.sh` output (above); clone in `/mnt/mishe-scratch/reproducibility-tail/purcell2011-fig5-hopf/` (kept for the scout's reply; not deleted). `article.txt` is the pdftotext of the replication article.

## Next step

Wait for the scout to re-specify or drop the claim (note-to-scout.md). No sandboxed run is planned until a re-registered claim exists.
