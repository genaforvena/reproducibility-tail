# patterson1973-quad-468: Algorithm 468, QUAD (automatic numerical integration over a finite interval)

**Verdict: partial.** Basis: `patched`. Claim source: `artifact-reference` (the shipped `res` output of the archive's own test program).

## Claim

The TEST01 table of the archive's test program prints `RESULT(K)` for 13 integrands at EPSIL = 0.001. Four rows are registered: f07 on [0, 1], f08 on [0.1, 1], f12 on [0, 1], f13 on [0, 1]. Values and tolerances are fixed in `queue/patterson1973-quad-468.json` (commit 826c062) and were not edited.

| integrand | paper value | ours | abs diff | tol_abs | within tol |
|---|---|---|---|---|---|
| f07 on [0, 1] | 0.7775046341 | 0.777505 | 3.7e-7 | 7.8e-4 | yes |
| f08 on [0.1, 1] | 0.009098645256 | 0.00909898 | 3.3e-7 | 9.1e-6 | yes |
| f12 on [0, 1] | -0.6346651825 | -0.634670 | 4.8e-6 | 6.3e-4 | yes |
| f13 on [0, 1] | 0.01349248565 | 0.0135495 | 5.7e-5 | 1.35e-5 | **no** |

f13 also reports `ICHECK = 1` in TEST01 (QUAD's own accuracy flag). The claim requires `ICHECK = 0` for the registered integrands, so f13 fails on both counts. The source comments on f13 say the archive's printed exact value 0.0013492485650 is "apparently a typo" and use 0.013492485650. That corrected value is the registered one, and we did not change it.

## Cause (f13)

`numerical-discrepancy`. QUAD, at EPSIL = 0.001, reports failure (ICHECK 1) for f13 on [0, 1] and returns 0.0135495. The archive's own shipped output `res` contains the same line, so the code still produces what its authors recorded. The mismatch is between that output and the registered reference value. TEST02 and TEST03 (QSUB, QSUBA) return 0.134925E-01 with ICHECK 1 and small relative error. This points at QUAD's adaptive path for this integrand, not at a build problem. We did not diagnose the algorithm further.

## Original attempt (G1)

The shipped `Makefile` as documented, run in the sandbox, stops at once: `make: f77: No such file or directory`. With `F77=gfortran` it stops with `No rule to make target 'src.f', needed by 'src.o'`. The archive is a shell archive (shar), not the single Fortran file the queue note describes: it holds `Fortran/Sp/Drivers/{Makefile,driver.f,res}` and `Fortran/Sp/Src/src.f`, and the Makefile expects `src.f` beside `driver.f`. Log: `evidence/original-attempt.log`. A first compile of the raw shar text as Fortran was also run and failed; its log was deleted by mistake. No result depends on it.

## Patch (basis)

- Toolchain: micromamba from the official mirror and gfortran (conda-forge) installed in the sandbox scratch during the `--fetch` step. Host has no Fortran compiler.
- Build: `make F77=x86_64-conda-linux-gnu-gfortran F77OPTS='-std=legacy -w'`, after copying `Fortran/Sp/Src/src.f` beside `driver.f`. No source edits.

## Replay and second pass (G3, G6)

- Pass 1: the Makefile's own `./driver > Res` target, optimised build.
- Pass 2: clean directory, `-O0` rebuild, run again.
- Both passes produce output byte-identical to the shipped `res` file (`evidence/reference/res`, sha256 b8d29a1d…). Both give the same f13 miss.
- The recipe was run from an empty scratch directory and gave the same values.

Limits: the two passes share the same compiler (gfortran 16.2.0 conda-forge) and the same source. Passes differ only in optimisation level. The code is deterministic, so there is no seed.

## Environment

- Sandbox: `tools/sandbox.sh`, bwrap, no network after the fetch step.
- gfortran: conda-forge `gfortran_linux-64` (gcc 16.2.0-7 family), installed with micromamba 2.10.0.
- Archive: `netlib.org/toms/468.gz`, sha256 `1891044f…d82319`, 13609 bytes. Uncompressed text sha256 `aeb69783…10f73b`.
- Shipped `res` output: sha256 `b8d29a1d…aea6b`.

## Evidence

- `evidence/original-attempt.log`: G1 original attempt, plus the failed `F77=gfortran` run.
- `evidence/recipe-run.log`: recipe output, from a clean scratch.
- `evidence/run1-output.txt`, `evidence/run2-output.txt`: outputs of the two passes.
- `evidence/values.txt`: parsed RESULT and ICHECK values per pass.
- `evidence/reference/res`: the shipped reference output.
- `evidence/pass2.log`: the -O0 second pass.

## Rebuild

`reports/patterson1973-quad-468/recipe.sh`: fetch, unpack, original attempt (once), patched build, two passes, VALUE lines.

## What would change the verdict

- A different integrand or tolerance in the registered claim would need the scout to revise the queue entry. We did not edit it.
- If the authors' published QUAD (a corrected release) gives ICHECK 0 and the registered value for f13, that would reproduce the claim. We have not searched for it.
