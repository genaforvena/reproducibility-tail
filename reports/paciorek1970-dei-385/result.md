# paciorek1970-dei-385: reproduced (basis patched, build-only)

**Paper.** Paciorek (1970), CACM Algorithm 385, exponential integral Ei(x) (function DEI). The archive is netlib TOMS
385.gz (sha256 f76ca4d6610c227c020e9d7901518089ba680d596ed8888615f38b26b4b5ddb7), a shell archive with
Fortran/Dp/Drivers (Makefile, driver.f, res) and Fortran/Dp/Src (src.f).

**Claim (registered by scout, not edited).** DEI(2.0) = 4.9542344, the Computed column of TEST01 at X = 2.0000 in the
shipped `res` file. Tolerance 2e-7 absolute.

**Our value.** `VALUE DEI_TEST01_X2 4.9542344`. The difference from the claim is 0. The driver's whole output is
identical to the shipped `res` (`evidence/res-diff.txt` is empty, diff exit 0).

**Verdict.** reproduced. **Basis:** patched, build-only.

- G1, original first: the Makefile in the shipped layout stops at once with
  `make: *** No rule to make target 'src.f', needed by 'src.o'.` (`src.o: src.f` in the Makefile, while the archive
  puts src.f in `Fortran/Dp/Src/`). Log: `evidence/original-attempt.log`.
- Build-only patch: no source file was changed. The Makefile's rules were run as separate commands from
  `Fortran/Dp/Drivers`, with src.f taken from `../Src`. The pre, mid and post manifests are identical, so
  `verify_sources.py record` wrote `kind: build-only` (exit 0).
- gfortran warnings only; no flags were added beyond the Makefile's empty F77OPTS.

**Environment pins.** gfortran 16.2.0 (conda-forge gcc 16.2.0-7, micromamba, `gfortran_linux-64`), installed in the
sandbox during the fetch step. Everything ran through `tools/sandbox.sh`.

**Replay (G5).** Not yet run; the result is new.

**Command.** `reports/paciorek1970-dei-385/recipe.sh` rebuilds and reruns everything from a clean scratch directory.
