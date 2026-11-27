# benner2006-hapack-854: HAPACK 1.1 (ACM TOMS 854), DHAESU example

**Claim.** WR(1), the real part of the first stable eigenvalue of the DHAESU example (tdhaesu.f, dhaesu.dat, N=5),
as the authors' shipped reference output `dhaesu.res` prints it: **-3.1941**, tolerance 1e-4 absolute (registered in
queue/benner2006-hapack-854.json, queue commit 2ee3b7f). Source of the value: `artifact-reference`, the authors' own
shipped output, not a number printed in the paper (the paper's table was not readable from this sandbox).

**Verdict.** `reproduced`, basis `patched` (build-only). This run's value: **-3.1941**, difference 0.0000,
within the tolerance.

## What ran

- Archive: netlib TOMS 854.zip, sha256 `dc9ab3fb0bc12bd5c7d5b8ea8b5805bb7a8b6c38b0926f519632be4cdb580c66`, equal to the
  hash in the queue entry (evidence/fetch.log).
- Compiler: GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, from micromamba in the sandbox. Flags:
  `-O2 -std=legacy -w -fallow-argument-mismatch`. The last flag is needed because gfortran rejects argument-type
  mismatches in this old code by default; it does not change the arithmetic.
- LAPACK and BLAS: the Debian reference packages liblapack3 and libblas3 3.12.0-3build1.1 (read-only in the sandbox).
- Library: the 46 unedited `.f` files in `Fortran77/Dp/Src` compiled and archived into `hapack.a`.
- Driver: the unedited `Fortran77/Dp/Drivers/tdhaesu.f` compiled and linked against `hapack.a`, `-llapack -lblas`.
- Run: `./tdhaesu < dhaesu.dat` in the sandbox (no network). Output: evidence/run.out.
- The verification is in `reports/benner2006-hapack-854/recipe.sh`, which rebuilds and reruns it from the archive.

## Original attempt (G1)

The authors' documented route is to set the macros in `make.inc` and run `make`. The archive ships no `make.inc`; the
template `Doc/make.inc` names `f77`, which is not installed in the sandbox. The documented `make` fails at the first
compile: `make: f77: No such file or directory`, `make_exit=2` (evidence/original-attempt.log). Outcome `failed`.

## Why build-only

Instead of writing a `make.inc`, the build runs gfortran directly with the same compile options as the template and
with the system libraries. Every source file is byte-identical before and after the build: `manifest.pre`,
`manifest.mid` and `manifest.post` have 65 files each and no differences; `verify_sources.py record` classifies the patch
`build-only` (reports/benner2006-hapack-854/result.json, `patch`). The build commands are the two lines in the recipe
between the second and third manifest calls.

## Diagnostics (not judged)

- Precision: WR(1) is printed to 4 decimals both in the shipped file and in this run; the tolerance 1e-4 is the
  registered value, so an agreement at the printed digit is the test.
- The run prints S, T, G, U and V with more digits than the shipped file, which lists them to 4 decimals; those
  matrices are not part of the claim and are not compared.
- Conjugate-pair order: the shipped file gives WI(2) = -0.3179 and WI(3) = +0.3179; this build gives the opposite
  signs for the same pair (eigenvalues 2 and 3, both with real part -0.1350). The claim is WR(1), which is not affected.

## Evidence

- reports/benner2006-hapack-854/recipe.sh (one command rebuilds and reruns; prints `VALUE R(1) ... -3.1941`)
- reports/benner2006-hapack-854/evidence/ : fetch.log, original-attempt.log, build.log, run.out, recipe-run.log,
  shipped-dhaesu.res (sha256 0ad09ec8f36bb56931f80df4e7263f255f919c00fe05b73661025fbcb01ce9a2), manifest.pre/mid/post
- reports/benner2006-hapack-854/result.json (claim, verdict, gates, patch record)

## Replay

See `replayed` in result.json. The clean replay is `tools/replay.py --id benner2006-hapack-854`, which wipes the
scratch directory and reruns the recipe from nothing.
