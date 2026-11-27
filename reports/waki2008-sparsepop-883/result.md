# waki2008-sparsepop-883: result

**Verdict: reproduced. Basis: patched** (dependency and environment fixes; the authors' SparsePOP 2.00 code is unmodified).

## Claim (registered in queue/waki2008-sparsepop-883.json, not edited)

- POP.objValue printed for `example1.gms`, relaxOrder 3, SeDuMi eps 1e-9 (Doc/UserManual/sect3.tex).
- Paper value -7.9550951; tolerance 1e-6 absolute.

## Our value

| pass | POP.objValue | diff from paper | within tol |
|---|---|---|---|
| 1 (recipe.sh, clean) | -7.95509506 | +4e-9 | yes |
| 2 (recipe.sh, same run) | -7.95509506 | +4e-9 | yes |

The printed relative objective error is 8.3e-10 and SeDuMi reports numerr 0, pinf 0, dinf 0 (evidence/run1.log).

## Basis and original attempt

- The authors' archive (883.zip, sha256 2c05dee…, checked) was run as shipped first, under Octave 10.3 from conda-forge. It did not run as documented. Failures, in order: `ver` needed `pkg`, `findstr` removed in Octave 10, `strtok` and `common_size` not on the path, and the archive does not contain SeDuMi. Logs: evidence/attempts/.
- To run it, the following were changed. None is a change to the authors' SparsePOP files.
  - SeDuMi 1.3 master (GPL, GitHub, sha256 13ca1132…, checked) was built with its installer edited for this host: the computer-type string, the mkoctfile call, and the openblas include flag. A one-line `f77blas.h` shim gives `blasint` and `BLASFUNC`.
  - `pkg.m` returns an empty package list, so `ver()` finds no Symbolic Math Toolbox. `findstr.m` is the MATLAB function, which Octave 10 no longer has.
  - A driver (impl/run_sparsepop.m) adds the Octave m-directories and calls `sparsePOP("example1.gms", param)`.
- Because the failed original attempt is recorded and the run needed these changes, the basis is `patched`.

## Environment pins

- Octave 10.3.0 (conda-forge via micromamba, the `octave` package).
- gfortran is not used. SeDuMi MEX files built by host gcc through `CC=/usr/bin/gcc`.
- micromamba: the current `micro.mamba.pm` linux-64 latest build at run time.
- SeDuMi: master, GitHub archive, sha256 13ca113297c89d34eab132d45f92db68753fe92a8751452aa88262064033a119.

## Limitations

- The paper's own printed value is the manual's printout (the paper text was not checked). The claim is therefore an artifact-reference match, not a table value from the paper.
- The GMS driver is the archive's own `sparsePOP` path, not a reimplementation.

## Evidence

- `recipe.sh`: the canonical rebuild and rerun. It fetches, builds SeDuMi, and runs the driver twice.
- `evidence/recipe-run.log`: the clean recipe run, RC=0.
- `evidence/run1.log`, `evidence/run2.log`: the two driver passes.
- `evidence/sedumi-install.log`: the SeDuMi build log.
- `evidence/attempts/`: failed attempts, in order.
- `impl/`: the shims and driver.

## Command

`bash reports/waki2008-sparsepop-883/recipe.sh`
