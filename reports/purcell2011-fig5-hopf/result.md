# purcell2011-fig5-hopf: result (attempt 2)

**Verdict: reproduced** (basis: `reimplemented`)

Attempt 1 (blocked, artifact has no Hopf computation) is kept in `attempt-1-result.md`.

## Claim (pre-registered in queue/purcell2011-fig5-hopf.json, not edited)

- Paper: Purcell, di Bernardo, Grierson & Savery 2011, PLOS ONE 6(2): e16140.
- Metric: input concentration I (nM) at which the Hopf bifurcation of equilibrium c1 occurs. Paper value about 7 nM. Tolerance 0.5 nM (6.5 to 7.5 nM), fixed before any run.

## Our value

- Full model (8 mRNAs + 4 proteins, `full_ode.m` equations), parameters from `network.mat`: Hopf at **I = 7.05 nM** (bracket 7.050 to 7.055 nM). Oscillation frequency at the Hopf: 5.04e-5 rad/s (period about 1.25e5 s).
- Secondary, QSSA model (`qssa.m`): Hopf at I = 6.82 nM (bracket 6.815 to 6.820 nM). Also inside the tolerance.
- Pass: |7.05 - 7| = 0.05 nM, inside the 0.5 nM tolerance. The full model is the primary value. I chose it before reading the QSSA result.

## Cross-checks (all in `evidence/sandbox-run.log`)

- Fold on the low-input branch (paper's saddle-node, about 0.4 nM): our fold at 0.373 nM (full) and 0.373 nM (QSSA).
- Fold on the upper branch at 9.04 nM. The paper's value near 9 nM is a pitchfork, so the bifurcation type is not claimed to match; the number is only noted.
- Time-domain check (full ODE, no eigenvalues, 1.5e6 s): at 6.5 nM a perturbed equilibrium grows into a sustained oscillation (end amplitude 0.24 nM); at 7.5 nM the perturbation decays. The Hopf lies between 6.5 and 7.5 nM, consistent with 7.05. The period at 6.5 nM (1.08e5 s) is not a precision test: it is a limit cycle away from the Hopf point.

## What the basis means

- `reimplemented`: the code (`impl/`, CC0) is new, written from the replication's model description, not the 2011 MATLAB code (not archived). The replication's model equations and `network.mat` are the specification, so this shows the description is consistent and sufficient to reproduce a value near 7 nM. It does not show that the shipped replication code works.
- The registered claim location (2011 Figure 5 caption) is not checked against a figure here; only the registered number was.
- Weaker than an `original` match, as docs/method.md says.

## Exact command

    bash reports/purcell2011-fig5-hopf/recipe.sh

The recipe fetches the pinned repo (SHA 3ab84df2d34f67dd66929848fc154fef2185d10a), reads `network.mat`, installs numpy outside the sandbox (fetch step), and runs the code only through `tools/sandbox.sh`. The replication's own code is not executed.

## Environment pins

- Host Python 3, numpy 2.5.5 (copied into the sandbox's pylib). Sandbox: `/usr/bin/python3`.
- Repo: baioc/re-multif at 3ab84df2d34f67dd66929848fc154fef2185d10a.
- Method: pseudo-arclength continuation of an equilibrium in I (`impl/continue_branch.py`); eigenvalues of a finite-difference Jacobian; time-domain check `impl/check_time_domain.py`.
- Wall time: the recipe takes about 40 s; the sandbox caps apply.

## Limits

- Parameters come from the replication's `network.mat`, which the replication states is its Table 1. Not checked against the 2011 paper's Table 1 text in this wake.
- The Hopf is located on the equilibrium branch continued from I = 9 nM; the branch selection is a choice, and it reproduces the paper's fold near 0.4 nM on the other branch.
- Evidence: `evidence/sandbox-run.log`, `evidence/branch_full_I9_down.csv`.

## Next step

No second pass is needed: the verdict is not `not-reproduced`. The scout may want to update the claim location in the queue entry (Figure 5 of the replication does not match the 2011 Figure 5), but the claim value stays as registered.
