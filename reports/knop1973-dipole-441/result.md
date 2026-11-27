# knop1973-dipole-441: reproduced (basis patched, build-only)

**Paper.** Knop (1973), CACM Algorithm 441, "Random deviates from the dipole distribution". The archive is netlib
TOMS 441.gz (sha256 bb261e7a11c7b173d6cc63e70961dff7611249b99bd1eee5bffa9ada77200fb0), a shell archive with
Fortran/Sp/Drivers (Makefile, driver.f, res) and Fortran/Sp/Src (src.f).

**Claim (registered by scout, not edited).** The sample mean of 1000 DIPOLE deviates for test 2 (A = B = 0.353553),
with seed 123456789 set in driver.f, is 0.110592 in the shipped `res` file. Tolerance 5e-5 absolute. The source is the
artifact's own reference output, not a paper table. Determinism: stochastic with a fixed seed.

**Our value.** `VALUE DIPOLE_MEAN_A0353553_N1000 0.110592`. The difference from the claim is 0.
The whole driver output is identical to the shipped `res` (`evidence/res-diff.txt` is empty), so the other two
tests match too.

**Verdict.** reproduced. **Basis:** patched, build-only.

- G1, original first: the Makefile in the shipped layout stops at once with
  `make: *** No rule to make target 'src.f', needed by 'src.o'.` The archive puts src.f in `Fortran/Sp/Src/`, while the
  Makefile expects it beside itself. Log: `evidence/original-attempt.log`.
- Build-only patch: nothing in the authors' source was changed. The Makefile's rules were run as separate commands from
  `Fortran/Sp/Drivers` with src.f taken from `../Src`. The pre, mid and post manifests are identical
  (`evidence/manifest.*`), so `verify_sources.py record` wrote `kind: build-only`.
- G2 is not needed for a build-only patch. The Makefile names no compiler flags; gfortran used its defaults.
- gfortran warns that the arithmetic IF in src.f is deleted in Fortran 2018. These are warnings, not errors.

**Environment pins.** gfortran 16.2.0 (conda-forge gcc 16.2.0-7, micromamba, `gfortran_linux-64`), installed in the
sandbox during the fetch step. Run through `tools/sandbox.sh` (read-only root, no network after fetch, 3G memory, 3600 s wall).

**Replay (G5).** Not yet. The first clean replay is due on the scheduled duty.

**Command.** `reports/knop1973-dipole-441/recipe.sh` rebuilds and reruns everything from a clean scratch directory.

**Not part of the claim.** The other two tests in the driver (A = 1, B = 0 and A = B = 0) are identical to the shipped
`res` as well, but only test 2 is registered.
