# monahan1984-hodges-lehmann-616: result (reproduced, basis patched)

**Claim (registered 2026-11-26T19:36Z, artifact-reference):** the Hodges-Lehmann estimate that TOMS 616's driver prints
for N=9, repetition 3, first test of HLQEST (random input, RANG seed 434977), shipped as `0.545388` in the archive's
printed run output (616.gz lines 366-441). Absolute tolerance 1e-6, fixed before any run. The claim and tolerance were not edited.

**Measured (ours):** `0.545388` in both passes (fresh compile and run, gfortran -O0, separate clean directories).
Difference from shipped: below 1e-6 (the shipped value has six decimals). Measured value (both passes, from
`evidence/p1-value.txt` and `evidence/p2-value.txt`) is `ours` in `result.json`, the printed six-decimal value.

**Verdict:** `reproduced`, basis `patched`. G2 (fidelity) passed: scout confirmed (msg #77) that the line-range cut
below does not change the algorithm. The archive's `TAPE1=INPUT` and `DATA INUN /1/` route the only reads
(lines 61, 65) to unit 1, and nothing in lines 1-354 refers to the tail.

**Basis:** `patched`.

**Original attempt (G1, failed, kept):** `gfortran` on the whole archive file as shipped. `compile_exit=1`:
lines 355-441 are stdin data and printed output, not Fortran. Log: `evidence/original-attempt.log`.

**Patch (basis patched):** the source is archive lines 1-354, unedited (`sed -n 1,354p`). The stdin is lines
355-365 (N=6..7 tie data and the N=0 stop), supplied as unit 1 (`fort.1`, the file gfortran opens for TAPE1=INPUT).
No line of the source was edited; the only change is removing the non-Fortran tail of the file.

**Exact command:** `bash reports/monahan1984-hodges-lehmann-616/recipe.sh` (the recipe fetches the archive with
sha256 check and gfortran from conda-forge into the sandbox scratch, then runs each step through `tools/sandbox.sh`).

**Environment pins:** netlib TOMS 616.gz sha256 `d81e3935449161431649327e1fa3c729db01af4475ebf1c7e9f3e881d1649c99`;
gfortran from conda-forge (`gfortran_linux-64`, micromamba latest) in the sandbox scratch; gfortran -O0 (warnings only:
Fortran 2018 deleted arithmetic IF, one array-bounds warning at line 154, which is the authors' own code).

**Evidence:** `evidence/original-attempt.log`, `evidence/p1-output.txt`, `evidence/p2-output.txt` (full printed
output of each pass, fort.3), `evidence/p1-compile.txt`, `evidence/p2-compile.txt`, `evidence/p1-value.txt`,
`evidence/p2-value.txt`, `evidence/reference/printed-output.txt` (shipped lines 366-441, unedited).

**Full-output compare (done):** all 64 printed rows (both passes) compared with the shipped lines 366-441 by N, repetition and sort/HLQEST type: every row matches to better than 1e-6 (pass 1 and pass 2 identical).


**What would change the verdict:** the scout's G2 reading says the cut is not an algorithm change, then the verdict
becomes `reproduced` with basis `patched` and G2 `pass`. If the full output differs past 1e-6 on any line, that is a
finding to diagnose, not a pass.
