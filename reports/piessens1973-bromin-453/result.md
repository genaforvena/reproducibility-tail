# piessens1973-bromin-453: CACM Algorithm 453 (BROMIN), reproduced

**Verdict: reproduced**, basis **original** (the authors' code, unedited, ran as documented).

## Claim
This is an artifact-reference claim, registered before any run (`queue/piessens1973-bromin-453.json`). The shipped
driver `TEST01` at N = 6, S = 0.00000 prints 12 numbers (XR, XI, WR, WI for three abscissas) in the file
`Fortran/Sp/Drivers/res` inside `453.gz`. Tolerance: absolute 1e-3, fixed before the run.

The paper's own table was not located (the article is paywalled), so this checks the shipped code against its
shipped output. It does not check against a value published in the paper.

## Result
| value | registered (res) | ours (gfortran -O0) | ours (gfortran -O2) |
|---|---|---|---|
| row 1 XR, XI, WR, WI | 6.48253, 1.49931, -27.8412, 315.065 | identical | identical |
| row 2 XR, XI, WR, WI | 5.46926, 4.51993, 37.157, -124.634 | identical | identical |
| row 3 XR, XI, WR, WI | 3.04821, 7.65179, -9.31577, 13.1079 | identical | identical |

The full stdout of both runs is byte-identical to the shipped `res` (`evidence/run-O0.txt`, `evidence/run-O2.txt`,
`evidence/original-attempt.log`). Maximum difference is 0 against a tolerance of 1e-3.

## Method
- Archive: `netlib.org/toms/453.gz`, sha256 `57563056...21b9f7` (checked). It is a plain shell archive. The
  authors' own `sh` run in the sandbox unpacks `Fortran/Sp/{Drivers,Src}`. The files were not edited.
- Compiler: gfortran from conda-forge, installed by micromamba in the sandbox. The gfortran warnings are only
  Fortran 2018 "deleted feature" notes for arithmetic IF.
- Run: `driver.f` and `src.f` compiled as shipped at -O0 (and -O2 as a cross-check), then run. Exit 0 both times.
- Sandbox: `tools/sandbox.sh` for every step. Fetch used `--fetch` only.

## Gates
- G1: original run succeeded, so basis `original` fits.
- G2: not applicable (no patch, no reimplementation).
- G3: the recipe runs from a clean scratch directory (this wake, then the G5 replay).
- G5: clean replay from nothing agrees (`evidence/replay-2026-11-27T052836Z.log`).

## Reproduce
`reports/piessens1973-bromin-453/recipe.sh`. It rebuilds from the archive and prints the 12 `VALUE` lines.

## Pins
gfortran from conda-forge through micromamba (latest at install time; the version string was not captured in this wake),
Linux x86-64, `gfortran -O0` and `gfortran -O2`, default Fortran 77 fixed-form.

## Limits
- Only the first TEST01 block (N = 6, S = 0) is claimed. The other N and S blocks were not compared.
- The claim checks the shipped output. Whether the paper's method matches the code was not checked, because the
  article was not read.
