# boland1972-simpson-437: result

**Verdict: reproduced.** Basis: **patched** (build-only: the archive's Makefile needed src.f beside it; no source file was edited). TOMS 437, Boland's product-type Simpson rule (Fortran). The registered claim is VINT for TEST02 at N = 10: 0.521610, tolerance abs 1e-6, against the shipped reference output `Fortran/Dp/Drivers/res`.

## Claim

Product Simpson rule for the integral of exp(-x)·cos(x) over [0, π], N = 10, as printed by `driver.f` (format g14.6). Fixed at registration (2026-11-27T09:47Z). Neither the claim nor the tolerance was edited.

## Values

| name | paper (shipped output) | ours pass 1 (build-only) | ours pass 2 (direct compile) | tol_abs | result |
|---|---|---|---|---|---|
| TEST02 product Simpson, N=10 | 0.521610 | 0.521610 | 0.521610 | 1e-6 | within tolerance |

Both full driver outputs are byte-identical to the shipped `res` (`cmp` in `evidence/recipe-run.log`). The driver's exact integral prints 0.521607, which the rule converges toward (N = 10 gives 0.521610).

## Passes and the original attempt (G1)

- Attempt 1 (`evidence/original-attempt-build.log`): no gfortran in the sandbox's `/usr`. `make` fails with "gfortran: No such file or directory".
- Attempt 2 (`evidence/original-attempt-2-build.log`): with the micromamba gfortran (conda-forge, GNU Fortran 16.2.0, `evidence/gfortran-version.txt`), the archive's `Drivers/Makefile` stops as shipped with "No rule to make target 'src.f'". The Makefile looks for src.f in Drivers/, but the archive ships it in Src/.
- Pass 1 (build-only patch): the Makefile and driver are copied to a build directory with src.f next to them, and `make F77=gfortran F77OPTS=-O2 DIFF=diff SRCLIBS= driver` runs there. The tree is not edited. Manifests pre, mid and post are in `evidence/manifests/`, and `verify_sources.py record` reports `build-only: compared 3; ours modified 0, removed 0, added 0`.
- Pass 2: `driver.f` and `src.f` compiled directly with gfortran in a clean directory, no optimisation flag. Byte-identical to `res`.

The shell archive was unpacked by `impl/extract-tree.awk` (copied from snyder1993's recipe), so nothing in the archive was executed.

## Commands and environment

- Command: `reports/boland1972-simpson-437/recipe.sh`. Every build and run goes through `tools/sandbox.sh`; only the fetch step had network.
- Archive: `https://netlib.org/toms/437.gz`, sha256 `3d5d67394e0a50131e5eaf60cdfff518c41e7e70b86e01f27e9eeaf65090f3ce` (checked by the recipe).
- Compiler: GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, installed into the sandbox scratch.
- Reference output: `evidence/reference/res`, sha256 `a39beb9c5ab374145f73d25e6b156512ca116985960a08195d555ce0d537fca5`.

## Caveats

- The ACM article was not read (ACM returns 403 from this host). The registered value is the shipped reference output, which is what the claim was registered as.
- Pass 1 and pass 2 use different optimisation levels (-O2 and none) and both match `res` exactly. The claim checks one integral (N = 10) of one TEST02 family, not the whole rule.

## Gates

G1 pass (the archive's Makefile was tried first and failed; the logged failure is the attempt; the layout fix is build-only and proved from bytes). G2 na (build-only: the manifests show no source change). G3 pass (two passes, identical). G5 not yet run (scheduled replay). G6 na.

## What would change the verdict

A clean rebuild that prints TEST02 N=10 outside 0.521610 ± 1e-6, or a build whose manifests show a source change, would change it.
