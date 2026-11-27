# damore2014-reliadiff-946: result

**Paper:** Algorithm 946, ReLIADiff, a C++ package for real Laplace transform inversion by algorithmic differentiation (Damore et al., 2014).

**Claim (registered by scout, not edited):** the DEMO2 default run gives `f_comp` at x = 5.00e+00 equal to `1.29653819e+00` in the shipped `output_demo2.txt`. Tolerance 2e-8 absolute.

## Verdict

- **Verdict:** `reproduced`
- **Basis:** `patched` (build-only). The authors' documented route does not run as written; see "Original attempt". The patch is to the build and runs, not to the source.
- **Our value:** `1.29653819e+00` (difference 0 against the paper value, tolerance 2e-8).

## Two passes (G3)

Both passes ran from a clean scratch directory through `recipe.sh`:

1. Pass 1: `VALUE RELIADIFF_FCOMP_X5 1.29653819e+00`
2. Pass 2: `VALUE RELIADIFF_FCOMP_X5 1.29653819e+00`

## Exact command

    reports/damore2014-reliadiff-946/recipe.sh

It runs inside `tools/sandbox.sh` (read-only root, scratch on the spare drive, no network after fetch). The sequence is: fetch the TOMS 946 archive, verify its sha256, run the original attempt in a copy, unpack, take `manifest.pre`, build, take `manifest.mid` and `manifest.post`, run the authors' `TEST_default.sh`, and print the `VALUE` line.

## Original attempt (G1)

The documented route is `make -f Makefile_gsl` (GSL 1.15 into `demos-Linux_g++/GSL`), then `make -f Makefile_gslloc` in `DEMO2-Function_To_Give`. The DEMO2 target calls the utility directory's plain `Makefile`, which still points GSL at `/usr/local`. Make stops with `No rule to make target '/usr/local/include/gsl/', needed by 'Util.o'`. The log is kept at `evidence/original-attempt.log`. The authors' GSL 1.15 build itself works (about 2m40s).

The patched route runs the authors' own Makefiles where they work (`Makefile_gsl`, `src`, `utility/Makefile_gslloc`), then the DEMO2 compile and link lines with GSL at `../GSL`, then the authors' `TEST_default.sh`.

## Build-only proof

`tools/verify_sources.py record` returns exit 0 with patch kind `build-only`:

- Source files compared: 39. Modified, removed or added by us: 0.
- Build-tool additions: 1977 files in the GSL build output, all in the build tree.
- The five build commands recorded are the literal command strings in `recipe.sh`'s build region.

No source file was changed, so the G2 paper check does not apply.

## Environment pins

- Archive: `netlib.org/toms/946.zip`, sha256 `23e42c6c0441575e12a1e4374747e3dab2c875ade6d2c6ffb58f4610cd67d55c`.
- GSL 1.15, from the archive's `gsl-1.15.tar.gz`, built as a shared library.
- `g++` from the sandbox image (flags as in the recipe).
- `gfortran` is not used.
- Run time needs `LD_LIBRARY_PATH=GSL/lib` so the loader finds the shared GSL. This is recorded in `recipe.sh`. It changes no binary.

## Differences from the shipped output (not claimed)

`evidence/output-diff.txt` compares our output with the shipped file:

- The elapsed-time lines differ (expected, timing only).
- The shipped file has a `WARNING` banner ("Calculated errors are just errors estimate, they are not errors bounds"). Our run's output does not show that banner.
- The numbers in the x = 5 row are identical.

The banner is text only and not part of the claim. It is recorded here so a reader is not surprised.

## Evidence

- `evidence/recipe-run.log`: pass 2 run log.
- `evidence/output_demo2.txt`: our output.
- `evidence/output_demo2-shipped.txt`: shipped reference (sha256 `b7a80b47...5ff64`).
- `evidence/output-diff.txt`: diff of the two.
- `evidence/original-attempt.log`: G1 failed attempt.
- `evidence/manifest.pre`, `manifest.mid`, `manifest.post`: build-only manifests.
- `evidence/fetch.log`: archive fetch.

## What would change the verdict

A different value on a further clean run, or a source-file change flagged by `verify_sources.py` on a rerun.
