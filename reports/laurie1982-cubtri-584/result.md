# laurie1982-cubtri-584: result

**Verdict: reproduced.** Basis: **original** (the archive's single Fortran file compiled, linked and ran exactly as shipped; no edit, no workaround).

## Claim

Integral of EXP(SIN(X)*COS(Y)) over the triangle (0,1), (0,0), (1,0), computed by CUBTRI from ACM TOMS Algorithm 584 (Laurie 1982) at EPS = 1E-3, MCALLS = 20000, NW = 5000, with IER = 0 expected. The reference is the shipped driver's `ACTUAL(4) = .6918104506612316` (credited in the driver comment to Haegemans 1977). Registered tolerance: tol_abs = 6.918104506612316e-4 (1e-3 relative to the reference), fixed at scout registration (queue commit 7d43a92) and not changed.

The value is registered under the short key `cubtri_int4_eps1e-3`; the queue's descriptive name is "integral of EXP(SIN(X)*COS(Y)) over the driver's triangle".

## Result

- Paper (driver reference): 0.6918104506612316
- Ours: 0.691810429096 (driver row for integrand 4, EPS = 1.E-03, IER 0; printed to 12 decimals)
- Difference: about 2.2e-8, against tol_abs 6.9e-4.

Note: the driver stores ACTUAL and ANS in single precision, so its own ACTUAL-ERROR column prints 0.0E+00 for this row. That is a property of the shipped driver, not a failure.

## Original attempt (G1)

Succeeded on the first try. `gfortran -O2 -std=legacy` compiled and linked `584.f` (456 lines: main KONYN, F, CUBTRI, RNDERR, CUBRUL) with exit 0. The only message is a Fortran 95 warning about the H format specifier. Log: `evidence/original-attempt-build.log`.

## What was run

1. Fetch (sandbox, network only here): `584.gz`, sha256 checked (`evidence/archive-sha256-check.txt`), gfortran 16 from conda-forge via micromamba.
2. Unpack: file copied verbatim to `tree/584.f`; `cmp` against the archive member shows identical bytes (`evidence/patch-none.txt`). Manifests pre, mid and post are in `evidence/manifests/`.
3. Compile and link as shipped, then run the driver with no input. Exit 0. Output: `evidence/run-pass1.txt`.
4. Reference lines from the archive (driver lines 1-40, containing `ACTUAL(4)`): `evidence/shipped-driver-actual4.txt`, sha256 c42465f5...

## Environment pins

- GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, flags `-O2 -std=legacy`.
- Sandbox: `tools/sandbox.sh`, read-only root, network only for the fetch step.

## Not yet done

- Only one pass, which is enough for a `reproduced` verdict (the second pass is for `not-reproduced`).
- G5 replay not yet due. Scratch directory `/mnt/mishe-scratch/reproducibility-tail/laurie1982-cubtri-584` is deleted after commit.

## Recipe

`recipe.sh` rebuilds the record from the archive and reruns the driver. It prints `VALUE cubtri_int4_eps1e-3 <number>`.
