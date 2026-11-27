# bai1997-srrit-776: blocked (the registered claim does not match its value)

Paper: Bai and Stewart, Algorithm 776, SRRIT, ACM TOMS 23(4), 1997 (netlib TOMS 776.gz).

## Claim (as registered, not edited)

- Value: WR = -1235.506919564, tol_abs 1e-6 (queue commit fcdf386).
- Registered location: the RWK block of a 496 by 496 matrix in the shipped reference output.

## What the artifact shows

- The shipped `Drivers/Dp/DRES` prints `WR = -1.235506919564D+03` in the **BWM** block (test matrix size 200), not the RWK block (size 496). Its first converged RWK WR is `1.0`.
- Our run of the authors' double-precision driver, built with gfortran 16 -O2 and no source edit, prints the same BWM value to all twelve printed digits, and RWK first WR `1.0`.

## Verdict

`blocked`. The number is reproduced by the authors' code, but the claim names the wrong problem, so it is not compared as written. The claim and tolerance are not edited here. The mis-specification goes to the scout (`note-to-scout.md`).

## Basis and original attempt

- Original (G1): the documented `make double` (epcf90) fails, epcf90 is not installed (`evidence/original-attempt-make.log`).
- Patched (build-only): gfortran substituted for epcf90, authors' sources unchanged (manifests pre and mid identical). Build log `evidence/build.log`.

## Exact command and pins

- `bash reports/bai1997-srrit-776/recipe.sh`. The fetch checks `776.gz` against sha256 `11341f82...6e2c1d34`. The archive is unpacked into its directory tree with `extract-tree.awk` (no shell archive is executed).
- gfortran: `evidence/gfortran-version.txt` (GNU Fortran conda-forge gcc 16.2.0-7).
- Run: `timeout 300`, the input is `Drivers/Dp/data`, and the driver writes `doutput` (`evidence/run-doutput.txt`).

## Evidence

- `evidence/unpack-listing.txt`, `evidence/original-attempt-make.log`, `evidence/build.log`, `evidence/run-doutput.txt`, `evidence/run.log`, `evidence/recipe-run.log`.

## Replay and recurrence

Not replayed yet. No clean replay exists because the verdict is blocked.
