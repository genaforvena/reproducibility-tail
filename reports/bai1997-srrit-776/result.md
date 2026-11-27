# bai1997-srrit-776: reproduced (basis: patched, build-only)

Paper: Bai and Stewart, Algorithm 776, SRRIT, ACM TOMS 23(4), 1997 (netlib TOMS 776.gz).

## Claim (as registered, revised by scout)

- Value: WR = -1235.506919564, tol_abs 1e-6, in the BWM problem (test matrix size 200, after 2000 SRRIT iterations) of the shipped double-precision reference output.
- Queue commit 9e8879b. The scout revised the claim from the earlier RWK 496 location, which prints WR 1.0 first, to the BWM block, where the value is printed. The number, tolerance and claim text are not edited here.
- History: the first verdict (blocked, 5cd2b23) was against fcdf386, the RWK version. Note to scout: `note-to-scout.md`.

## Result

- The authors' double-precision driver, built unmodified with gfortran 16 -O2, prints `WR = -1.235506919564D+03` as the first converged eigenvalue of the BWM block (test matrix size 200). That is -1235.506919564 at every printed digit, so |ours - paper| is below 1e-12 against tol_abs 1e-6.
- The RWK block (test matrix size 496) prints `WR = 1.000000000000D+00` first, as the earlier note said.
- Two passes gave the same BWM value: the 08:40Z wake (5cd2b23) and this wake (08:47Z).

## Basis and original attempt

- Original attempt (G1, failed): the authors' documented `make double` (Doc/Makefile, epcf90) stops because epcf90 is not installed (`make: epcf90: No such file or directory`, exit 2). Log: `evidence/original-attempt-make.log`.
- Build-only patch: gfortran is the compiler; the authors' sources are not edited. `tools/verify_sources.py record` compared 9 files, none modified, none added. Build log: `evidence/build.log`. Because the patch is build-only, the paper check of G2 is not needed (`na`).

## Exact command and pins

- `bash reports/bai1997-srrit-776/recipe.sh`. The fetch checks `776.gz` against sha256 `11341f825b8c12bb7f51bf58affe513255d14206fa8147310284249c2e6d1d34`. The archive is unpacked with `extract-tree.awk`; no shell archive is executed.
- gfortran: GNU Fortran (conda-forge gcc 16.2.0-7), `evidence/gfortran-version.txt`.
- Run: `timeout 300`, input `Drivers/Dp/data`, output in `doutput` (`evidence/run-doutput.txt`).

## Evidence

- `evidence/original-attempt-make.log`, `evidence/unpack-listing.txt`, `evidence/build.log`, `evidence/run-doutput.txt`, `evidence/run.log`, `evidence/recipe-run.log`, `evidence/gfortran-version.txt`, `evidence/manifest.{pre,mid,post}`, `evidence/shipped-DRES-double.txt`.

## Replay and recurrence

Replay 1 (2026-11-27 09:08Z, `evidence/replay-2026-11-27T090823Z.log`): DIFFERS, G5 fail. Cause: the recipe printed the
BWM value only as an `OBSERVED` line, with no `VALUE <name> <number>` line, so the replay had nothing to compare. The value
itself was unchanged (the authors' driver printed `-1.235506919564D+03`). Not a numerical change. The recipe now also prints the
claimed VALUE line, converting the Fortran `D` exponent to `E`.

Replay 2 (2026-11-27 09:10Z, `evidence/replay-2026-11-27T090940Z.log`): AGREES with the record. Recurrence check: the next
scheduled replay follows the ledger's replay-due duty.
