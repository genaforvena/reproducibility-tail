# akima1996-rgbi3p-760: Algorithm 760 (Akima 1996), RGBI3P

**Verdict: reproduced.** Basis: `original`. Scope: the shipped RGBI3P check value only, a shipped-reference match (artifact-reference), not a number printed in the paper.

- **Claim (registered, unchanged):** ZI(XI = 3.50, YI = 5.00) = 1.70, tolerance abs 0.01, from the RGBI3P "Calculated ZI Values" block of the shipped RES.
- **Our value:** 1.70 in both passes (`evidence/run-pass1.txt`, `evidence/run-pass2.txt`).
- **Original attempt (G1):** the shipped `driver.f` and `src.f`, unmodified, compiled with plain gfortran (default flags) and ran to completion (`evidence/original-attempt-build.log`, build_exit=0, run_exit=0). The archive ships no Makefile or build instructions, so the compile line is the only build step; no source was edited.
- **Output file:** the driver reopens unit 6 as `WFRG3P`, so the tables are written to that file, not to stdout. The recipe reads `WFRG3P`.
- **Parser check:** the value is row YI = 5.00 of the first RGBI3P block, and the header field at XI = 3.50 is checked before the value is printed. The RGSF3P block shows the same 1.70 but is not the claim.
- **Command:** `reports/akima1996-rgbi3p-760/recipe.sh` (fetch with sha256 check, unpack with the shared awk extractor, build, two runs in fresh directories).
- **Environment pins:** GNU Fortran 16.2.0 (conda-forge gcc 16.2.0-7) via micromamba in the sandbox; archive `netlib.org/toms/760.gz` sha256 `3f9058c03127be9d25940886425eb7fb5518356143078c2cb2c2fef32239b018`; shipped RES sha256 `37e58bd57e42efd12b1f56bd51a79d43322cf6bc80501f4f88777a3bbed09839`.
- **Queue:** the scout's entry had no archive sha256; rerun registered the fetched bytes in commit 8de001e (provenance only). Claim, paper value and tolerance are unchanged.
- **Gates:** G1 pass (original attempt succeeded). G2 not applicable (no patch). G3 pass (two passes agree). G5 not yet run: the clean replay is due and is not claimed here.
- **Limits:** the compile uses gfortran's default flags because the archive gives no build instructions; a different compiler or optimisation level could differ. Only one claimed value.
- **Evidence:** `reports/akima1996-rgbi3p-760/evidence/`. Scratch deleted after the record.
