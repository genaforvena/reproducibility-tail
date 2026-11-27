# caliari2008-padua2d-886: result

**Paper:** Caliari, De Marchi, Vianello (2008). Algorithm 886: Padua2D, Lagrange interpolation at Padua points on
bivariate domains. ACM TOMS 35(3), art. 21. Stack: Fortran 77. Field: numerics (polynomial interpolation).

**Claim (paper-text, registered 2026-11-27T03:28Z):** normalized true error of the Padua interpolant at degree 60 for
the Franke function F1 on the unit square, Table I: 2E-11. Absolute tolerance 5e-12 (the printed value stands for
[1.5E-11, 2.5E-11]). Read from the pre-publication draft; the published TOMS table may differ.

## Verdict

- **Verdict:** reproduced
- **Basis:** original (documented compile line from Doc/README, no source edit)
- **Our value:** 2.468e-11 (driver output `Actual error: 0.2468E-10`), identical in both passes.
- **Margin:** 0.468e-11 of 5e-12 tolerance, 94%. Inside tolerance, but close to the edge; the ledger flags it.

## Original attempt (G1)

The archive ships no Makefile. Following Doc/README, drvrec is built with gfortran -O2 from the authors' sources,
with the documented `blas/*.f` alternative in place of `-lblas`. The build exits 0 and drvrec runs to completion.
Logs: `evidence/pass1-build.log`, `evidence/pass1-run.log`.

## Runs (G3)

Two passes: a clean rebuild in its own directory, then a run in its own working directory. Both print
`Actual error: 0.2468E-10`. Logs: `evidence/pass1-run.log`, `evidence/pass2.log`.

## Notes

- The driver's source contains a constant `Expected error 0.2468D-10`. It is not the oracle. The registered claim is
  the paper's Table I value, and the shipped Results/ files are not used (their coordinates do not match the target grid).
- The registered tolerance was fixed before the run and not changed.
- Replay (G5) has not run yet; the recipe prints the `VALUE` line for it.
- Toolchain: gfortran 16.2.0 (conda-forge) in the sandbox scratch. The sandbox fetch step verified the archive sha256.

## Recipe

`recipe.sh` rebuilds and reruns both passes through `tools/sandbox.sh`.
