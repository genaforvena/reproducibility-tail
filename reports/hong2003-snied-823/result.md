# hong2003-snied-823: TOMS 823 (Snied), EI at I = 4096

**Verdict: blocked.** Our run gives 0.99994610736637701 against the shipped 0.9999468969847435 (tol 1e-9), a
reproducible gap of about 790 tolerances. The cause is not isolated, so this is not recorded as
`not-reproduced (cause: ...)`. Basis: `original` (no source file edited; see the build caveat below).

**What is missing to unblock:** the code version or RNG/state that produced the shipped `Drivers/res1`. Until a
cause is shown, the numbers stay here and the ledger grade is `-`.

**Diagnosis this wake** (`evidence/diagnosis-2026-11-27.txt`):
- Toolchain exonerated: the sibling variant Sniedx, same compiler and recipe, reproduces its shipped `res1` exactly
  (0.99998999508936381 vs 0.9999899950893638).
- Flag choice exonerated: IFLAG 0, 2 and 3 give 0.99913877598010004, 0.99959330656565726, 0.99927082907549902; none is the shipped value.
- `Drivers/data1` exonerated: no source or driver reads it.
- Open lead: a whole-program `-fdefault-real-8` build moves the value to 0.999945206205708367754958574430412810, so
  REAL precision matters somewhere on this path. Split real-size builds break an interface, so the dependence is not yet localised.
- Not yet tested: whether the shipped `res1` came from a different `src.f`/`extra.f` version or RNG seed table. Testing a seed table
  to match the number would be tuning, so it is not used as a verdict.

## Claim

- Quantity: `EI = SUM/I` at I = 4096 printed by TSNIED (Snied, IFLAG = 1 Owen-type scrambling, DIMEN = 2).
- Paper value (shipped reference, `Drivers/res1`, artifact-reference): **0.9999468969847435**.
- Tolerance (registered in the queue entry, not edited): absolute **1e-9**.
- Our value (pass 1, gfortran 16.2 -O2): **0.99994610736637701**.
- Difference: ours minus shipped = -7.9e-7, about 790 times the tolerance.

## Passes (all four agree on the claimed value; this is the reproducible observation the blocked verdict rests on)

| pass | build | value at I = 4096 |
|---|---|---|
| 1 | gfortran 16.2 -O2 (the original attempt) | 0.99994610736637701 |
| 2 | gfortran 16.2 -O2, clean rebuild (repeat) | 0.99994610736637701 |
| 3 | gfortran 16.2 -O0 | 0.99994610736637701 |
| 4 | gfortran 13 -O2 (different environment) | 0.99994610736637701 |

Passes 1 and 4 differ in toolchain and passes 1 and 3 in optimisation level; the timing line differs
only in the elapsed time. The verdict is confirmed by the second environment (pass 4).

## Build caveat

`Drivers/Makefile` includes a `makefile.inc` that the archive does not ship, so the authors' documented
build cannot run as shipped. The compile lines in `recipe.sh` are ours (`gfortran <opt>` on `Src/src.f`,
`Src/extra.f`, `Drivers/driver.f`, then linked). No source file is edited. This is the same situation as
`renka1997-ssrfpack-773`, which also recorded basis `original` with compile lines of its own.

## Command and pins

- `reports/hong2003-snied-823/recipe.sh` (fetch, four builds, four runs, `VALUE` line).
- Archive: `https://netlib.org/toms/823.zip`, sha256 `de5eaa5face30d4590a8679a94f0b830229771087afbdd4bdc1b75d11b3f9785` (checked).
- Toolchains: conda-forge gfortran 16.2 (env16) and gfortran 13 (env13), via micromamba inside the sandbox.
  Exact build strings are in the sandbox logs, not pinned further here.

## Evidence

- `reports/hong2003-snied-823/evidence/pass{1..4}-build.log`, `pass{1..4}-run.log`, `pass{1..4}-stdout.txt`.
- `reports/hong2003-snied-823/evidence/probe-*.txt` (flag probes), `evidence/diagnosis-2026-11-27.txt` (this wake).
- `reports/hong2003-snied-823/evidence/recipe-run.log`.
- The shipped output is `Drivers/res1` inside the archive (not copied into evidence).
