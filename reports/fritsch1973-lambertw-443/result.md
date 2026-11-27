# fritsch1973-lambertw-443: reproduced (basis patched, build-only)

**Paper.** Fritsch, Shafer, Crowley (1973), CACM Algorithm 443, "Solution of the Transcendental Equation w e^w = x".
The archive is netlib TOMS/CACM 443.gz (sha256 bf664e74f2700a5c8a2f6c27b4cbc9e1d7b37c19a792764fd73c6941f642026f).

**Claim (registered by scout, not edited).** TEST01 of the shipped driver, the Computed value of WEW_A at x = 1.0,
is 0.56714326 in the shipped `res` file. Tolerance 1e-7 absolute. The source is the artifact's own reference output,
not a paper table.

**Our value.** `VALUE W_WEW_A_AT_1 0.56714326`. The difference from the claim is 0.

**Verdict.** reproduced. **Basis:** patched, build-only.

- G1, original first: the authors' Makefile in the shipped layout fails at once with
  `make: *** No rule to make target 'src.f', needed by 'src.o'.` The archive puts src.f in `Fortran/Sp/Src/`, while the
  Makefile expects it beside itself. The log is kept in `evidence/original-attempt.log`.
- Build-only patch: nothing in the authors' source changed. The Makefile's own rules run from `Fortran/Sp/Drivers`
  with `src.f` taken from `../Src`. The manifests of the authors' source files (`evidence/manifest.pre`, `.mid`, `.post`)
  are identical, so `tools/verify_sources.py record` writes `kind: build-only`.
- The full TEST01 and TEST02 output (`evidence/Res`) is identical to the shipped `res` (`evidence/res-diff.txt` is empty).
- G2 is not needed for a build-only patch. The authors' Makefile names no compiler flags, so F77OPTS is empty and gfortran
  uses its defaults.

**Environment pins.** gfortran 16.2.0 (conda-forge gcc 16.2.0-7, micromamba, `gfortran_linux-64`), installed in the sandbox.
Run through `tools/sandbox.sh`: read-only root, no network after fetch, memory 3G, wall 3600 s.
The build emits "Fortran 2018 deleted feature: Arithmetic IF" warnings. These are warnings, not errors.

**Replays.** The recipe was run once from a clean scratch directory (`evidence/recipe-run.log`). A scheduled G5 replay
with `tools/replay.py` then agreed with the record (`evidence/replay-2026-11-27T142334Z.log`).

**Command.** `reports/fritsch1973-lambertw-443/recipe.sh` rebuilds and reruns everything.

**Not checked.** The second test (TEST02, WEW_B) prints values that differ from WEW_A in the last digit at some x. That is
not part of the claim and is not analysed here. The claim is only TEST01 at x = 1.0.
