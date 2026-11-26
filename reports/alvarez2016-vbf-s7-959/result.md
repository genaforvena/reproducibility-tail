# alvarez2016-vbf-s7-959: reproduced (basis: patched, build-only)

**Status**: all eight measured values match the registered paper values within tolerance. Verdict: `reproduced`. The build-only proof (`patch kind build-only`) shows the source tree was unchanged before the build, so the paper-text G2 check is not needed. The earlier blocked note is withdrawn.

**Claim** (scout, `queue/alvarez2016-vbf-s7-959.json`): Alvarez-Cubero & Zufiria, CALGO Algorithm 959 (ACM TOMS 42(2), 2016), VBF C++ library. Running `./ex.exe S7 7` on the 7-bit S-box in the archive prints eight measures, and `S7.cy` lists the cycles. The claim is the paper's reference values for those measures and the cycle count. Tolerance (fixed before any run): integers exact (0); the two potentials `|x - 0.015625| <= 1e-9`.

**Paper values and our values** (the recipe's `VALUE` lines, from-scratch run):

| Measure | Paper | Ours |
|---|---|---|
| Nonlinearity | 56 | 56 |
| Algebraic degree | 3 | 3 |
| Algebraic immunity | 3 | 3 |
| Absolute indicator | 16 | 16 |
| Sum-of-squares indicator | 4161536 (printed as 4.16154e+06) | 4161536 |
| Linear potential | 0.015625 | 0.015625 |
| Differential potential | 0.015625 | 0.015625 |
| Cycles in S7.cy | 4 (lengths 1, 13, 22, 92) | 4 (`S7.cy` identical to the shipped file) |

**Verdict**: reproduced. All eight measured values are inside the registered tolerance.
**Basis**: `patched`. The authors' `make ex` as documented fails (G1 log below). The NTL library was built from the archive's own bundled `SupportPackages/ntl-9.2.0`, and the Makefile's compile line was run directly with `-I../Src`. No source file was edited and no code was written.

## Commands

The whole run is `bash reports/alvarez2016-vbf-s7-959/recipe.sh` (`recipe.sh`). It runs the following steps, each inside `tools/sandbox.sh`:

1. `--fetch`: `curl` of `https://netlib.org/toms/959.zip`, then sha256 check.
2. Unzip; copy the shipped `Res/S7/S7.out` and `S7.cy` as the oracle, each sha256-checked.
3. G1 original attempt: `make ex` in `CPP/Drivers` (kept in `evidence/original-attempt.log`, not overwritten).
4. Build NTL 9.2.0 from `SupportPackages/ntl-9.2.0` to `/work/ntl` (`evidence/ntl-build.log`, exit 0).
5. `g++ -I/work/ntl/include -I../Src -L/work/ntl/lib -Wall ex.cpp -o ex.exe -lntl`.
6. `./ex.exe S7 7`, twice (`evidence/run1.log.gz`, `run2.log.gz`, and the `S7.cy` copies).
7. Print the `VALUE` lines and diff the cycle file and the measures against the shipped reference.

The recipe's own log is `evidence/recipe-run.log`. It printed `CY identical` and `measures identical`.

## Attempts

1. `evidence/original-attempt.log`: `make ex` in `CPP/Drivers` stops with `No rule to make target 'VBF.h', needed by 'ex'` (exit 2). `VBF.h` is in `CPP/Src/`, and the Makefile does not look there. This is the original attempt and is recorded as `failed`.
2. The NTL build and the direct compile (step 4 and 5 above) succeeded; the driver ran in two passes, byte-identical logs.
3. From-scratch recipe run (`evidence/recipe-run.log`, this wake, 16:48-17:04Z, with the build-tree proof): fetch, sha256, NTL build, compile and two driver runs, all exit 0. Its `VALUE` lines equal the direct passes.

## Pins

- Compiler: g++ 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1), host image in the sandbox. The authors used g++ 4.8.4 (per the queue entry). The compile printed only a `-Wmisleading-indentation` warning in `VBF.h:1379`.
- NTL 9.2.0, built from the archive's bundled `SupportPackages/ntl-9.2.0`, with the default configuration. GMP not used (optional).
- Archive `959.zip`: sha256 `e22c4212904de71769091373d279dbaa3f605a95599fe0767ff676982ed287fd` (matches the queue entry).
- Reference `S7.out` sha256 `719dd8e1…d253f`; `S7.cy` sha256 `cd2da89e…acd591d` (both checked in the recipe).

## Limits

- The reproduction is with the authors' driver and inputs; it checks the library's outputs on one 7-bit S-box, not the algorithm in general.
- The build needed a flags patch (the Makefile's rule cannot find `VBF.h`). Basis `patched` records that.
- The ACM article itself was not read (its DOI returns 403 to automated fetch), so the paper values come from the queue entry and the archive's own reference outputs.
