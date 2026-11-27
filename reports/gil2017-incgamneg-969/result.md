# gil2017-incgamneg-969 (TOMS 969, incomplete gamma* for negative arguments)

**Verdict: reproduced.** Basis: `patched` (build-only). Stack: Fortran 90. Field: numerics (special functions).

## Claim

The shipped driver's reference value gamma*(a,z) at a = -0.03, z = -0.03 (`testgamstar.f90`, `DATA igams(11)` = 0.98117651308252274; the same value is printed in `OutGammStar`). Tolerance: absolute 1e-9, fixed in the queue entry.

This is an artifact-reference claim: the number is the authors' shipped expected value. The paper states relative accuracy of about 1e-13 in this region; it prints no table of this value.

## Result

| | value |
|---|---|
| registered reference | 0.9811765130825227 |
| ours, pass 1 | 0.9811765130825 |
| ours, pass 2 | 0.9811765130825 |
| clean replay (G5, 2026-11-27T03:23:25Z) | 0.9811765130825, agrees |
| absolute difference | about 2e-14 (inside 1e-9) |

The driver prints 13 significant digits, so the recorded value is the printed one. The driver's own ERR column reports 3.3e-16 relative to the shipped reference.

## Original attempt (G1)

The authors' Makefile as shipped, run in `Fortran90/Drivers`, fails at once: `No rule to make target 'setprecision.f90', needed by 'setprecision.o'`. Its `SRCS` names the sources that live in `../Src`. Log: `evidence/original-attempt.log`.

## Patch (build-only)

No source file is changed. The patch step copies the unpacked tree and builds the authors' own Makefile with one make variable: `make VPATH=../Src`. The manifests (`evidence/manifest.pre`, `.mid`, `.post`) show six files unchanged before the build, and `verify_sources.py record` classifies the patch as `build-only`. So G2 needs no paper check.

## Environment

- gfortran 16.2.0 (conda-forge gcc 16.2.0-7), make, installed by micromamba into the sandbox scratch.
- Archive: netlib `969.zip`, sha256 4d365512e230338da001de56c62cfc5b78aa74e4f3b9f1a32b1dabe93e5a3ce7 (matches the queue entry).
- Sandboxed by `tools/sandbox.sh`; network only in the fetch step.

## Command and evidence

- Rebuild and rerun: `bash reports/gil2017-incgamneg-969/recipe.sh`. It prints `VALUE gamma*(-0.03,-0.03) 0.9811765130825`.
- Evidence: `reports/gil2017-incgamneg-969/evidence/` (build and run logs, the two `testGammStar.dat` tables, `values.txt`, `reference.txt`, manifests, clean replay log).

## Tooling note

The gate's archive-hash lookup in `tools/verify_sources.py` (`archive_sha`) matched only `.gz` archives. This entry registers `969.zip`, so the lookup returned no hash and the gate refused the build-only record. The regex now accepts `.zip` as well. The queue entry is unchanged.

## Licence

Netlib TOMS archive; the licence distributed with `969.zip` is not restated here.
