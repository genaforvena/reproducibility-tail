# renka2003-dnsplin1-828: TOMS 828 (DNSPLIN1, discrete nonlinear spline interpolation)

**Verdict: blocked (G2 hold). Basis: patched (the build-only proof no longer holds). The measured value below is recorded here and not in result.json.**

Why blocked: `tools/verify_sources.py` now counts build-configuration files (makefile.inc) as source (commit 33ef940). The re-record with that tool gives `kind: source`, with `Drivers/makefile.inc` added. So the G2 paper check applies, and the not-reproduced verdict cannot stand until the paper text is read. The claim and the tolerance are unchanged.

Measured (not a verdict): ours 0.565126294872521D-01 against shipped 0.565126291685656D-01, 3.2e-10 apart, tolerance 1e-12. The earlier not-reproduced wording is withdrawn until G2 passes.

## Claim

The shipped output Fortran77/Dp/Drivers/res1 (the driver run on data1, 7 points) prints the second value after the count
241 as 0.565126291685656D-01 (row 3 of the file). Registered: absolute tolerance 1e-12, not to be loosened.

## Result

| | value |
|---|---|
| shipped (res1, row 3) | 0.565126291685656D-01 |
| ours, pass 1 (recorded -O2 build, `make Res1`) | 0.565126294872521D-01 |
| ours, pass 2 (clean directory, same binary) | 0.565126294872521D-01 |
| ours, confirmation (separate tree, compiled at -O0) | 0.565126294872521D-01 |

|ours - shipped| = 3.2e-10, outside the tolerance 1e-12. The difference is not print rounding: across all 724 numbers in the
output, 712 differ by more than 1e-12, the largest by 6.4e-8. So the discrepancy is systematic in the spline values.

## What was done

- **Original attempt (G1): failed.** The authors' Makefile, run as documented (`make Res1`), stops at its first line:
  `Makefile:11: makefile.inc: No such file or directory`. The archive ships no makefile.inc. Log:
  `evidence/original-attempt.log`.
- **Build-only patch.** A makefile.inc written from the Makefile's own variable names: gfortran (conda-forge), `-O2 -std=legacy`,
  the bundled lapack.f and dblas.f compiled as objects, and one prerequisite line `driver: lapack.o dblas.o`. Then the
  authors' target `make Res1`. No source file was edited. `verify_sources` records build-only (6 archive source files
  compared, none modified, none added).
- **Limitation of the build-only proof.** The manifest only hashes source-extension files (`is_source`), so the new
  makefile.inc is not in the proof at all. The record's "added 0" does not cover it. This should be fixed in the tool (hash
  every file in the tree, or at least every added file) before any further build-only result relies on it.
- **Runs.** Pass 1 and pass 2 as above. The confirmation pass is a separate tree rebuilt at `-O0` with the same sources.
  Output is identical, so the optimisation level is ruled out as the cause. This confirmation is weak: it changes only
  the optimisation level.

## Open

- G2 paper check: not done. Resolver: the scout (or the paper text). Disposition: next wake.

- The cause is not localised. The untested hypothesis: the authors' build linked an external BLAS and LAPACK (the Makefile's
  LAPACK and BLAS variables suggest this) rather than the bundled lapack.f and dblas.f. The next bounded experiment is to
  link a conda-forge LAPACK and BLAS in the sandbox and see whether the values move toward the shipped ones.
- G5 replay: not yet. This is not a clean replay until the recipe reruns from nothing.

## Command

`reports/renka2003-dnsplin1-828/recipe.sh`

## Evidence

`reports/renka2003-dnsplin1-828/evidence/`: the original attempt log, the recipe run log, the make logs, the reference res1,
the two pass outputs, the -O0 confirmation output, and the manifests (pre, mid, post).
