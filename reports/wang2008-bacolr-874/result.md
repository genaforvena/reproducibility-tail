# wang2008-bacolr-874: reproduced (basis original)

Paper: Wang, Keast, Muir, "Algorithm 874: BACOLR, spatial and temporal error control software for PDEs based on high
order adaptive collocation", TOMS 34(3), May 2008, Article 15. Code: netlib TOMS 874.zip (Fortran 77).

## Claim

UOUT(XOUT = 0.91) at TOUT = 1.0, KCOL = 2, NINT = 42, as printed by the archive's own driver1.f in the shipped reference
output res1: **0.6602**. Absolute tolerance 1e-3, fixed in the queue entry before the run.

## Result

| value | shipped reference (res1) | ours, pass 1 (default flags) | ours, pass 2 (-O2) | difference |
|---|---|---|---|---|
| UOUT(XOUT=0.91), TOUT=1.0 | 0.6602 | 0.6602 | 0.6602 | 0 (tolerance 1e-3) |

Verdict: **reproduced**. Basis: **original**. The whole printed output of driver1 is byte-identical to the shipped res1
in both passes (`cmp`), so every printed value in the file matches, not only the claimed one.

## Why the basis is `original`

The archive ships no Makefile and no build line. The sources the driver needs (driver1.f, Src/src.f, Src/blas.f) were
compiled together as shipped, with gfortran's default flags and no edit to any file, and the program was run. It built
and ran (`evidence/original-attempt.log`: build_exit=0, run_exit=0). No patch, no build fix, no stub. The compile line
is the plain one, which is the only route the archive points to, so this basis is `original` and not `patched`.

## Caveats

- The shipped reference is the authors' printed output, four significant digits. It shows the code still does what the
  authors saw. It is not a number from the paper's text (the TOMS article was not read here).
- The compiler is gfortran from conda-forge (gcc 16.2.0), not a 2008 compiler. The match shows the bit-rot question
  for this example, not behaviour on other compilers.
- The claim is for one printed value of one example. It does not test the other four output blocks against the paper.

## Commands

From `reports/wang2008-bacolr-874/recipe.sh`. Every step runs in `tools/sandbox.sh`; the only network steps are the fetch
of 874.zip (sha256 checked) and the micromamba gfortran install, both with `--fetch`.

- compile (pass 1): `gfortran -o driver1 driver1.f ../Src/src.f ../Src/blas.f` in `Drivers/`, then `./driver1`
- pass 2: `gfortran -O2 -o driver1 driver1.f ../Src/src.f ../Src/blas.f` in a clean copy, then `./driver1`
- value: the first `0.9100E+00` row after the `TOUT = 0.10E+01` header, column 2

## Pins

- archive: netlib 874.zip, sha256 `92131b07424008c41ecac9dd667412c84dd604e79cf8d58841df03db26acc58b`
- reference res1: sha256 `b4b1edb5af482ef115a810ead6f94246cc0a596c2e4d67b2b0cc382684dacc2c`
- compiler: GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, via micromamba `gfortran_linux-64` latest at fetch time

## Evidence

- `evidence/original-attempt.log`: build and run as shipped (pass 1)
- `evidence/pass1-output.txt`, `evidence/pass2-output.txt`: the two runs' output (identical to res1)
- `evidence/pass2-run.log`: the -O2 build and run
- `evidence/pass1-value.txt`, `evidence/pass2-value.txt`: the extracted value, 0.6602E+00 in both
- `evidence/reference/res1`: the shipped reference output, unedited
- `evidence/recipe-run.log`: the full recipe run that produced the VALUE lines

## Replay

G5 is not yet satisfied: no clean replay exists. The `replay-due` duty will list this result once it is due.
