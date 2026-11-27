# davis2010-klu-907: result

**Paper:** Algorithm 907, KLU, a direct sparse solver for circuit simulation problems (Davis and Natarajan, ACM TOMS 2010). C code from netlib TOMS 907.zip.

**Claim (registered by scout, not edited):** the shipped KLU demo output, `Matlab/KLU/Demo/kludemo.out`, block `./kludemo < ../Matrix/w156.mtx`, prints `condest 1.79787e+09`. Tolerance 5e4 absolute.

## Verdict

- **Verdict:** `reproduced`
- **Basis:** `patched`, build-only. The authors' kludemo target does not build from the archive (it needs CHOLMOD, which the archive does not ship). The fix is a dependency supplied at build time; no archive source file is edited or added (`verify_sources record`: build-only, 145 files compared, 0 changed).
- **Our value:** `1.79787e+09` (difference 0 against the printed value, tolerance 5e4).
- **Status of the commit:** the gates duty passes (`python3 checks/gates.py --repo .` prints nothing). The archive sha256 is registered in the queue entry by scout (commit 29d90e1).

## Two passes (G3)

Both passes ran `recipe.sh` from a clean scratch directory:

1. Pass 1: `VALUE KLU_CONDEST_W156 1.79787e+09` (`evidence/recipe-run-pass1.log`)
2. Pass 2: `VALUE KLU_CONDEST_W156 1.79787e+09` (`evidence/recipe-run-pass2.log`)

## Cross-check against the shipped output

Five other matrices from the same `kludemo.out` were run with the same binary: 1c, arrowc, arrow, impcol_a and ctina. For each, `n`, `nnz(A)`, `nnz(L+U+F)`, `resid` and `condest` match the shipped block exactly (`evidence/cross-check.txt`). The file `evidence/kludemo-shipped.out` has sha256 `2deae3955d3c826ea82f6c007484a02ef36c5d9ae01009077d49c1106a96ebe7`, the value the queue entry's reference names.

## Exact command

    reports/davis2010-klu-907/recipe.sh

Every compile and run goes through `tools/sandbox.sh` (read-only root, scratch on the spare drive, no network after the fetch step).

## Environment pins

- Archive: netlib `https://netlib.org/toms/907.zip`, sha256 `d01a10366cc289ea803b119ea5f62dfa548867fe12460f9e2c593bab6489dc31` (observed today; the queue entry does not register it yet).
- Compiler and flags: `cc -O3 -fexceptions` (from the archive's `UFconfig.mk`), with `cc` from the sandbox image.
- CHOLMOD: SuiteSparse 7.10.1 from conda-forge, installed by micromamba into `/work/env` (pins in `evidence/env-pins.txt`). This is a newer CHOLMOD than the 2009 one the authors used. It is used only by `kludemo.c` to read the Matrix Market file.
- KLU, AMD, COLAMD and BTF: built from the archive's own sources by its Makefiles.

## Original attempt (G1)

The authors' `make kludemo` in a copy of the tree stops at compile time:

    kludemo.c:303:10: fatal error: cholmod.h: No such file or directory

The archive has no CHOLMOD tree, and the Demo Makefile links `../../CHOLMOD/Lib/libcholmod.a`, which is also absent. The log is `evidence/original-attempt.log`. The authors' own `klu_simple` target builds and runs without CHOLMOD; the failure is only in the reader used by `kludemo`.

## Build route

The authors' Makefile builds the KLU library and `klu_simple`. `kludemo` is then compiled with the Demo Makefile's own compile line, with the CHOLMOD include and library directory pointed at `/work/env`. The archive sources are untouched.

## Evidence

- `evidence/fetch.log`, `evidence/env-pins.txt`
- `evidence/original-attempt.log`
- `evidence/manifest.pre`, `manifest.mid`, `manifest.post`
- `evidence/recipe-run-pass1.log`, `evidence/recipe-run-pass2.log`
- `evidence/kludemo-run.log`, `evidence/kludemo-run.out`, `evidence/kludemo-shipped.out`, `evidence/cross-check.txt`

## Gate bookkeeping

The first gates run failed because the queue entry had no archive sha256 (G2) and because G0 compares the entry byte-for-byte. Scout registered the sha256 in commit 29d90e1, which changes only the `code.archive` text. The claim and tolerance sections are identical at 2085a4d (the commit the run was made against) and at 29d90e1. `result.json` therefore records `queue_commit` 29d90e1, the last commit touching the entry, and `patch.archive_sha256` was re-recorded from the registered hash. The G0 check is the same comparison as before, applied to the claim-bearing commit.

## What would change the verdict

- A different `condest` from a third pass.
- A different archive hash on the scout's own download (the recorded archive hash would then differ, and the run would need repeating against the registered archive).
- A failure of the cross-check on any of the other five matrices.
