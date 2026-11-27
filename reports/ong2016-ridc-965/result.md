# ong2016-ridc-965: reproduced (basis original)

**Paper.** Ong, Haynes, Ladd (2016), "RIDC Methods: A Family of Parallel Time Integrators", ACM TOMS 43(1), Article 8
(CALGO Algorithm 965). The archive is netlib TOMS 965.zip (sha256 a05c08deacd16436d180e8fe7e29557732b852a089785692eac07594158560c5).

**Claim (registered by scout, not edited).** The first component `sol[0]` printed by `./explicit 4 10` (RIDC forward Euler,
order 4, nt = 10 on u_i' = -(i+1) t u_i over [0,1], u_i(0) = 1) is 0.606521722539, the first line of the shipped
`examples/explicit/ref/n1.ref`. Tolerance 1e-11 absolute. The reference is the artifact's own output, not a paper table.

**Our value.** `VALUE SOL0_RIDC4_NT10 0.606521722539`. Difference 0.

**Verdict.** reproduced. **Basis:** original. The archive's own build and tests ran as documented, with no edits.

- G1, original first: `./configure`, `make` and `make check` ran in a copy (`evidence/original-attempt.log`). `make check`
  passed both examples. `examples/explicit/run.sh` diffed n1 to n5 against `ref/n*.ref` with no differences
  (diff.log empty, `:test-result: PASS`).
- The n1 run (`evidence/run.log`) prints `0.606521722539` and `0.367864508325`, identical to `ref/n1.ref` (`cmp` silent).
- The exact value does not need a fresh compile or a patch. No source file was changed.

**Environment pins.** g++ 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1), GNU Make 4.3, OpenMP via `-fopenmp` from configure.
Run through `tools/sandbox.sh`: read-only root, no network after fetch, memory 3G, wall 3600 s.
The build emits `--pedantic -Wall` warnings from the authors' code; these are not errors.

**Replays.** The recipe ran twice from a clean scratch directory (`evidence/recipe-run.log`, `evidence/recipe-run-2.log`); both
give `0.606521722539`. The G5 independent replay (`tools/replay.py`) is not yet run: the `replay-due` duty will schedule it.

**Command.** `reports/ong2016-ridc-965/recipe.sh` rebuilds and reruns everything.

**Not checked.** The paper article's own printed values were not checked (scout could not verify the DOI). The claim is
only the archive's n1 case. The other cases (n2 to n5), and the implicit solver, are not part of this claim.
