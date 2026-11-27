# zwolak2007-odrpack95-869: result

**Verdict: reproduced.** Basis: **original** (the authors' sources, unchanged, built with their makefile's default flags and run as their driver documents). The compiler is conda-forge gfortran installed in the sandbox fetch step, because `f95` is not available here (G1: toolchain install, then retry).

## Claim

BETA(1) of the explicit ODR fit in `F95/Drivers/simple_example.f90` (ODRPACK95, ACM TOMS Algorithm 869), as printed in the shipped reference `F95/Drivers/simple_example.out`, section "Estimated BETA(J)", row J = 1. Registered value 1.63337057, tolerance abs 1e-6, fixed at registration (2026-11-27T09:33:00Z). Neither the claim nor the tolerance was edited.

## Values

| name | paper (shipped output) | ours pass 1 | ours pass 2 | tol_abs | result |
|---|---|---|---|---|---|
| BETA(1) (ODR, simple example) | 1.63337057 | 1.63337057 | 1.63337057 | 1e-6 | within tolerance |

Pass 1 and pass 2 are identical (`evidence/values-run1.txt`, `evidence/values-run2.txt`). The difference to the paper is below the 9-digit print resolution (about 5e-9), so the margin against tolerance is far under the 80% flag.

## Sensitivity to optimisation (not the verdict)

The same sources built with `gfortran -O2` give BETA(1) = 1.63337663 (`evidence/run-sensitivity-O2.txt`). That is 6.1e-6 away from the paper, six times the registered tolerance. The authors' makefile passes no optimisation flag, so the verdict uses the documented build; the -O2 run is recorded because the claim is sensitive to the compiler's optimisation level. A reader who rebuilds with optimisation should expect a different digit at the sixth decimal. This is a finding about the code's numerical sensitivity, not a failure of the reproduction.

## Commands and environment

- Command: `reports/zwolak2007-odrpack95-869/recipe.sh` (fetch, build, two passes, sensitivity run). Every build and run goes through `tools/sandbox.sh`.
- Archive: `https://netlib.org/toms/869.zip`, sha256 `404eb22d15122a6ce59959f39737cba198a3767eb1976ceb8f12b211c3a09550` (the scout did not record one; this wake recorded it and the fetch checks it).
- Compiler: GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, from conda-forge via micromamba (`gfortran_linux-64`).
- Sources compiled in order: `F95/Src/real_precision.f`, `F95/Src/odr.f`, `F95/Src/lpkbls.f`, then `F95/Drivers/simple_example.f90`, linked as `simple_example`.
- Reference output: `evidence/reference/simple_example.out`, sha256 `9e1862cc4c94ccfcff7ddbe472577a7e2d426f6f5351322401d68da57e56565a`. Our run's full stdout differs from it only in trailing spaces on two response-table lines.

## Evidence

- `evidence/original-attempt-build.log`: the build and run of pass 1 (the G1 attempt, kept once).
- `evidence/run-pass1.txt`, `evidence/run-pass2.txt`: full driver output for each pass.
- `evidence/recipe-run.log`: the recipe's own log of the run that produced this verdict.
- `evidence/run-sensitivity-O2.txt`: the -O2 sensitivity run.
- `impl/extract_value.py`: reads row J = 1 of the BETA table and prints the `VALUE` line.

## Gates

G1 pass (authors' sources first, compiler installed in the sandbox fetch step, then retried). G2 na (no patch, no reimplementation). G3 pass (two passes, identical). G5 not yet run (a scheduled replay will confirm it). G6 na (verdict is not `not-reproduced`).

## What would change the verdict

If a clean rebuild with the authors' documented flags gave a value outside 1.63337057 ± 1e-6, the verdict would change. The -O2 result already shows the claim is optimisation-sensitive, so a replay that adds optimisation flags would not be the same test.
