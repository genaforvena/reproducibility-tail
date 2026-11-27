# fullerton1972-gamma-435: reproduced (basis: patched, build-only)

Paper: W. Fullerton, "Algorithm 435: Modified Incomplete Gamma Function", Communications of the ACM 15(11), 1972.
Artifact: netlib CALGO 435.gz (shell archive), sha256 `07b19a25...1894a8d`, the scout's pinned hash.

## Claim (registered 2026-11-27T16:05:48Z, not edited)

The shipped driver's reference table, row A = 11.0000, X = 16.0000, column "Computed / Gamma(A)":
**0.92250806**, absolute tolerance 1e-6. The claim is the routine's computed value, not the exact value 0.92260396.

## Our value

**0.92250806** (`VALUE computed_A11_X16 0.92250806`). Difference from the shipped value: 0. Within tolerance.

## Verdict and basis

- Verdict: `reproduced`.
- Basis: `patched`, build-only. The authors' code ran only after a build-side change. The archive's own Makefile does not run as shipped (no `f77` in the sandbox), so the basis cannot be `original`.

## Original attempt (G1)

`make Res` with the Makefile unchanged fails at `f77 -c driver.f` (Error 127). Log: `reports/fullerton1972-gamma-435/evidence/original-attempt.log`.

## What was patched (build only, no archive file edited)

1. Compiler: the sandbox gfortran 16.2.0 (conda-forge, installed by micromamba during `--fetch`) is used in place of `f77`.
2. Layout: the Makefile expects `src.f` beside it (`src.o: src.f`), but the archive ships it in `Fortran/Sp/Src/`. The build compiles `../Src/src.f` directly. No copy is made.
3. Build commands, exactly as the recipe runs them:
   - `/work/env/bin/x86_64-conda-linux-gnu-gfortran -c ../Src/src.f -o src.o`
   - `/work/env/bin/x86_64-conda-linux-gnu-gfortran -c driver.f -o driver.o`
   - `/work/env/bin/x86_64-conda-linux-gnu-gfortran -o driver driver.o src.o`
4. `verify_sources.py record`: build-only, 3 source files compared, 0 modified, 0 added, 0 removed before the build. Exit 0. Manifests: `evidence/manifest.{pre,mid,post}`.

## Limits

- Rows other than A = 11, X = 16 are not claimed. Against the shipped table, three A = 0.5 cells and one A = 6.0, X = 2.5 cell differ in the last printed digits (by 4e-9 to 7e-8). The likely cause is arithmetic on different hardware or compiler; this is not tested. Row A = 41, X = 45 gives `NaN` here where the shipped table has `1.0000000`, with IEEE invalid and overflow flags signalled. That cell is not claimed.
- The authors' Makefile stays as shipped. Only compiler selection and the `src.f` path are changed, and both are visible in the build commands.

## Reproduction

- Exact command: `bash reports/fullerton1972-gamma-435/recipe.sh` (fetches inside `tools/sandbox.sh --fetch`, then runs everything inside `tools/sandbox.sh`).
- Passes: two. Pass 1 failed at the record step because `result.json` did not yet exist (its `record` step needs it); the record was then re-run with the same manifests and commands, exit 0. Pass 2 is a full recipe run from a fresh unpack: build exit 0, record exit 0, value 0.92250806.
- Environment pins: `evidence/env-pins.txt`. Sandbox gfortran 16.2.0 from conda-forge.
- Evidence: `reports/fullerton1972-gamma-435/evidence/` (fetch log, original-attempt log, build log, driver run, `Res`, shipped `res`, manifests).

## Why not the closed form

A is an integer here, so the exact value has a closed form. The claim is the code's own 1e-4 deviation from it, which the registered entry says is intended. A closed-form check would give 0.92260396 and fail this claim by design.
