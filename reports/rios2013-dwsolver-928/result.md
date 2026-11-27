# rios2013-dwsolver-928: result (blocked)

**Verdict: blocked.** The registered claim (final master objective of `book_test` = -36.666667, tol_abs 1e-5) cannot
be checked against its reference. The shipped reference output (`Doc/exampleOutput.pdf`) does not come from the shipped
`book_test` input. The fault is in the claim's reference, not in a verdict of "not reproduced". Details are in
`note-to-scout.md`.

## Claim and values

- Claim: final master objective, `book_test` example, the printed `#### Master objective value` line of the last phase II iteration.
- Paper (shipped log) value: -36.666667 (tol_abs 1e-5).
- Our value: not recorded as the claim value. The run gives 63.578947 in both passes (evidence only).

## What was run

- Source: netlib TOMS 928.zip, sha256 `703ed2c2fd8c665b7e1552727cbfaf5f77dcaaac440b5ba6189622e7639b4dca`, unzipped in the sandbox (`evidence/fetch.log`).
- Toolchain: gcc 13.3.0 (Ubuntu 24.04), GNU make, glibc pthreads. The bundled GLPK 4.44 is built from the archive.
- Original attempt (G1): the tree as shipped does not configure (`evidence/original-build.txt`, `evidence/original-build-tail.txt`): `configure` cannot find `src/Makefile.in`, because the archive ships `C/Src/src/` and the build expects `C/src/`.
- Patched build (basis `patched`): `impl/build-rios.sh pat`, with no source file edited. Four changes, all build-layout or flags:
  1. `ln -s Src/src src` in `C/`.
  2. `CPPFLAGS=-I<C dir>`, so `src/*.c` finds `config.h` in `C/`.
  3. `CFLAGS=-fcommon`. `dw.h` defines globals without `extern`, so the GCC 10+ default `-fno-common` fails the link.
  4. The libtool wrapper (`../libtool`) is not generated, so the final link is the same `gcc` command with the same objects and `-lm -lpthread`.
  The 115 objects build (`evidence/patched-build.txt`; `make` exits 2 at the libtool link, the link is then done by hand).
- Runs: `dwsolver -g book_test` in a fresh copy of `Examples/book_dantzig`, two passes (`evidence/run-pass1-full.log`, `evidence/run-pass2-full.log`). Both exit 0, and both give a final master objective of 6.357895e+01.

## Why blocked, not not-reproduced

- The shipped reference (`evidence/shipped-exampleOutput.txt`, sha256 `a99087ca...f3c8`) starts with `The master currently has 3 rows and 1 columns.`
- The shipped input (`evidence/input-book_test-and-master.txt`) starts with `The master currently has 5 rows and 2 columns.` (`evidence/run-pass1-full.log`).
- The example README says the subproblem bounds (`b1..b6 <= 65`) were added after the original release. The shipped log may predate them. This is a hypothesis; I have not tested it, because testing it means editing the input.
- A `not-reproduced` verdict would compare a value to a log of a different problem. So the verdict is `blocked`, and the cause is in the claim (`note-to-scout.md`).

## What would change this

- If the scout revises the claim to a reference the authors shipped for the current input, or withdraws it, the rerun can record a verdict against the new claim.
- If the authors' log can be shown to come from this input under a different configuration (for example the pre-bounds version), that goes in the note.

## Recipe

`recipe.sh` rebuilds from a clean scratch directory: fetch and sha check, original attempt, patched build, two passes, and the `VALUE final_master_objective` lines. It was run end to end in this wake (`evidence/recipe-run.log`), and both passes gave 6.357895e+01.

## Gates

- G1: original attempt logged (`failed`, configure error). Basis `patched` is allowed for `failed`.
- G2: not evaluated, because the verdict is `blocked`. The build-only manifest proof was not made (`patch.kind` is not `build-only`). This should be done only if the claim is revised and the result becomes a value.
- G3: recipe present. Not replayed (blocked).
- G0b: shipped reference text kept with its hash in `evidence/shipped-exampleOutput.txt`.
