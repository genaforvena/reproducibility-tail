# renka1999-cshep2d-790: result

**Paper:** Renka, R. J. (1999). Algorithm 790: CSHEP2D, Cubic Shepard method for bivariate interpolation of scattered
data. ACM TOMS 25(1), 70-73. Stack: Fortran 77. Field: numerics (scattered data interpolation).

**Claim (artifact-reference, registered 2026-11-26T20:16Z):** the Max Error for interpolation function 1, node set 1
(N=100, NI=33, NC=17, NW=30, NR=6), printed by CS2TST to `res1_2`, is 0.0451, as in the shipped reference output.
Absolute tolerance 5e-5 (half of the last printed unit).

## Verdict

- **Verdict:** reproduced
- **Basis:** patched (build-only)
- **Our value:** 0.0451 in both passes (exact match at the printed precision).

## Original attempt (G1)

The archive ships no build command. `driver1.f` compiled alone does not link: `undefined reference to testdt_` and
`tstfn1_`, which are in `src_792.f`. Log: `evidence/original-attempt.log`.

## Patch (build-only, G2)

The authors' `driver1.f`, `src_792.f` and `src.f` are compiled together, out of tree, with gfortran -O0:

    gfortran -O0 -o cs2tst /work/build/Drivers/Sp/driver1.f /work/build/Drivers/Sp/src_792.f /work/build/Src/Sp/src.f

Three manifests were taken (`evidence/manifest.{pre,mid,post}`). The record has `kind: build-only`, with nothing
modified, removed or added between pre and mid.

## Input and runs (G3)

The driver reads node set 1 from stdin: the first six lines of `data1` (KS=1, first function 1, last function 10,
NC=17, NW=30, NR=6). It writes `res1_2` to its working directory. Two clean passes both give function 1 Max Error
0.0451. Evidence: `evidence/run1-res1_2`, `evidence/run2-res1_2`; the shipped file is `evidence/reference/res1_2`,
copied unedited and hash-checked in `result.json`.

## Environment

- Archive: `netlib.org/toms/790.gz`, sha256 `ac71fab09b7dd3715c0b1bb79bc77d3d95bcfd46141935a2cd9e2df1837718ff`.
- Compiler: gfortran from conda-forge (installed in the sandbox scratch during fetch).
- Licence: the netlib TOMS code is under the ACM licence. The licence text is not recorded here.

## Reproduce

    bash reports/renka1999-cshep2d-790/recipe.sh

G5 replay has not been run yet (no `replayed` entries). The claim compares one value at four decimals, so this
confirms the printed bin, not the last digits.
