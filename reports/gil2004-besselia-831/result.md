# gil2004-besselia-831: Algorithm 831 (modified Bessel functions of imaginary order), TOMS 831, Fortran 77

**Claim (pre-registered, unchanged):** WKTEST's Wronskian check for the scaled functions (IFAC=2) prints a maximum
of 6.814548925149211E-13 over the driver's grid (X = 0.95 I, A = 0.9 J, I, J = 1..1000 step 10). Absolute tolerance 1e-13.

**Our value:** 6.8156591481738360E-13 on both passes. |ours - paper| = 1.1e-16, inside the tolerance.

**Verdict: `reproduced`. Basis: `original`.** The authors' sources compile as shipped (gfortran -O2, no edits, no flags
beyond -O2). Original attempt succeeded.

**Paper scale note (as the charter asks):** our maximum is below 1e-12, the paper's "close to 1e-12" scale for the
(0,1500) x [-1500,1500) range the grid lies in.

## What ran

- Fetch: `https://netlib.org/toms/831.gz`, sha256 `5d56edbb...` (matches the queue registration), unpacked as a shell
  archive inside the sandbox scratch. gfortran from conda-forge (micromamba) into the sandbox scratch.
- Original attempt (G1, succeeded): `gfortran -O2 -o run/wktest Drivers/wktest.f Src/src.f Src/airy.f Src/d1mach.f`,
  exit 0. Log: `evidence/original-attempt.log`.
- Two passes (G3): the original binary run in its build directory, and the same binary run in a clean directory.
  The driver writes its report to `TESTF.DAT`. Both report files are identical (`evidence/run1-fort1.txt`,
  `evidence/run2-fort1.txt`).
- Reference: `evidence/reference/Res` (shipped, unedited; sha256 f07295e9...).

## Caveat on the rest of the output

Several entries of the driver's earlier per-point error table differ from the shipped `Res`, some by up to about 1e-12
absolute (for example X=50, A=550, first column: 0.399680289D-14 shipped vs 0.152100554D-12 ours). They are not the
registered claim, so they are recorded here and not judged. The maximum is the claim.

## Command

`reports/gil2004-besselia-831/recipe.sh`.
