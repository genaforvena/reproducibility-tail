# donnelly1973-bivnor-462 — result

**Paper:** Donnelly, T. G. (1973), Algorithm 462: Bivariate normal distribution (BIVNOR), CACM 16(10), p. 638 (TOMS Algorithm 462).

**Claim:** BIVNOR(h=0.8, k=-1.5, r=-0.9), the standard bivariate normal CDF, as printed in row 1 of the shipped reference output (`Fortran/Dp/Drivers/res`): **0.147355** (g14.6). Tolerance: 5e-07 absolute.

**Our value:** 0.147355 (difference 0 at the printed precision).

**Verdict:** `reproduced`
**Basis:** `patched` (build-only). The archive's Makefile does not build as shipped; see "Original attempt". No source file was edited.

## Original attempt

The Makefile as shipped expects `src.f` and `erf.f` in `Drivers/`, but the shar places them in `Src/`:
`make: *** No rule to make target 'src.f', needed by src.o. Stop.`
Log: `evidence/original-attempt-build.log`.

## Build-only workaround

A directory of symlinks to the unedited archive files (Makefile, driver.f, src.f, erf.f), then the Makefile's own target:

```
make F77=gfortran "F77OPTS=-O2 -std=legacy" Res
```

Manifests (`evidence/manifest.pre`, `.mid`, `.post`) show no source change between pre, mid and post. The `patch` record is build-only with four files compared and none modified.

## Exact command

`reports/donnelly1973-bivnor-462/recipe.sh` (rebuilds from the archive and reruns inside `tools/sandbox.sh`).

## Environment pins

- Archive: `netlib.org/toms/462.gz`, sha256 `547505dbaaa2b140deffa1ed3f90c133d637b70502e468b0dc8a26c09ad88aa0` (matches the queue entry).
- Compiler: GNU Fortran 16.2.0 (conda-forge gcc 16.2.0-7), flags `-O2 -std=legacy`.
- Sandbox: `tools/sandbox.sh`.

## Evidence

- Run output: `evidence/run-pass1.txt`
- Build log: `evidence/build-run.log`
- Shipped reference row: `evidence/shipped-res.txt` (sha256 recorded in `evidence/shipped-res.sha256`)
- Archive check: `evidence/archive-sha256-check.txt`
- Manifests: `evidence/manifests/`

## Replay (G5)

- 2026-11-27T12:58:26Z: failed on the label only. The recipe printed no `VALUE` line matching the registered name. Recipe label corrected in commit 3dff36d. The value itself was 0.147355.
- 2026-11-27T13:15:37Z: clean replay, `VALUE BIVNOR(0.8, -1.5, -0.9) 0.147355`, agrees with the record (commit aac3428).

## Limits

- Comparison is at the six significant digits printed by the shipped driver (g14.6). The tolerance of 5e-07 is the rounding half-unit of the printed value; the computed value is not compared to more digits.
- The build is patched in the sense of the Makefile path only. The original Makefile failure is kept above.

## Note on this file

This `result.md` was written on 2026-11-27 (rerun wake 1795805886994247576) after the result record, the ledger row and two replays already existed. It was missing before, which left the ledger link broken and the entry counted as open by `checks/queue-state.py`. The verdict and values are unchanged from `result.json`.
