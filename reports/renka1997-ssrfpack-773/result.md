# renka1997-ssrfpack-773: result

**Paper:** Renka (1997). Algorithm 773: SSRFPACK, interpolation of scattered data on the surface of a sphere with a
surface under tension. ACM TOMS 23(3). Stack: Fortran 77. Field: numerics. The paper text was not reachable, so the
claim is the shipped reference output.

**Claim (artifact-reference, registered 2026-11-27T03:36Z):** FF(16,16) of the SSRFTEST output grid, i.e. line 562 of the
shipped `Drivers/Sp/RES`. Value 0.4441613, absolute tolerance 1e-6. Not changed.

## Verdict

- **Verdict:** blocked (the claim as registered does not decide the verdict; see `note-to-scout.md`)
- **Basis:** original (unmodified sources; the compile lines are ours because the archive ships no build file)
- **Values by toolchain** (line 562, shipped 0.44416130):

| Pass | Toolchain | Flags | FF(16,16) | Against 1e-6 |
|---|---|---|---|---|
| 1 | gfortran 16.2 | -O2 | 0.44415909 | miss (2.21e-6) |
| 2 | gfortran 16.2 | -O2 (repeat) | 0.44415909 | miss (agrees with pass 1) |
| 3 | gfortran 16.2 | -O0 | 0.44416130 | hit |
| 4 | gfortran 13 | -O2 | 0.44416130 | hit |

- **Probe (diagnosis, not the verdict):** gfortran 16.2 -O1 hits; -O2 -fno-tree-vectorize hits; -O2 -ffloat-store and
  -O2 -ffp-contract=off still miss. So the miss follows the auto-vectoriser in gfortran 16.2 -O2 (diagnosed by flag
  toggling, not by reading the vectorised loop).

## Why blocked

A miss under one toolchain and a hit under another means the registered 1e-6 does not separate a reproduction from a miss.
The claim names no toolchain. Recording the gfortran 16 -O2 value as not-reproduced would need a confirming second pass,
and the second toolchain reproduces, so it is not confirmed. Recording the gfortran 13 value would choose the friendlier
environment after the fact. The scout owns the claim and tolerance, so I did not change either.

## Notes

- The driver writes `RES` (`STATUS='NEW'`), not `ssrftest.out` as the queue's claim location says. I read `RES`.
- `evidence/shipped-RES.txt` (sha256 336b18c8…) is the shipped reference output, copied from the sha-checked archive.
  Shipped 773.gz sha256 410dc353… matches the queue entry.
- The `-O2` miss is a single-precision reduction order difference, not a source change.
- Replay (G5) not run; no `VALUE` is recorded as a result because the verdict is blocked.

## Recipe

`recipe.sh` rebuilds and reruns the four passes through `tools/sandbox.sh`. `probe-flags.sh` runs the diagnosis.
