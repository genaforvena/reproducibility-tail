# benson2008-dsdp5-875: reproduced (basis: patched, build-only)

Paper: Benson and Ye, "Algorithm 875: DSDP5, software for semidefinite programming", ACM TOMS 34(3), 2008.
Archive: netlib.org/toms/875.zip, sha256 43a19f4832245b4703dc1826a9786d21073a76e9c554e951aa2d3136ed78158f (checked).

## Claim

The shipped reference log `bin/output.theta` (archive member), last iteration of `theta graph1`: DD Objective
-3.00000012e+00. Compared as a magnitude, 3.00000012, absolute tolerance 1e-5 (registered; not changed here).
The paper's text was not read in this wake; the claim is the shipped reference output.

## Verdict

**reproduced**, basis **patched** (build-only).

- Pass 1 (verdict build, make.include at -O3): DD objective of iteration 4 = -3.00000012e+00, magnitude
  3.00000012, difference 0 against the registered value. The whole `theta graph1` log is identical to the
  shipped `output.theta` (`diff` reports no difference).
- Pass 2 (clean copy, `OPTFLAGS=-O0`): the same magnitude, 3.00000012.

## Original attempt (G1)

The documented route fails at link on this host (`make all`, make.include as shipped):

    /usr/bin/ld: cannot find -lg2c: No such file or directory

make.include's `LAPACKBLAS` lists `-lg2c`, an obsolete f2c runtime that this host does not have. The matlab
target also fails (exit 127, `mex` absent); it is not part of the claim. Log: `evidence/original-attempt.log`.

## What was changed

Only the build command, and no file. make.include is unedited; the library list is overridden on the make
command line (`LAPACKBLAS='-llapack -lblas -lm'`) and only the `dsdplibrary` and `example` targets are built.
Three manifests of the archive's 139 source and build-config files (pre, mid, post) are identical, so the
record is build-only (`verify_sources.py record`: modified 0, removed 0, added 0).

## Exact command

    bash reports/benson2008-dsdp5-875/recipe.sh

Build and run inside `tools/sandbox.sh`: `cd /work/build && DSDPROOT=/work/build make LAPACKBLAS='-llapack -lblas -lm' dsdplibrary example`, then `cd /work/build/bin && ./theta graph1`.

## Environment

- Sandbox: Ubuntu 24.04 host, gcc 13.3.0 (`/usr/bin/gcc`), GNU make, system BLAS and LAPACK (`/usr/lib/x86_64-linux-gnu/liblapack.so.3`, `libblas.so.3`).
- No compiler or library was installed; the fetch step only downloads and unpacks the archive.

## Evidence

- `evidence/recipe-run.log`: the full recipe run.
- `evidence/original-attempt.log`: the failed documented build.
- `evidence/pass1-build.log`, `evidence/pass1-run.log`, `evidence/pass1-output.txt`.
- `evidence/pass2-run.log`, `evidence/pass2-output.txt`.
- `evidence/reference/output.theta`: the shipped reference log, copied unedited.
- `evidence/manifest.{pre,mid,post}`: the build-only proof.

## Limits

- The claim is the shipped reference output, not a number printed in the paper's text.
- The verdict rests on the library-list override; a build with the original `-lg2c` cannot link here at all.
- Only this host's BLAS/LAPACK were used; the sign convention and print format are the authors' own.

## Next

No replay yet. The G5 replay (`replay-due` duty) is run later, one result per wake, through `tools/replay.py`.
