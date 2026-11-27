# kraft1994-tomp-733: result

**Verdict: reproduced** (basis patched, kind `extraction`). Our value 1.7952392 matches the registered 1.7952392 within tol_abs 1e-5.
G2 passes by the extraction rule (scout's decision, message #115): the patch step only copies lines 556 to the end of `733.f` into `TOMP.FOR`, byte for byte; `tools/verify_sources.py record` checks the range hash against the mid manifest, and `checks/gates.py` re-checks it from `evidence/source-range.f`.

## Claim (registered in queue/kraft1994-tomp-733.json, not edited)

- Paper: D. Kraft, TOMS 733 (TOMP, Fortran modules for optimal control), ACM TOMS 20(3), Sep 1994.
- Value: the final cost of the shipped test driver at iteration 27, `0.17952392D+01` (1.7952392), tol_abs 1e-5.
- Source: the archive's shipped output block (733.f lines 77-109, `File TOMP.OUT`). The article is paywalled and was not read.

## Our values (recipe.sh, sandboxed, two passes)

- Pass 1: 1.7952392 (`evidence/pass1-tomp.out`, iteration 27, constraint violation 0.8371D-06).
- Pass 2: 1.7952392 (`evidence/pass2-tomp.out`).
- Difference from the claim: 0 at the printed precision, inside tol_abs 1e-5.

## Build and patch

- As shipped, `733.f` does not compile. Lines 1-555 are the archive's prose (TOMP.TXT, TOMP.OUT, TOMP.M) and MATLAB data, not comment-marked. gfortran stops at line 4 (the original attempt, `evidence/pass1-build.log` of the recipe run; the failing lines are quoted in result.json).
- The Fortran code starts at line 556 (`SUBROUTINE d_TOMP`). The patch step is the extraction of lines 556 to the end into `TOMP.FOR` in the build copy. No line of the code is changed, and `733.f` is never edited.
- Build: `gfortran -std=legacy -w -o tomp TOMP.FOR`.
- `verify_sources record --archive-file ... --range 556:6242 --extracted TOMP.FOR` exits 0 with kind `extraction`: `733.f` unchanged, `TOMP.FOR` the only addition, its hash `8d7dceb4…` equal to the range hash. Build-only does not apply (a file was added before the build), so the extraction rule is the G2 route.

## Gates

- G1 pass: the original attempt (the shipped file as is) failed to compile; logged.
- G2 pass by the extraction rule (kind `extraction`; the copied code is the archive's own bytes, so there is no fidelity question left to check against the paper; the TOMP book and the TOMS article were not read).
- G3 pass: two clean passes, identical value.
- G5 n/a: not replayed yet (G3 two-pass is the recorded replay).

## Evidence

`reports/kraft1994-tomp-733/evidence/`: `patch.log`, `pass1-build.log`, `pass1-run.log`, `pass2-run.log`, `pass1-tomp.out`, `pass2-tomp.out`, `values.txt`, `reference-block.txt`, `record.log`, manifests (`manifest.pre|mid|post`).
Earlier manual passes (outside the sandbox, before the recipe) are kept in `evidence/manual-prior-run/`; they are superseded and were not used for the value.

## Reproduce

`bash reports/kraft1994-tomp-733/recipe.sh` (fetches the archive and, if missing, gfortran into the scratch spare drive; the scratch tree is kept as the source for the archive range).
