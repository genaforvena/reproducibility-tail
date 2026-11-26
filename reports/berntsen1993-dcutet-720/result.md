# berntsen1993-dcutet-720: reproduced (basis: patched, build-only)

Paper: Berntsen, Cools and Espelid, "Algorithm 720: an adaptive cubature over a collection of 3-dimensional simplices (DCUTET)", ACM TOMS 19(3), 1993.
Archive: netlib.org/toms/720.gz, sha256 dc7f045565f861b4561f76b55cc49596e435349847cebdc0e6e5de5230025deb (checked).

## Claim

The shipped sample output of `PROGRAM DTEST1` (archive lines 1317-1321, "Output produced on a SUN 3/50"):
RESULT = 0.22779999698986, the integral of exp(x*x+y*y+z*z) over the reference tetrahedron, EPSREL 1e-5,
EPSABS 0, MAXPTS 1000. Absolute tolerance 1e-5 (registered; not changed here). The paper's text was not read.

## Verdict

**reproduced**, basis **patched** (build-only, with one judgment call below).

- Pass 1 (gfortran 13 from conda-forge, -O0): RESULT = 0.22779999698985759, ERROR 1.975e-6, NEVAL 43, IFAIL 0.
- Pass 2 (clean copy, -O2): RESULT = 0.22779999698985759.
- Difference from the shipped value: about 4e-15, far inside 1e-5.

## Original attempt (G1)

The shipped `720.shar` is one Fortran file, not a shell archive, so the queue note's "extract with sh" does not
apply. Its first 71 lines are a comment block followed by an unprefixed Makefile fragment (`dtest1: dtest1.o ...`,
`r1mach.o: r1mach.f`). Compiling the file as shipped with gfortran fails: 25 errors, "Non-numeric character in
statement label". Log: `evidence/original-attempt.log`.

## What was changed

- **Unpack** (before the pre manifest): the Fortran lines were split by line ranges into `dcutet.f` (from D1MACH, line 72,
  through the double-precision code) and `dtest1.f` (DTEST1 and F, lines 1867-1907). No Fortran line was edited.
- **Judgment call:** the 71 header lines (comment block and Makefile fragment) are left out. This is treated as
  unpacking, not as a patch. If a reviewer reads it as a patch, the record stays build-only for the build but the
  G2 paper check would be needed for the header removal.
- **Build:** `gfortran -O0 -o dtest1 dtest1.f dcutet.f`, no flag or code change.

The three manifests (pre, mid, post; 2 files each) are identical, so `verify_sources.py record` labels the build
build-only (modified 0, removed 0, added 0).

## Exact command

    bash reports/berntsen1993-dcutet-720/recipe.sh

The build and run happen inside `tools/sandbox.sh`; gfortran is installed in the sandbox scratch from conda-forge
(`gfortran_linux-64`) during the fetch step.

## Evidence

- `evidence/recipe-run.log`: the full recipe run.
- `evidence/original-attempt.log`: the failed compile of the shipped file.
- `evidence/unpack.log`: the line counts of the split units.
- `evidence/pass1-build.log`, `evidence/pass1-run.log`, `evidence/pass1-output.txt`, `evidence/pass1-result.txt`.
- `evidence/pass2-run.log`, `evidence/pass2-output.txt`, `evidence/pass2-result.txt`.
- `evidence/reference/sun3-50-output.txt`: the shipped sample output block, copied unedited.
- `evidence/manifest.{pre,mid,post}`: the build-only proof.

## Limits

- The claim is the shipped sample output, not a number read from the paper.
- The verdict depends on the unpacking judgment above.
- Only gfortran 13 was used; no other compiler was tried.

## Next

No replay yet (G5, `replay-due` duty, one result per wake, via `tools/replay.py`).
