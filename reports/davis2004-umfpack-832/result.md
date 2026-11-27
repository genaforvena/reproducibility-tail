# davis2004-umfpack-832: result

**Verdict: reproduced.** Basis: `patched` (build-only; no authors' source file changed).

## Claim (registered before any run, queue/davis2004-umfpack-832.json)

The "numeric factorization flops" value that the shipped reference output
`UMFPACK/Demo/umf4.out` (inside `832.zip`) prints for the west0067 matrix
(`HB/west0067.rua`, 67 by 67, 294 entries) is `1.41920e+04`. The registered
tolerance is absolute 0.05, which is the print rounding of six significant digits and nothing more.
This is the code's own shipped reference output, so the match is an artifact match, not a value from the paper.
The ACM article was not read.

## Our value

| | flops for west0067 |
|---|---|
| shipped reference (`umf4.out`, line 379) | 14192.0 (`1.41920e+04`) |
| rerun, pass 1 | 14192.0 (`1.41920e+04`) |
| rerun, pass 2 (fresh unpack, same command) | 14192.0 (`1.41920e+04`) |

Difference 0.0, against tolerance 0.05. The margin is 0% of the tolerance.

## Exact command

    bash reports/davis2004-umfpack-832/recipe.sh

It runs the authors' documented `make hb` in `UMFPACK/Demo`, with `F77=gfortran` on the command line,
inside `tools/sandbox.sh`. The value is read from the first `numeric factorization flops` line after
`./readhb_nozeros < HB/west0067.rua > tmp/A` in the build log.

## Environment pins

- Archive: `netlib.org/toms/832.zip`, sha256 `c0149f87f95678435f0363c84689975cad5814ac3a6912bdb4c6894dbb74debd`. This matches the queue entry.
- C: gcc 13.3.0 (Ubuntu 24.04, `/usr/bin/gcc`), with the stock `Make/Make.include` settings `CONFIG = -DNBLAS` and `CFLAGS = -O`.
- Fortran (the `readhb` helpers only): gfortran 16.2.0 from conda-forge, installed in the sandbox by micromamba during `--fetch`.
- AMD V1.1 and UMFPACK V4.3 are built by the archive's own Makefiles.

## Gates

- G1 (original attempt first): the stock `make hb`, run in a copy with no Fortran override, builds UMFPACK, AMD and `umf4`, then fails at `readhb` with `make: f77: No such file or directory` (exit 2). Log: `evidence/original-attempt.log`. Outcome `failed`, so basis `patched` is correct.
- G2: not needed. The patch is build-only (see below).
- G3: pass. The value agrees across pass 1 and pass 2, and the west0067 log block is identical with timing lines removed. Pass 2 is a fresh unpack of the archive in the same recipe run, not a separate run of the whole recipe.
- Build-only proof: `tools/verify_sources.py record` gives `build-only`. 246 authors' source and build files were compared before and after the build, with no modified, removed or added file, and no tool changes. The build command recorded is `cd /work/pre/832/UMFPACK/Demo && make hb F77=gfortran`.

## Evidence

Everything is in `reports/davis2004-umfpack-832/evidence/`:

- `fetch.log`, `original-attempt.log`, `build-hb.log`, `build-hb.exit`, `pass2-hb.log`, `pass2.exit`, `recipe-run.log`
- `umf4.out.reference` (the shipped reference, sha256 `6b816cb5239a07adff9595229edc4d88fa0ab679c3c63f16ea56f034a97535e8`)
- `manifest.pre`, `manifest.mid`, `manifest.post` (build-only proof)

## Limits

- The claim is one number, the flop count for the west0067 case. The other three cases that `make hb` runs (can_24, fs_183_6) were run but not compared, and neither were the solve residuals or timings.
- The shipped reference is the authors' own output. It shows that the code still computes what its authors saw. It is not a value printed in the paper.
- The build uses the stock `Make.include` (`-O`, no BLAS) rather than `Make/Make.linux` (`-O3`). The flop count is an integer count from UMFPACK's own accounting, so that should not matter. This was not separately tested with other flags.
- Only the Fortran compiler name was supplied (the authors' `f77` is absent in the sandbox). The Fortran compiler is gfortran 16, not the authors' compiler.
- No `not-reproduced` verdict is involved, so the second-pass rule for negative results does not apply.

## Claim check

The registration is consistent with the shipped output and with the build, so no note to the scout is needed. Under `NBLAS` the value is the same as the reference output, which is what the claim needs.
