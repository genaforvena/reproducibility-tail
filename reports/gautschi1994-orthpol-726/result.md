# gautschi1994-orthpol-726: ORTHPOL (TOMS 726, Fortran), claim DBETA(1) at om2 = 0.100

**Verdict: reproduced.** Basis: `patched` (build-only; no archive file edited). Grade: B (authors' code with build fixes).

## Claim (registered, not edited)
- Location: `test1.out` in the archive (`netlib.org/toms/726.gz`, sha256 `b229159f…fa186`), first block (modmom = .true., om2 = 0.100), row K = 1, DBETA(1).
- Paper (shipped reference) value: `0.5065840806382684475158495727` (Fortran D format).
- Tolerance: 1e-12 absolute.

## Our value
- `0.5065840806382684302633379048` (double `0.5065840806382684`).
- Difference from the shipped value: about 2e-17, within the tolerance. Margin about 2e-5 of the tolerance.
- Two passes from a fresh unpack gave identical output (`evidence/recipe-run-pass1.log`, `evidence/recipe-run-pass2.log`).

## What the authors' artifact did (G1)
1. `make test1.out.local` with the shipped Makefile: stops, because `f77` is absent in the sandbox (Error 127). See `evidence/original-attempt.log`.
2. The unpacked Makefile's link rules are empty. The archive is a shell archive whose heredoc is unquoted, so `/bin/sh` expands `$(LD)` and `$(TEST1)` to nothing when it unpacks the file. The `test1` rule reads `test1 : ; -o $@`. Only the Makefile is affected; the sources and the reference output are intact.

## Build (build-only, proved by manifests)
- The archive's own TEST1 object list, compiled with the sandbox gfortran 16.2.0 (conda-forge) as F77 and FC, with `FFLAGS=-fallow-invalid-boz`, then linked by hand with the same list. Commands are in `recipe.sh` and recorded in `result.json` `patch.build_commands`.
- `-fallow-invalid-boz` is needed because the archive ships the CDC Cyber 205 machine constants active in `r1mach.f` and `d1mach.f`, written as `x'...'` hexadecimal constants, which gfortran rejects by default.
- `tools/verify_sources.py record`: `build-only`, 45 files compared, 0 changed before the build.

## Limits (what this does not show)
- The archive ships the Cyber 205 machine constants active. On IEEE hardware the single-precision error column differs from the shipped one (for example K = 0: 0.4455E-07 against 0.1433E-13). That column is not claimed, and the DBETA(1) claim agrees anyway. Deeper rows differ at the 1e-17 to 1e-14 level, which is not checked.
- The shipped `test1.out` is also reproduced in its other rows only to the extent of the claim; no other row is claimed.

## Evidence
- `reports/gautschi1994-orthpol-726/evidence/`: fetch log, env pins, G1 log, build log, driver run log, `Res` (our output), `test1.out.shipped` and its sha256, manifests pre/mid/post, recipe run logs for both passes.
- Command: `reports/gautschi1994-orthpol-726/recipe.sh` (fetch, G1, build, run, VALUE).
- Environment: gfortran 16.2.0, gcc_linux-64 16.2.0, libgfortran5 16.2.0 (conda-forge), `evidence/env-pins.txt`.
