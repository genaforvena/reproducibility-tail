# hutchinson1986-cubgcv-642: reproduced

**Verdict: reproduced.** Basis: original (the authors' source ran as shipped).

The claim is the printed output of the shipped CUBGCV test driver (seed DSEED = 1.2345D4, 50 points, cubic smoothing spline). Nine values are registered: VAR, generalized cross validation, mean square residual, and Y and SE at I = 1, 21 and 41. Tolerance is 1e-4, the print rounding unit.

| value | registered | our run (-O0) | our run (-O2) |
|---|---|---|---|
| VAR | 0.0279 | 0.0279 | 0.0279 |
| GCV | 0.0318 | 0.0318 | 0.0318 |
| MSR | 0.0246 | 0.0246 | 0.0246 |
| Y(1), SE(1) | 0.0342, 0.1004 | 0.0342, 0.1004 | 0.0342, 0.1004 |
| Y(21), SE(21) | 0.9069, 0.0525 | 0.9069, 0.0525 | 0.9069, 0.0525 |
| Y(41), SE(41) | -0.6242, 0.0541 | -0.6242, 0.0541 | -0.6242, 0.0541 |

The -O0 and -O2 outputs are byte-identical (`evidence/run-O0.txt`, `evidence/run-O2.txt`).

## What ran

- Source: `netlib.org/toms/642.gz`, sha256 `fea2d2ad...` checked. Gunzipped text sha256 `7d302910...`, which matches the claim's reference sha.
- Source is lines 1 to 628 of the gunzipped file, unedited: CUBGCV, its subroutines, the TEST DRIVER and GGRAND. Lines 630 onward are the printed output and are never compiled.
- `gfortran -std=legacy` (a compile flag, not a source edit) at -O0, with -O2 as a cross-check.
- Values parsed on the host from the printed table rows (I = 1, 21, 41) and the summary lines.

## Limits

- The registered values are the shipped printed output, not numbers from the paper. The paper was not read (paywalled). So this shows the shipped code reproduces its shipped output, as with piessens1973-bromin-453.
- No build patch, no manifests needed.

Recipe: `recipe.sh`. Evidence: `evidence/`. Scratch directory deleted after the record is committed.
