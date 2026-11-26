# greenberg1997-sleuth-775: provisional result (not final)

Status: the value matches the registered claim under the `reimplemented` basis. The verdict is NOT final:
gate G2 (paper fidelity) and gate G5 (second route) are open. No `result.json` yet; no ledger entry.

## Claim (registered in queue/greenberg1997-sleuth-775.json, not edited)
- Problem 1, BETA=10 pass, eigenvalue index 2, ELAM.
- Registered paper value: 4871.3813012287, tol_abs 1e-3.
- The paper text was not read (the value is the shipped RES reference output).

## Our value
- Pass 1 (-O2, clean directory): ELAM = 4871.3813065256945
- Pass 2 (-O0, clean directory, from a fresh unshar and fresh build): ELAM = 4871.3813065256945
- Difference from the claim: 5.3e-6, within tol_abs 1e-3. The shipped code's own error estimate is 4.08e-4.

## Basis: reimplemented (G1 original attempt failed)
- The authors' driver.f and src.f were compiled UNCHANGED (their hashes are in evidence/reference/sources.sha256).
- Original attempt (evidence/original-attempt.log): compile_exit=1. Undefined references to 8 NAG Library routines
  (F06YAF, F06PAF, F06QFF, F06QHF, X01AAF, X02AJF, P01ABF, C05AZF) and DTIME. The archive does not ship them,
  and Info/depend lists them as NAG routines.
- impl/nag_shims.f supplies them. Written from each routine's call semantics (BLAS-style for F06), not tuned to any
  output value. Limits:
  - C05AZF is a bisection stand-in with the caller's reverse-communication protocol (src.f:853). NAG uses Bus-Dekker.
    The zero is only accurate to the caller's EPS either way.
  - X02AJF is assumed to be 2**-53. Not checked against the NAG value.
  - P01ABF prints nothing for IFAIL=0. The authors' callers (src.f:699, src.f:3632) reach it with NREC and REC unset
    on the IFAIL=0 path. An earlier shim version printed those garbage lines, and the -O0 build segfaulted inside
    P01ABF (evidence: backtrace from a -fcheck=all -g build, in the transcript). The guard is in the committed shim.
  - Not done: the paper's own section or equation for these routines was not checked (G2).

## Gates status
- G1: original attempt failed (missing library, log kept). Reimplemented shims were needed.
- G2: OPEN. Each shim needs a paper citation; the paper is not read here.
- G3: two clean passes (-O2 and -O0) gave the same value to all printed digits (recipe.sh, evidence/run1-value.txt, run2-value.txt).
- G5: OPEN. A reimplemented match needs a second route (second implementation or analytic check).

## Pins and reproduction
- Command: `reports/greenberg1997-sleuth-775/recipe.sh` (runs fetch, build and both passes through tools/sandbox.sh).
- Source: netlib.org/toms/775.gz, sha256 193a6050951da6a0619b5299c9f5ebb56f72b0b763369dcebc1fe071d74c8c0c.
- gfortran: conda-forge gfortran_linux-64 via micromamba (latest, not yet pinned; next wake records the version).
- Shim file: reports/greenberg1997-sleuth-775/impl/nag_shims.f.
- Queue note discrepancy: the registered reference sha256 (da93...) is the uncompressed 775 file, not the RES member
  (our RES member is da53d7ae...). The claim value is unaffected; flagged for the scout.

## Evidence
- evidence/run1-fort7.txt, run2-fort7.txt (unit-7 output, both passes)
- evidence/run1-stdout.txt, run2-stdout.txt (unit-6 output)
- evidence/recipe-run.log (the last full recipe run)
- evidence/original-attempt.log (G1)
