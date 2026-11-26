# preusser1990-c1c2-684: reproduced (basis original)

Paper: A. Preusser, "Algorithm 684: C1 and C2 interpolation on triangles with quintic and nonic bivariate polynomials",
ACM TOMS 16 (1990) 253-257. Code: netlib TOMS 684.gz (single Fortran file, sha256 checked).

## Claim

PROGRAM DFC1C2 in the shipped driver prints, for Z(44,3) on the example's rectangular grid, a COMPUTED VALUE next to the
author's EXPECTED constant 3.035646151154. The registered tolerance is 1e-3 absolute, fixed in the queue entry before the run.

## Result

| value | expected (shipped constant) | ours, pass 1 (default flags) | ours, pass 2 (-O2) | difference |
|---|---|---|---|---|
| Z(44,3), C2 grid value | 3.035646151154 | 3.035507202148 | 3.035507202148 | 1.39e-4 (tolerance 1e-3) |

Verdict: **reproduced**. Basis: **original**.

## Why the basis is `original`

The archive is one file and ships no build line. It was compiled as shipped with gfortran (conda-forge 16.2.0) and default
flags, then run. It built and ran (`evidence/original-attempt.log`: build_exit=0, run_exit=0). The build prints only Fortran
2018 warnings about old-style DO labels. No edit to the source.

## Caveats

- The driver's second WRITE prints the C2-minus-C1 difference, because Z is overwritten before it. That is not the claimed
  quantity, so it is recorded but not claimed. The claim uses the first COMPUTED VALUE line only.
- The expected constant is the author's value printed in the shipped driver. The TOMS article was not read, so the paper
  text is not the source of the number.
- The author's comment notes that the default single-precision build can lose up to three digits. The observed gap of
  1.4e-4 is within that stated loss, and the tolerance was fixed beforehand to allow it.
- Only one value of one example is tested.

## Commands

From `reports/preusser1990-c1c2-684/recipe.sh`:
- fetch: `curl` of 684.gz, sha256 checked, gunzipped to `684.f` (inside `tools/sandbox.sh --fetch`)
- pass 1: `gfortran -o dfc1c2 684.f` then `./dfc1c2`
- pass 2: `gfortran -O2 -o dfc1c2 684.f` then `./dfc1c2`, in a clean directory

## Pins

- archive: netlib 684.gz, sha256 `d7370718ce36c41ae718fe3061cad733f664427cf78736abb5a0e20e3171dbe3`
- compiler: GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, via micromamba `gfortran_linux-64` at fetch time

## Evidence

- `evidence/original-attempt.log`: build and run as shipped (pass 1)
- `evidence/pass1-output.txt`, `evidence/pass2-output.txt`: both runs' output
- `evidence/pass2-run.log`: the -O2 build and run
- `evidence/recipe-run.log`: the full recipe run that produced the VALUE lines

## Replay

Not yet replayed. G5 is `na` until the replay-due duty asks for it.
