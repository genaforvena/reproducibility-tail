# snyder1993-fresnel-723: reproduced (basis: patched)

**Paper.** W. V. Snyder, "Algorithm 723: Fresnel integrals", ACM TOMS 19(4), 452-456 (1993); revised TOMS 22(4), 498-500 (1996). The ACM article was not read; the authors' Fortran (netlib TOMS 723.gz, sha256 checked) was run.

**Claim (registered, not edited).** C(1.0) = 0.7798934 (shipped `Drivers/Dp/RES`, printed as 7.7989340E-01), absolute tolerance 1e-6.

**Our value.** 7.7989340E-01 (0.7798934) in both passes. Difference from the claim: 0 at printed precision, inside the tolerance.

**Verdict.** reproduced. **Basis.** patched: the authors' `Doc/makefile` calls `f77` (absent) and names `drdfrenl.f`, which the archive does not ship (the driver is `Drivers/Dp/driver.f`). The build uses gfortran and names the driver object `drdfrenl.o`. No source file was changed; the build is build-only by the record (`verify_sources record`: kind build-only, 23 files compared, 0 modified).

## What was run

- Source: netlib TOMS 723.gz, sha256 `335fe1d3...566b13` checked. Unpacked with `extract-tree.awk` (this directory; the awk is a copy of goldstein's). The archive is a shell archive and was not executed.
- Compiler: GNU Fortran 16.2.0 (conda-forge gcc 16.2.0-7) installed in the sandbox with micromamba.
- Build (13 commands, see `recipe.sh`): gfortran -O2 on the double-precision driver and routines in `Src/Dp`, linked to `drdfrenl`.
- Runs: two passes, each in a fresh run directory with the same binary, `timeout 120`, exit 0.
- Exact command: `reports/snyder1993-fresnel-723/recipe.sh`.

## Original attempt (G1)

The authors' `Doc/makefile`, as shipped, fails with `make: No rule to make target 'drdfrenl.o', needed by 'drdfrenl'` (exit 2): the archive ships `driver.f` under `Drivers/Dp`, not `drdfrenl.f`. The retry with `F77=gfortran` fails the same way (exit 2). The log is kept (`evidence/original-attempt-make.log`, `evidence/retry-make-f77-gfortran.log`). Because the build is patched, the verdict's basis is `patched`.

## Evidence

- `evidence/archive-sha256-check.txt`, `evidence/gfortran-version.txt`, `evidence/unpack-listing.txt`.
- `evidence/shipped-res-dp.txt`: the shipped double-precision reference table.
- `evidence/run-pass1.txt`, `evidence/run-pass2.txt`: both passes print `-1.0 ... 7.7989340E-01` and `1.0 ... 7.7989340E-01`, and the two passes agree row for row.
- The 25-row table of pass 1 matches the shipped table except one unit in the 7th digit in two entries (C at X=-4, S at X=-5) and the zero-row formatting.
- `evidence/manifests/`, `evidence/build.log`, `evidence/recipe-run.log`.
