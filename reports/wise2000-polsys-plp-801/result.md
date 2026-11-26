# wise2000-polsys-plp-801: reproduced (basis patched, build-only toolchain change)

Paper: Wise, Sommese, Watson, "Algorithm 801: POLSYS_PLP", TOMS 26(1), March 2000. Code: netlib TOMS 801.gz (Fortran 90).

## Claim

Re X(2) of the first INPUT.DAT problem (TWO QUADRICS, real finite solution, TRACKTOL 1e-4, FINALTOL 1e-14, seed 32749),
as printed in the archive's own OUTPUT.DAT: **-0.788344824094120**. Absolute tolerance 1e-6, fixed in the queue entry.

## Result

| value | paper (shipped OUTPUT.DAT) | ours, pass 1 (gfortran 9.5 -O0) | ours, pass 2 (gfortran 9.5 -O2) | difference |
|---|---|---|---|---|
| Re X(2), first real finite solution | -0.788344824094120 | -0.788344824094139 | -0.788344824094139 | 1.9e-14 (tolerance 1e-6) |

Verdict: **reproduced**. Basis: **patched**, build-only (a toolchain change, no source or flag change).

## Why the basis is `patched`

The README's build with the latest gfortran (13.x, conda-forge) does not run. `polsys_plp.f90` is rejected with
"Index variable 'iter' redefined at (1) in procedure 'root_plp' called from within DO loop at (2)": ITER is modified
inside ROOT_PLP while a caller's DO loop uses it. `-std=legacy` does not lift the error. The original attempt is
logged (`evidence/original-attempt.log`, `evidence/legacy-attempt.log`), so the original outcome is `failed`.

The same unedited sources compile and link with gfortran 9.5 (pinned, conda-forge) using the README's file forms
(free form for polsys_plp.f90, fixed form for lapack_plp.f, then main_template.f90 and the link). Three manifests prove
the build is build-only: `verify_sources record` gives kind `build-only`, nothing modified, removed or added in the
authors' files, and nothing added by the build tool.

Caveat: the verdict is for the code as shipped, built with gfortran 9.5. It is not a claim that the code runs unchanged
on gfortran 13. The fault is a Fortran standard violation that newer compilers reject. An older compiler accepting it
is the only environmental difference.

## Commands

From `reports/wise2000-polsys-plp-801/recipe.sh` (every step runs in `tools/sandbox.sh`; the only network step is the
fetch of 801.gz, sha256 checked):

- unpack: `sed -n '4,$p' 801.txt > shar.sh; sh shar.sh` (into `/work/pre/Fortran90/Dp`)
- build (pass 1): `gfortran-9.5 -O0 -c -ffree-form polsys_plp.f90`; `-ffixed-form -ffixed-line-length-none -c lapack_plp.f`;
  `-I../Src -c main_template.f90`; link `main_template main_template.o polsys_plp.o lapack_plp.o`
- run: `./main_template` in `Drivers/` (reads INPUT.DAT, writes OUTPUT.DAT)
- pass 2: the same with `-O2`, in a separate tree copied from the same unpacked sources

## Pins

- archive: netlib 801.gz, sha256 `ea179f8d264d8130755145cfe02f51a2d789ae7d6d3fde55bddbd725d9ff78ad`
- compiler: gfortran 9.5.0 (conda-forge gcc 9.5.0-19), pinned via micromamba `gfortran_linux-64=9`
- original attempt compiler: gfortran 13 (conda-forge latest at fetch time, 2026-11-26)
- sources: Fortran90/Dp/Src/polsys_plp.f90 and lapack_plp.f, Drivers/main_template.f90 (manifest in `evidence/manifest.*`)

## Evidence

- `evidence/original-attempt.log`: gfortran 13 build failure (the original attempt)
- `evidence/legacy-attempt.log`: `-std=legacy` with gfortran 13, same failure
- `evidence/build.log`: the pass-1 build (build_exit=0)
- `evidence/pass1-run.log`, `evidence/pass2-run.log`: the runs (run_exit=0)
- `evidence/pass1-OUTPUT.DAT`, `evidence/pass2-OUTPUT.DAT`: the runs' output; `evidence/reference/OUTPUT.DAT`: the shipped output, unedited
- `evidence/value-pass1.txt`, `evidence/value-pass2.txt`: the extracted X(2) values
- `evidence/manifest.pre`, `.mid`, `.post`: the build-only proof

## Gates

G1 pass (original attempt logged). G2 pass (build-only, exit 0). G3 pass (two passes, -O0 and -O2, same value).
G5 n/a until the replay is due. Grade B (the authors' code with a build fix), per the ledger rule.
