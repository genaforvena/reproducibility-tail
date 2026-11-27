# gil2014-marcumq-939: result

**Paper:** Algorithm 939, computation of the Marcum Q-function (A. Gil, J. Segura, N. M. Temme), ACM TOMS 40(3), 2014. Fortran 90 code from netlib CALGO 939.zip.

**Claim (registered by scout, not edited):** the reference DATA array `q`, element 5, in the shipped `Fortran90/Drivers/testmarq.f90`: Q_8(13, 15) = 0.8516869957363. Tolerance 1e-10 absolute.

**Verdict:** `reproduced`, basis `patched` (build-only).

**Our value:** `VALUE Q_mu8_x13_y15 8.5168699573630136E-01` (`evidence/valq8.out`). Difference from the claim: 1.3e-15, well inside 1e-10. Two passes from a fresh unpack gave the same value (`evidence/recipe-run-pass1.log`, `evidence/recipe-run-pass2.log`).

## Why the basis is patched

1. **Original attempt (G1), failed.** The archive's `Doc/Makefile`, run unchanged in a copy, stops at `No rule to make target 'cons.f90'`: the Makefile expects its sources beside it, but the archive ships them in `Fortran90/Src` and `Fortran90/Drivers`. g95, the Makefile's default compiler, is also absent from the sandbox (`command -v g95` prints nothing). Log: `evidence/original-attempt.log`.
2. **Build fix (no archive file edited).** The same Makefile is run with `FC` set to the sandbox's gfortran 16.2.0 (conda-forge, micromamba during `--fetch`) and `VPATH` pointing at the archive's `Src` and `Drivers`. Objects go into a separate build directory. The manifests `pre`, `mid` and `post` hash the same five source files, with no change; `verify_sources.py record` returns `build-only` (`evidence/manifest.*`).
3. **Value.** The shipped driver prints only relative errors, not the Q value. `impl/valq8.f90` is new code written for this rerun. It calls the authors' `marcum(8, 13, 15)` unchanged and prints the value. It is compiled against the authors' modules, so the basis is `patched`.

## Archive's own test, for context

`testmarq` (the authors' driver, built as above) writes `testQP.dat`. Its relative errors are all at or below about 1e-12 (largest: 9.3e-13 at mu = 1000). The maximum recurrence check is 3.6e-13 (shipped: 3.1e-13). Those differences are rounding-level and are shown, not judged. Evidence: `evidence/testQP.dat`, `evidence/outputQP.shipped`.

## Environment pins

- gfortran 16.2.0, libgfortran5 16.2.0, gcc_linux-64 16.2.0, gfortran_impl_linux-64 16.2.0 (conda-forge): `evidence/env-pins.txt`.
- Archive: netlib 939.zip, sha256 `dbf77461a9c02c603f8eb2bfcfcef6e3d1cfbb7d628b54b18f79c4a7e62af9e4` (matches the queue entry).
- Shipped driver source `testmarq.f90`: sha256 `21b863f38dc6e170c5a575c4cf90a6eb960f1c61667ebb84e4adcb3b51714738`.

## Incident note

The first run built successfully but the record step refused the patch as `source` (record_exit 2). The cause: the build commands were held in shell variables, not literal text, so the recipe's build region did not contain them. The recipe now writes the commands literally, and the record step returns `build-only` on both passes. The failed run's log is kept at `evidence/recipe-run.log`.
