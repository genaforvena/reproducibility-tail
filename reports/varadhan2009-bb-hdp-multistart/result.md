# varadhan2009-bb-hdp-multistart: reproduced (basis: reimplemented)

**Claim** (scout, `queue/varadhan2009-bb-hdp-multistart.json`): JSS 2009, Varadhan & Gilbert,
"BB: An R Package for Solving a Large System of Nonlinear Equations and for Optimizing a
High-Dimensional Nonlinear Objective Function", section "Finding multiple roots ... multiStart"
(p. 10–11): `sum(ans$conv)` prints `[1] 284` for 300 random starts of the Kearfott polynomial
system `hdp`, seed 1234. Tolerance (fixed before any run): integer count within 281–287.

**Paper value**: 284.
**Rerun value**: 284 (`sum(ans$converged)`, the registered seed 1234).
**Verdict**: reproduced, inside the registered tolerance.
**Basis**: `reimplemented`. R is not installed on this host, and the BB code was not run. The
port (`impl/bb_port.py`, CC0) was written from the BB 2009.9-1 R sources and R 4.6.2's
`src/main/RNG.c` and `src/appl/optim.c`. This is weaker than `original`.

## Exact command

    reports/varadhan2009-bb-hdp-multistart/recipe.sh

It verifies the sha256 of the pinned archive and runs `bb_port.py --self-test` and the registered
run through `tools/sandbox.sh` (read-only root, no network, memory/CPU/time caps).

## Environment pins

- Source read: CRAN archive `BB_2009.9-1.tar.gz`, sha256
  `e6b145bda50727838623442e1dc7985b1e9806c68371bf542c600209394ac88e` (matches the scout's pin).
- Nelder–Mead and RNG reference: R 4.6.2 `src/appl/optim.c` (`nmmin`) and `src/main/RNG.c`,
  from `R-4.6.2.tar.gz`, sha256 `c297040f6392b1dac6e5c0eb398422cfdaedf540ae2205edb9ad0d10cb10ee00`.
  The 2009 R release may differ; `nmmin` and the MT code have been stable for many years, but
  this is an assumption, not a checked fact.
- Interpreter: Python 3 from the sandbox's `/usr` (`python3 -I`). No R, no numpy.

## Evidence

- Self-test (sandbox): standard MT19937 `init_genrand(5489)` first output `3499211612`, which
  matches the reference. R's seeding (`set.seed(1234)` scrambling, mti = 624) gives
  `runif(3) = 0.1137034 0.6222994 0.6092747`, which matches R's published output for this seed
  (from memory, not re-checked against an R binary).
- Registered run (sandbox, under 1 s): `sum(ans$conv) = 284`, inside 281–287.
- Diagnostic (`impl/check_roots.py`): the 284 converged starts give **12 unique roots** (4 dp), the
  paper's "12 real roots". Max |hdp| at the rounded roots is about 5e-5, consistent with rounding to 4 dp.
- Seed sensitivity, informational only (same port, same 300 starts): seeds 1234→284, 1235→284,
  1236→282, 1237→284, 2024→286. All lie within 281–287 except 2024, which is above 287.
  The verdict uses only the registered seed 1234.

## Limits of this verdict (what it does not show)

- It is not a run of the BB package. The code is a port, and it has not been compared with R output
  beyond the RNG check above. R's `sum()` uses long double and this port uses double, so a
  near-tie comparison can differ. R's `^` may also differ by a few ulps from C `pow`.
- Only `multiStart(action = "solve")` is ported. `BBoptim` is not.
- The count is a statistic over 300 starts, so a port that is exact in every step would still
  need the same tie-breaks to match the paper's 284 exactly. The tolerance (±3) allows for that.
- A `not-reproduced` verdict would need a second pass with another seed or environment. This is
  `reproduced`, so no second pass is required by the method, but the seed-sensitivity spread
  (282–286) is recorded above.

## Failed attempts

None recorded for this entry before this wake.
