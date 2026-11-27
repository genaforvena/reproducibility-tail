# deboor1980-solveblok-546: reproduced (basis: original)

**Paper.** de Boor and Weiss, Algorithm 546, SOLVEBLOK: almost block diagonal linear systems (ACM TOMS 6, 1980, pp. 88-91). Artifact: netlib CALGO `546.gz` (sha256 `dec187cff28bdce0de6c53439e6562fbf9748a86e3a379a66296456b357bb524`). The article text was not read; the claim is the code's own reference constant.

**Claim (registered, not edited).** The `DETERMINANT` printed by the shipped test program for its fixed 11 by 11 test matrix, reference constant `2.418821899E6`, absolute tolerance `5.0`.

**Our value.** `2418822.8` (printed `0.24188228E+07`), identical in pass 1 (default optimisation) and pass 2 (`-O2`). Difference from the reference: 0.9, inside the tolerance of 5.0. The program's own `ERROR` line prints `0.75`, also inside tolerance.

**Verdict:** `reproduced`. **Basis:** `original`: the shipped source compiles with gfortran (warnings only, Fortran 2018 deleted-feature notices for shared DO labels) and runs as shipped. No file was patched.

**Command.** `reports/deboor1980-solveblok-546/recipe.sh`. It fetches the archive inside the sandbox (`tools/sandbox.sh --fetch`), installs gfortran from conda-forge with micromamba into `/work/env` if missing, and compiles and runs both passes inside `tools/sandbox.sh`.

**Pins.** Archive sha256 as above. Compiler: gfortran from conda-forge via micromamba (version in `evidence/fetch.log`).

**Evidence.** `evidence/fetch.log`, `evidence/pass1.log`, `evidence/pass2.log`, `evidence/recipe-run.log`.

**Replay (G5).** Pending. The replay-due duty will name it when due.
