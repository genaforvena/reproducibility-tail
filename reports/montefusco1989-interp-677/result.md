# montefusco1989-interp-677: TOMS 677 (MASUB), self-check values

**Verdict: blocked** (resolver: scout). Basis: patched. The measured values are within the registered tolerance; the entry cannot be graded until the archive hash is registered.

## Claim
The self-check PROGRAM MAIN of TOMS 677 (Montefusco & Casciola 1989). Its maximum and mean absolute errors (ERMAX, ERMEAN, from MMERR on the 10x10 reconstruction) against the built-in ANS2 = 0.6059994 and ANS1 = 0.06695094. Registered tolerance: relative 1e-5 on each value. The gates' schema takes absolute tolerances, so `tol_abs` in result.json is the same tolerance written out: 6.059994e-06 (ERMAX) and 6.695094e-07 (ERMEAN). The paper was not read; the claim is the archive's built-in reference.

## Our values
| value | paper (built-in) | pass 1 (gfortran -O2, recorded build) | pass 2 (clean dir, gfortran -O0) | difference (pass 1 / pass 2) | within rel 1e-5 |
|---|---|---|---|---|---|
| ERMAX | 0.6059994 | 0.6059995 | 0.6059992 | 1.7e-7 / 3.3e-7 | yes |
| ERMEAN | 0.06695094 | 0.06695094 | 0.06695094 | 0 / 0 | yes |

The program prints "EXECUTED ON YOUR COMPUTER" in both passes. The two passes differ in the seventh digit of ERMAX, which is compiler rounding in single precision.

## Why blocked
- The queue entry records no archive hash (`code.archive` says "sha256 not recorded by scout"). The archive hash here is d4d94e7a7ca6cf1980e3c05af74731cea35d00d62358ace806b134e4a8a4e64b (677.gz, fetched 2026-11-26 in the sandbox).
- A build-only record (`tools/verify_sources.py record`) and G2 need that registered hash. Without it, checks/gates.py rejects a build-only record, so result.json carries no `patch` record yet.
- Resolver: scout registers the hash in `queue/montefusco1989-interp-677.json` (`code.archive`). This is the same registration as for gaviano and buckley, as decided by the operator (#61). Once it lands: run `reports/montefusco1989-interp-677/recipe.sh` again, set the verdict to `reproduced`, the gates to G2 `na` (build-only), and regenerate the ledger.

## Basis and the original attempt
- The archive as shipped does not compile: `Error: Two main PROGRAMs at (1) and (2)` (four test programs in one file). Logged in `evidence/original-attempt.log` (kept once).
- The build compiles two verbatim line ranges of the archive, copied outside the authors' source tree: lines 1-162 (the first PROGRAM MAIN with MACEPS and MMERR) and lines 634 to the end (the MASUB package). No text is edited. The other three test programs are not compiled. This is a workaround, so basis is `patched`.
- The build-only record (manifests pre, mid, post in `evidence/`) shows the authors' tree unchanged. It is written only once the hash is registered.

## Exact command and pins
- `bash reports/montefusco1989-interp-677/recipe.sh`
- gfortran from conda-forge (gfortran_linux-64, installed by micromamba into the sandbox scratch at /work/fortran, not pinned to a version: record it when the hash lands), gfortran -O2 for pass 1 and -O0 for pass 2.
- Host: Linux 6.8.0-149-generic. Sandbox: tools/sandbox.sh.

## Evidence
- `evidence/run1-stdout.txt`, `evidence/run2-stdout.txt`, `evidence/values-run1.txt`, `evidence/values-run2.txt`, `evidence/build.log`, `evidence/recipe-run.log`, `evidence/original-attempt.log`
- Scratch (kept while blocked, not committed): /mnt/mishe-scratch/reproducibility-tail/montefusco1989-interp-677/
- Extraction helper: `impl/extract_values.py` (reads the printed ERMAX and ERMEAN lines; `VALUE` output for G5 replay).

## What would change the verdict
- Hash registered: re-record and grade `reproduced` (basis patched, G2 na as build-only).
- Scout states the extraction of the two line ranges is outside what the claim measures (for example, the other test programs are needed): then the claim needs a rewrite by scout, not by rerun.
