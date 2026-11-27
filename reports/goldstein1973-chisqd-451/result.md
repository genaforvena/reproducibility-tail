# goldstein1973-chisqd-451: reproduced (basis: patched)

**Paper.** R. B. Goldstein, "Algorithm 451: Chi-square quantiles", Communications of the ACM 16(8), 483-485 (1973), collected as ACM TOMS Algorithm 451. The ACM article was not read; the authors' Fortran from the netlib archive was run.

**Claim (registered, not edited).** `CHISQD(0.5, 10) = 9.341794` (writeup column), absolute tolerance 1e-5. The shipped reference `Fortran/Sp/Drivers/res` (computed column, N = 10) gives 9.341793.

**Our value.** 9.341793 in both passes. Difference from the claim: 1e-6, inside the tolerance.

**Verdict.** reproduced. **Basis.** patched: the authors' Makefile is not usable as shipped (it calls `f77`, which is not in the sandbox). The compiler name was substituted with gfortran. No source file was changed.

## What was run

- Source: netlib TOMS 451.gz, sha256 `5bb6f1b1...` checked. Unpacked with `extract-tree.awk` (this directory). The archive is a shell archive; it was not executed. The delimiter is quoted as `"SHAR_EOF"`, which the stock awk in `reports/bai1997-srrit-776/` does not match, so this directory has its own copy.
- Compiler: GNU Fortran 16.2.0 (conda-forge gcc 16.2.0-7), installed in the sandbox with micromamba.
- Build: `gfortran -O2` on `Fortran/Sp/Src/src.f` and `Fortran/Sp/Drivers/driver.f`, linked to `driver`. The build-only check (`verify_sources record`) reports kind `build-only`: no source was modified before the build, so the paper check of G2 is not needed.
- Runs: two passes, each in a fresh run directory with the same binary, `timeout 120`.
- Exact command: `reports/goldstein1973-chisqd-451/recipe.sh`.

## Original attempt (G1)

The authors' `Drivers/Makefile`, as shipped with no variables, fails: `make: f77: No such file or directory`, exit 2 (`evidence/original-attempt-make.log`). The retry with the same Makefile and `F77=gfortran` builds and runs (`evidence/retry-make-f77-gfortran.log`, make exit 0). Because the substitution is a compiler name, the basis stays `patched`.

## Evidence

- `evidence/archive-sha256-check.txt`: the archive hash check.
- `evidence/gfortran-version.txt`, `evidence/unpack-listing.txt`.
- `evidence/shipped-res.txt`: the shipped reference output (hashed in `result.json`).
- `evidence/manifests/`: manifest pre, mid and post for the build.
- `evidence/build.log`, `evidence/run-pass1.txt`, `evidence/run-pass2.txt`: both passes print `10 ... 9.341793` in the computed row.
- `evidence/recipe-run.log`: the full recipe output.

## Open

- G5 replay is not run. It is due only under the replay-due duty.
- The writeup column of the driver's table (9.341794) is a hard-coded table. The claim compares against it, and our value comes from the code. Only the N = 10, P = 0.5 cell is claimed; other cells differ between the computed and writeup columns by up to about 1e-2 and are not claimed.
