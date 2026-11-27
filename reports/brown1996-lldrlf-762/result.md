# brown1996-lldrlf-762: result (reproduced)

**Claim.** `log(f(exp(W)|DFN,DFD))` at W = -1000 standard deviations, A = B = 1e-3, as printed by LLDRLF through the authors' `driver1.f`. This is the shipped reference output (RES1, first block), so it is an artifact-match claim, not a number from the paper's tables. Registered tolerance: abs 1e-6.

**Verdict.** `reproduced`. Basis `patched`, build-only: the authors' source is unmodified, and only the compiler was supplied.

**Paper's value (shipped RES1).** -1.4180151734062165E+03

**Our value.** -1.4180151734062165E+03, in both passes. Difference 0, inside tolerance.

**What was run.** Netlib TOMS 762.gz (sha256 checked against the queue entry), unpacked verbatim with `extract-tree.awk` (no shell archive executed). Built with GNU Fortran 16.2.0 `-O2` from `Src/Dp/src.f`, `others.f`, `port.f` and `Drivers/Dp/driver1.f`, unmodified. The driver is interactive, so stdin answers select the default grid and PAUSE is answered with blank lines.

**Original attempt (G1).** The archive ships no makefile and no build instructions. The sandbox as shipped has no Fortran compiler, so the first attempt could not start (exit 127): `evidence/original-attempt-build.log`. After gfortran was installed into the sandbox, the same unmodified sources compiled cleanly: `evidence/retry-gfortran-compile.log`.

**Patch (build-only).** `verify_sources.py` manifests: pre = mid, 5 files compared, nothing modified, removed or added in the tree. Build tool changes: none. Kind `build-only`, so G2 is not needed.

**Gates.** G1 pass (failed original attempt logged). G2 n/a (build-only). G3 pass (two passes in fresh run directories give the same value). G5 pending: a clean replay is run next, see the ledger.

**Evidence.** `reports/brown1996-lldrlf-762/evidence/`: archive hash check, gfortran version, unpack listing, shipped RES1, manifests, build log, run-pass1 and run-pass2 outputs, recipe run log.

**Environment pins.** GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0; `tools/sandbox.sh` (bwrap, no network after fetch); archive sha256 `a4d88389baadaec61bce2de0ea4c28d76c53996ba0e25b5e55d901e67c9a4b51`.

**Reproduce.** `bash reports/brown1996-lldrlf-762/recipe.sh` (needs the sandbox and micromamba fetch). The recipe prints `VALUE logf_W-1000 <number>`.
