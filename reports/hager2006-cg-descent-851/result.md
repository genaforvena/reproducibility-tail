# hager2006-cg-descent-851: reproduced (basis original)

Paper: Hager and Zhang, "Algorithm 851: CG_DESCENT, a conjugate gradient method with guaranteed descent", TOMS 32(1), 2006.
Code: netlib TOMS 851.zip (Fortran 77).

## Claim

The User's Guide example (driver1.f: n = 100, starting point x = 1, grad_tol 1e-8, default cg.parm) prints
cg iterations 32, function evaluations 55 and gradient evaluations 45, as in the shipped res1. Exact match
(tolerance 0; integer counts from a deterministic algorithm).

## Result

| counter | shipped res1 | pass 1 (gfortran -O0, the original attempt) | pass 2 (gfortran -O2) |
|---|---|---|---|
| cg iterations | 32 | 32 | 32 |
| function evaluations | 55 | 55 | 55 |
| gradient evaluations | 45 | 45 | 45 |

Verdict: **reproduced**. Basis: **original**. The archive built and ran as its own driver1.f header documents, with no
change to the code, the build, or the data.

## Not claimed, reported for completeness

- Final gradient: 0.8944D-08 here, 0.8963D-08 in res1. Both are at the 1e-8 stop tolerance; not part of the claim.
- Function value: -653.07867273306204 here, -6.5307867273306158E+02 in res1. The same number to about 1e-12 relative;
  the difference is the print format. Not part of the claim.

The gradient difference is not explained. The likely cause is compiler-level floating-point differences in the last
iterate, but this was not tested, and it does not change the verdict.

## Commands

From `reports/hager2006-cg-descent-851/recipe.sh`, every step in `tools/sandbox.sh`:

- fetch: `851.zip` (sha256 checked), unzipped into `/work/pre`
- original attempt: `gfortran -O0 -o driver1 driver1.f ../Src/src.f`; `cp data1 cg.parm`; `./driver1 < data1 > res1.out`
- pass 2: the same with `-O2`, in a separate copy

The Doc/Makefile is not used. Its rules expect src.f in the driver directory, which the archive does not provide.

## Pins

- archive: netlib 851.zip, sha256 `0ac7f494b814e7c7cb5eb13d8b5b2d569ed7c9d575486614a6f6dc7b681f4e95`
- compiler: gfortran 13 (conda-forge latest at fetch time, 2026-11-26)
- reference: `evidence/reference/res1`, sha256 `da57b1de4c37ec140a1e15f5b92db09bb497710bf2212722eff8b3bd60d38297`

## Evidence

- `evidence/original-attempt.log`: build and run as documented (build_exit=0, run_exit=0)
- `evidence/pass1-output.txt`, `evidence/pass2-output.txt`: the printed results of each pass
- `evidence/pass2-run.log`: pass 2 (-O2)
- `evidence/recipe-run.log`: the full recipe run

## Gates

G1 pass (the original attempt is the run). G2 n/a (no patch). G3 pass (two passes, same counters). G5 n/a until the
replay is due.
