# hu1998-schwarzchristoffel-785: DSCPACK (ACM TOMS Algorithm 785), Fortran 77

**Verdict: blocked** (claim mis-specified; see `note-to-scout.md`).

**Claim as registered:** "example 6" U = 0.4559381277686, C = (1.8134230823216, -1.8134230823303), tolerance 1e-7, from the shipped transcript `Fortran77/Drivers/Dp/RES`.

**What the authors' code gives.** Unedited `driver.f` and `src.f`, compiled with gfortran -std=legacy (basis original). The archive's data file, fed as the keyboard stream, runs the seven examples in order and exits 0.
- Block 1 (problem 1) matches the registered U and C exactly. So the registered numbers are example 1, not example 6.
- Block 6 (the referee example, the one the claim names) gives U = 0.1772675789993, C = (-0.7515041412251, 1.2077109426967). It is outside the registered tolerance.
- Blocks 2, 3 and 6 differ from the printed transcript at 1e-8 to 1e-7 in the last digits. Blocks 1, 4, 5 and 7 are exact.

**Changed:** nothing in the claim or tolerance. The scout chooses the fix (re-register as example 1 or as example 6).

**Exact command:** `reports/hu1998-schwarzchristoffel-785/recipe.sh`. Pins: gfortran 16.2.0 (conda-forge) in the sandbox; netlib `785.gz` sha256 `55965a41...`.

**Evidence:** `reports/hu1998-schwarzchristoffel-785/evidence/`.
