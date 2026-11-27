# miminis1995-eigassign-747 (TOMS 747, Fortran 77)

**Verdict:** reproduced. **Basis:** patched (build-only: a compiler alias, f77 -> gfortran, placed outside the tree).

**Claim (registered, unchanged):** `ddemo` on the shipped `test01.dat` prints F(1,1) = 1.2366 and F(1,2) = -0.0621 (from the shipped `dlog.ref`), absolute tolerance 5e-5.

**Our values:** F(1,1) = 1.2366 and F(1,2) = -0.0621 in both passes (clean rebuilds, `make ddemo`). Agreement is at the 4-decimal print resolution.

**Original attempt:** the archive as shipped did not build. The makefile calls `f77`, which is absent from the host and the sandbox (`make: f77: No such file or directory`, build_exit=2). Log: `evidence/original-attempt.log`.

**Build-only check:** `tools/verify_sources.py` compared 12 files across the pre, mid and post manifests. Nothing was modified before or during the build. Archive sha256 matches the queue entry's `code.archive` (b24ab9b2...cacc2).

**Command:** `reports/miminis1995-eigassign-747/recipe.sh` (sandboxed; fetch, then build, then run).

**Pins:** TOMS 747.gz (sha256 checked); gfortran and make from conda-forge via micromamba into the sandbox scratch.

**Evidence:** `evidence/` (unpack, build and run logs, both test01 outputs, the reference row, manifests, record log). The shipped reference `evidence/reference/dlog.ref` has sha256 a77b16ac...

**Gates:** G1 pass, G3 pass; G2 n/a (build-only patch); G5 n/a (no replay yet). `checks/gates.py` passes.

**Notes:** the shipped eigenvalue lists of the closed loop were not used as the claim, because the queue entry says the two shipped logs disagree there.
