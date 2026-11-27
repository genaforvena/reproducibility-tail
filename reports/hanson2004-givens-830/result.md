# hanson2004-givens-830 — result

**Paper:** Hanson, R. J. and Hopkins, T. R. (2004), "Another Visit With Standard and Modified Givens Transformations and A Remark On Algorithm 539 (Algorithm 830)", ACM TOMS 30(1), pp. 86-94. The ACM article was not read; the claim is the archive's own shipped reference output.

**Claim:** The first element of the scaled x-vector in the first test block of the shipped `res1` (`rotm_battery.f90` on `data3`): **14.519450** (E16.8). Tolerance 1e-5 absolute, fixed before the run.

**Our value:** 14.51945. The full `res1` output is byte-identical to the shipped `res1` (diff: 0 lines).

**Verdict:** `reproduced`
**Basis:** `patched` (build-only). The shipped Makefile names a NAG compiler path that does not exist here. The workaround is only a compiler override on the command line plus symlinks; no source file was edited.

## Original attempt

`make res1` with the Makefile as shipped: `make: /opt/NAGWare/bin/f95: No such file or directory`. Log: `evidence/original-attempt-build.log`.

## Build-only workaround

Symlinks to the unedited archive (Fortran90/Src, Drivers/Makefile, Drivers/rotm_battery.f90, Drivers/data3) under `/work/build/Fortran90/Drivers`, then:

```
make F90=gfortran "F90OPTS=-O2" F90LINK=gfortran "F90LINKOPTS=-O2" res1
```

The manifests (`evidence/manifests/`) show 17 source files compared: pre == mid, so the patch is build-only (`tools/verify_sources.py record`, exit 0).

## Exact command

`reports/hanson2004-givens-830/recipe.sh`, which fetches, unpacks, runs the original attempt, builds, records, and prints `VALUE rotm-x1-scaled <number>`.

## Environment pins

- Archive: `netlib.org/toms/830.gz`, sha256 `aadb021e657f625267c8aa6e4b9f4b5b83aed15a5b7755e8339798e8704925a6` (matches the queue entry).
- Compiler: GNU Fortran 16.2.0 (conda-forge gcc 16.2.0-7), `-O2`.
- Sandbox: `tools/sandbox.sh`.

## Evidence

- Run output: `evidence/run-pass1.txt`; shipped reference: `evidence/shipped-res1.txt` (sha256 in `evidence/shipped-res1.sha256`)
- Build log: `evidence/build-run.log`; archive check: `evidence/archive-sha256-check.txt`
- Replay log: `evidence/replay-2026-11-27T190207Z.log`

## Replay (G3/G5)

- 2026-11-27T19:02:07Z: clean replay, `VALUE rotm-x1-scaled 14.51945`, agrees with the record.

## Limits

- Only the first x-vector element of the first block is the registered claim. The rest of `res1` was compared as a whole file, as evidence only; it is not part of the claim.
- The ACM article was not read. The paper's own printed values are not the basis of this claim.
