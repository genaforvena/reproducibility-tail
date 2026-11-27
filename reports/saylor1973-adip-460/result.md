# saylor1973-adip-460: reproduced (basis: original)

**Paper.** Saylor and Sebastian, Algorithm 460 (ADIP: optimum parameters for alternating direction implicit procedures), ACM TOMS 16(10), 1973. Artifact: netlib CALGO `460.gz` (sha256 `542ae8263c1d41ae98a2d100713e8dc62555d50ee88446d28c2b608002c8982d`). The article text was not read; the claim is the code's own printed output.

**Claim (registered, not edited).** The `DMU` printed by the shipped driver for `ITNS = 1`, reference value `0.0775958` (shipped `res` file: `0.775958E-01`), absolute tolerance `1e-7`.

**Our value.** `0.775958E-01` in pass 1 (default optimisation) and pass 2 (`-O2`), identical to the shipped `res` file line for line. Difference from the reference: 0 at print precision, inside the tolerance of 1e-7.

**Verdict:** `reproduced`. **Basis:** `original`. The authors' Fortran was compiled with gfortran and run as shipped. The archive's Makefile expects `src.f` in the driver directory, but the files ship in `Fortran/Dp/Src` and `Fortran/Dp/Drivers`. The recipe therefore runs one gfortran command on the archive's own two files. No file is edited or copied over.

**Command.** `reports/saylor1973-adip-460/recipe.sh`. It fetches the archive inside the sandbox (`tools/sandbox.sh --fetch`), installs gfortran from conda-forge with micromamba into `/work/env` if missing, and compiles and runs both passes inside `tools/sandbox.sh`.

**Pins.** Archive sha256 as above. Compiler: gfortran 16.2.0 (conda-forge gcc 16.2.0-7), from `evidence/fetch.log`.

**Evidence.** `evidence/fetch.log`, `evidence/pass1.log`, `evidence/pass2.log`, `evidence/recipe-run.log`, `evidence/res-shipped` (copy of the shipped reference output, sha256 `ef36f2e0…73bd`).

**Replay (G5).** Pending. The replay-due duty will name it when due.
