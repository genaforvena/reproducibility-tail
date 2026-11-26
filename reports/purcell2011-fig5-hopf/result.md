# purcell2011-fig5-hopf: reproduced (basis: reimplemented)

Attempt 1 (blocked: the replication artifact has no Hopf computation) is kept in `attempt-1-result.md`. Attempt 2 is the new calculation below.

## Claim (pre-registered in `queue/purcell2011-fig5-hopf.json`, not edited)

- Paper: Purcell, di Bernardo, Grierson & Savery 2011, PLOS ONE 6(2): e16140.
- Metric: input concentration I (nM) at which the Hopf bifurcation of equilibrium c1 occurs. Paper value about 7 nM. Tolerance 0.5 nM (6.5 to 7.5 nM), fixed before any run.

## Our value

- **Primary (paper Table 1, exact constants):** Hopf at **I = 7.1875 nM** (bracket 7.18502 to 7.19002 nM). |7.1875 − 7| = 0.19 nM, inside the tolerance.
- Table 1's footnote gives the activator and repressor constants as exact values, (1E-10)^(1/1.3) and (1E-12)^(1/1.3) M, and the replication's `network.mat` stores them rounded (2e-8 and 6e-10). The registered spec is the paper's Table 1, so the exact values are the primary run.
- **Sensitivity (rounded `network.mat`):** Hopf at I = 7.0525 nM (bracket 7.05003 to 7.05503). Also inside the tolerance. The 0.14 nM shift between the two runs comes only from rounding k_A and k_R, so the value is sensitive to that rounding.
- Secondary, QSSA model (`qssa.m`, rounded network.mat): Hopf at 6.8175 nM (bracket 6.81502 to 6.82002). Also inside the tolerance.

## Parameter fidelity check (G2, against the paper's Table 1)

Table 1 was read from the PLOS image (`t001`, fetched in this wake):

| Parameter | Table 1 | network.mat |
|---|---|---|
| k_tl | 6E-4 s⁻¹ | 6e-4 |
| δ_m | 2.5E-3 s⁻¹ | 2.5e-3 |
| δ_X | 4E-4 s⁻¹ | 4e-4 |
| N | 1.3 | 1.3 |
| k_A (activator) | ~2E-8 M (exact (1E-10)^(1/1.3) = 2.0309e-8) | 2e-8 (rounded) |
| k_A (repressor) | ~6E-10 M (exact (1E-12)^(1/1.3) = 5.8780e-10) | 6e-10 (rounded) |
| β | 4E-10 M·s⁻¹ | 4e-10 |
| P_tc | 4E-10 M·s⁻¹ | 4e-10 |

All values agree to the table's precision. The two rounded constants differ from their exact footnote values by about 2% and 2%, and that is the only difference, which is why the exact run is primary.

## Cross-checks

- Time-domain check (full ODE, no eigenvalues, 1.5e6 s, independent of the continuation): at 6.5 nM a perturbed equilibrium grows into a sustained oscillation (end deviation 0.24 nM); at 7.5 nM the perturbation decays (6.8e-4 nM). The Hopf lies between 6.5 and 7.5 nM, which the continuation result agrees with. This was run with the rounded network.mat values, not the exact ones. The bracket is well inside 6.5–7.5 nM either way.
- Fold on the low-input branch: 0.373 nM (paper: about 0.4 nM).
- Fold on the upper branch at 9.04 nM. The paper's value near 9 nM is a pitchfork, so the bifurcation type is not claimed to match.

## Basis

- `reimplemented`. The replication's code (`baioc/re-multif`, pinned SHA 3ab84df) has no Hopf computation (attempt 1). The authors' own artifact was tried first and cannot produce the claimed quantity, so the Hopf value is a new calculation in `impl/`, written from the model equations and parameters. It shows that the model description and the parameters are sufficient to reproduce a value near 7 nM. It does not show that the replication's shipped code works.
- The original attempt is recorded as `not-possible` (missing code, not a toolchain failure), with no toolchain install needed.

## Exact command

    reports/purcell2011-fig5-hopf/recipe.sh

The recipe fetches the pinned repo (SHA 3ab84df2d34f67dd66929848fc154fef2185d10a), reads `network.mat`, installs numpy outside the sandbox (fetch step), writes the exact-constants parameter file, and runs the reimplementation only through `tools/sandbox.sh`. The replication's own code is not executed.

## Environment pins

- Host Python 3, numpy 2.5.5 (copied into the sandbox's pylib). Sandbox: `/usr/bin/python3`.
- Repo: baioc/re-multif at 3ab84df2d34f67dd66929848fc154fef2185d10a.
- Method: pseudo-arclength continuation of an equilibrium in I (`impl/continue_branch.py`); eigenvalues of a finite-difference Jacobian; time-domain check `impl/check_time_domain.py`.

## Evidence

- `evidence/sandbox-run.log`: the full run of the recipe (primary, sensitivity, QSSA, fold and time-domain checks), replay pass.
- `evidence/recipe-run-1.out`, `evidence/recipe-run-2.out`: console output from the two runs (G3 replay: both give the primary bracket 7.18502–7.19002).
- `evidence/branch_full_I9_down.csv`: the continuation branch.

## Limits

- The Hopf point is located on the equilibrium branch continued from I = 9 nM. The branch selection is a choice, and it reproduces the paper's fold near 0.4 nM on the other branch.
- The claim location is the 2011 paper's Figure 5 caption. The replication's Figure 5 is a time series at I = 5 nM and does not match it. The number was checked, not the figure (see `note-to-scout.md`).
- Table 1 was read from the image, not an electronic table.
