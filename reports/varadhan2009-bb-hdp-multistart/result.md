# varadhan2009-bb-hdp-multistart: reproduced at the edge of tolerance (basis: original)

**Claim** (scout, `queue/varadhan2009-bb-hdp-multistart.json`): JSS 2009, Varadhan & Gilbert, "BB", section "Finding multiple roots ... multiStart" (p. 10–11): `sum(ans$conv)` prints `[1] 284` for 300 random starts of the Kearfott system `hdp`, seed 1234. Tolerance (fixed before any run): integer count within 281–287.

**Paper value**: 284.
**Rerun value**: **287** (`sum(ans$conv)` and `sum(ans$converged)` both 287, two driver runs).
**Verdict**: reproduced, inside the registered tolerance, but at its upper edge (|287 − 284| = 3 = tol_abs). The verdict is what the registered rule gives. The tolerance was not changed.
**Basis**: `original`. The authors' BB 2009.9-1 package was built with `R CMD INSTALL` in the sandbox (R 4.5.3, from conda-forge, installed in the `--fetch` step). No edits to the package.

## Gap filled, and where it came from

The installed package does not export `hdp`. The first attempt failed with `object 'hdp' not found` (log kept: `evidence/attempt1-hdp-not-in-package.log`). The fix does not write any code: the recipe takes the authors' own `hdp` definition from their JSS vignette source (`BB/inst/doc/BBvignetteJSS.Stex`, the same listing as the paper) and sources it. The driver's listing matches the paper's: `setRNG(list(kind="Mersenne-Twister", normal.kind="Inversion", seed=1234))`, `p0 <- matrix(runif(900), 300, 3)`, `multiStart(par = p0, fn = hdp, action = "solve")`. The `hdp` the paper prints is the same function as the archived `tests/multiStartHDP.R`, which uses 200 starts and is a different check.

## Cross-check disagrees (recorded, not hidden)

The earlier `reimplemented` basis (a Python port, `impl/bb_port.py`, `recipe-reimplemented.sh`) gave 284, the paper's value. The authors' code gives 287 under the same seed and listing. The port does not reproduce the authors' count; its agreement with 284 was a coincidence of its own RNG path, or the port diverges from BBsolve in a detail. This is not resolved here. The authors' code is the verdict basis, so the port is not evidence for the claim.

Likely cause, not checked: R 4.5.3 with the current `setRNG` and `numDeriv` (conda-forge) differs from the 2009 R environment, so iteration paths differ (the paper itself warns about this on p. 9). The cause is not diagnosed; a second environment would be needed to settle it (not run).

## Exact command

    reports/varadhan2009-bb-hdp-multistart/recipe.sh

It fetches the pinned tarball (sha256 `e6b145bd…`), installs R and the dependencies in the sandbox, builds BB with `R CMD INSTALL`, extracts `hdp` from the vignette, and runs the driver twice (G3 replay).

## Environment pins

- BB 2009.9-1, `BB_2009.9-1.tar.gz`, sha256 `e6b145bda50727838623442e1dc7985b1e9806c68371bf542c600209394ac88e` (matches queue).
- R 4.5.3 (conda-forge `r-base`), `r-numderiv` and `r-setrng` from conda-forge (current versions), gcc/gfortran 16.2.0.
- Not the 2009 R (R 2.9.1). The paper's count is for that environment.

## Evidence

- `evidence/original-attempt.log`: the successful original run (exit 0), two driver runs, both 287.
- `evidence/attempt1-hdp-not-in-package.log`: the first run, failed on `hdp` not found, kept as the failed attempt.
- `impl/ml_original.R`: the driver. `impl/bb_port.py`, `impl/check_roots.py`: the reimplementation (cross-check only).

## Limits

- 287 is inside tolerance only at the edge. A different R environment could move it to either side of the tolerance, and the verdict would change. Nothing was run to test that.
- Only `multiStart(action = "solve")` is run. `BBoptim` is not.
- The seed-sensitivity spread recorded for the port (282–286) is for the port, not the authors' code, and is not reused as evidence here.
