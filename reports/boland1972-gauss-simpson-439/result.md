# boland1972-gauss-simpson-439: result

**Paper:** Algorithm 439, product-type three-point Gauss-Legendre Simpson integration (W. R. Boland, Communications of the ACM 15(12), 1972). Fortran code from netlib CALGO 439.gz.

**Claim (registered by scout, not edited):** the shipped reference output `Fortran/Dp/Drivers/res`, block TEST01 (integral of F(X)·G(X) from -1 to 1, F = 1, G = 1/(1+x²)), row N = 10, VINT = 2.65082. Tolerance 1e-5 absolute.

**Verdict:** `reproduced`, basis `patched` (build-only).

**Our value:** TEST01 N = 10 VINT = 2.65082. Difference from the claim: 0 at 5 decimals. Two passes from a fresh unpack gave byte-identical output (`evidence/Res`, `evidence/Res.pass1`). The only difference from the shipped `res` file is one trailing blank line after the table.

## What was patched, and why it is build-only

1. **Original attempt (G1), failed.** The archive's Makefile, run unchanged, stops with `make: f77: No such file or directory`. The base sandbox has no Fortran compiler (`evidence/original-attempt.log`).
2. **Toolchain.** gfortran 16.2.0 (conda-forge, micromamba) is installed in the sandbox during the fetch step (`evidence/fetch.log`, `evidence/env-pins.txt`).
3. **Missing source path.** The Drivers Makefile compiles `src.f` from the Drivers directory, but the archive ships it in `Src/`. Two changes fix this, neither of which edits an archive file:
   - `VPATH=../Src` lets make find the prerequisite.
   - `impl/f77-shim.sh`, placed on the build PATH as `f77`, maps the compiler's single argument `src.f` to `../Src/src.f`.
4. **Link libraries.** The Makefile's link line has no library argument. `SRCLIBS='-L/work/env/lib -lgfortran -lm'` passes the gfortran runtime and libm through the Makefile's own variable.

The manifests show this: `pre`, `mid` and `post` hash the same three source files (Makefile, driver.f, src.f), with no modified, added or removed file (`evidence/manifest.*`). `verify_sources.py record` returns `build-only`.

## Environment pins

- gfortran 16.2.0 (conda-forge), libgfortran5 16.2.0, gcc_linux-64 16.2.0.
- Archive: netlib 439.gz, sha256 `81cfd10dead980d26565450b9f98bac46566f3d9da7b70552086feb4fd314407` (matches the queue entry).
- Shipped reference `res`: sha256 `023e7bbe564d3d79b8938650f8279516825e6f75eb53ab4b977f80ae1cae14d1`.

## Incident note (for the record)

An earlier wake left a 385-byte shell-script draft at the path of the conda gfortran driver. It exited 0 and wrote no object file, so the first compile attempts looked like success. The recipe now tests the compiler (writes and checks an object file) and links the conda gcc driver under the gfortran name only if that test fails. In this run the test passed (`gfortran_driver=ok` in `fetch.log`); the scratch copy was repaired by hand before the first recipe run.

## Command and evidence

- Rebuild and rerun: `reports/boland1972-gauss-simpson-439/recipe.sh` (the sandbox does the fetch, build and run).
- Evidence: `reports/boland1972-gauss-simpson-439/evidence/` (`fetch.log`, `original-attempt.log`, `build.log`, `driver-run.log`, `Res`, `res.shipped`, `manifest.pre|mid|post`, `recipe-run-pass1.log`, `recipe-run-pass2.log`).
