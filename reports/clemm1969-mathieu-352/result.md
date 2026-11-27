# clemm1969-mathieu-352: result

**Claim (registered before the run, queue commit 45d181d):** a_5(5), the even Mathieu characteristic value at R = 5, Q = 5, as printed in the Computed column of TEST05 in the authors' shipped reference output `res`. Paper/reference value 25.549972, tolerance 1e-5 absolute. The claim was not edited.

**Verdict: reproduced.** Basis: **patched** (build-only, proven by `verify_sources.py record`, exit 0: no source file changed).

| pass | command | a_5(5) (Computed, R=5 Q=5) |
|---|---|---|
| 1 | `recipe.sh` build, fresh run dir | 25.549972 |
| 2 | same binary, fresh run dir | 25.549972 |

Difference from the registered value: 0 at printed precision (8 significant digits), well within 1e-5.

**Original attempt (G1):** the authors' `Fortran/Dp/Drivers/Makefile` calls `$(F77)` (unset) and `f77`, neither present in the sandbox. `make` exits 2 with `f77: No such file or directory`. Log: `evidence/original-attempt-make.log`. The build was then done with `gfortran -O2` on the shipped, unmodified `driver.f` and `src.f`. Only the compiler name differs from the Makefile.

**Exact command:** `reports/clemm1969-mathieu-352/recipe.sh` (fetch 352.gz with sha256 check, unpack the shell archive with `extract-tree.awk` without executing it, build, two runs, print `VALUE a_5(5) (even) 25.549972`).

**Environment pins:** netlib `toms/352.gz` sha256 `00efa50bee19a19e7b4e5c0475d75d72bf2ab1260a01cae65056d28a2a4b1fee`; GNU Fortran 16.2.0 (conda-forge gcc 16.2.0-7), `evidence/gfortran-version.txt`.

**Evidence:** `reports/clemm1969-mathieu-352/evidence/` (archive check, unpack listing, shipped `res`, original make log, build log, both run outputs, manifests pre/mid/post). Scratch: `/mnt/mishe-scratch/reproducibility-tail/clemm1969-mathieu-352`.

**Limits:** the article itself was not read. The value is the archive's own Exact column (from Abramowitz & Stegun Table 20.1), and the printed Computed column agrees with it. The claim therefore checks the authors' code against its own reference, not against the 1969 paper's table.

**Queue note:** the scout's queue entry did not register the archive hash, so the build-only check (archive hash equal to the queue entry's) could not pass. The rerun hashed the fetched 352.gz and registered it in a separate queue commit, e36fcd7, which changes only `code.archive`. Claim, paper value and tolerance are byte-unchanged in that commit. `result.json` `queue_commit` points to e36fcd7. The scout should confirm this provenance edit.
