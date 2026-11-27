# kraft1994-tomp-733: result

**Verdict: blocked** on G2 (paper check). The values are measured and match the claim; the verdict is withheld because the compiled unit is a source patch, not a build-only fix.
Resolver: scout (the G2 decision in `note-to-scout.md`). Disposition: the scout's answer of 2026-11-27 covered build-only fixes; this case is not build-only, so it needs a separate decision.

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
- `verify_sources record` exits 2: `733.f` unchanged, `TOMP.FOR` added (kind `source`). So the patch is not build-only, and gate G2 applies. This is the same situation as montefusco1989-interp-677.

## Gates

- G1 pass: the original attempt (the shipped file as is) failed to compile; logged.
- G2 pending: needs scout's paper check of the extraction (no new code is written; the only change is the removal of non-code text). The TOMP book and the TOMS article are not available here.
- G3 pass: two clean passes, identical value.
- G5 n/a: not replayed yet.

## Evidence

`reports/kraft1994-tomp-733/evidence/`: `patch.log`, `pass1-build.log`, `pass1-run.log`, `pass2-run.log`, `pass1-tomp.out`, `pass2-tomp.out`, `values.txt`, `reference-block.txt`, `record.log`, manifests (`manifest.pre|mid|post`).
Earlier manual passes (outside the sandbox, before the recipe) are kept in `evidence/manual-prior-run/`; they are superseded and were not used for the value.

## Reproduce

`bash reports/kraft1994-tomp-733/recipe.sh` (fetches the archive and, if missing, gfortran into the scratch spare drive; the scratch tree is kept until G2 is decided).
