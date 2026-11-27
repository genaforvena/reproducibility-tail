# dorrer1968-fdist-322: Algorithm 322, F-distribution (TOMS 322, Fortran 77)

**Verdict: blocked** (on gate G2, the paper check of the patch). **Basis: patched.**

Neither reproduced nor refuted yet. Both measured values are inside tolerance of the shipped expected values, but the verdict cannot be `reproduced` until G2 is decided (see below).

## Claim (registered, not edited)

Upper-tail probability p = 1 − PROB(nf1, nf2, f) from the shipped test driver's DATA tables, 0.05 block:

| name | paper (shipped expected) | tol_abs |
|---|---|---|
| p for F=161.45 with (1,1) df (table entry 51) | 0.05 | 5e-4 |
| p for F=2.9782 with (10,10) df (entry 63) | 0.05 | 5e-4 |

The reference is the test driver's own expected values (`claim.source` = artifact-reference), not a value read from the article.

## Measured (ours)

| point | pass 1 | pass 2 | e-diff (|0.05 − p|) |
|---|---|---|---|
| F=161.45, (1,1) | 0.5000E-01 | 0.5000E-01 | 3.5e-7 |
| F=2.9782, (10,10) | 0.5000E-01 | 0.5000E-01 | 1.9e-6 |

The driver prints four significant digits, so each value is 0.0500 to printed precision. The e-diff column gives the exact distance from 0.05 (the print precision is the limit of this reading, not the tolerance). Both are inside 5e-4 with a wide margin. Raw output: `evidence/pass1-stdout.txt`, `evidence/pass2-stdout.txt`.

## Original attempt (G1)

The archive text as shipped (`322.txt`) does not compile: lines 1–23 are mail prose and the shar separator. gfortran -std=legacy fails at line 1 (`evidence/original-attempt.log`). So the basis is `patched`.

## Patch

`sed -n '24,116p;120,254p' 322.txt > DORRER.FOR`: the Fortran code (PROB, the driver, the report subroutine) with the three lines 117–119 removed. Those lines are a `-------------` separator and two blank lines. gfortran rejects line 117. No statement, constant, or DATA value is changed.

`verify_sources.py record` exit 2, kind `source`. The contiguous range 24:254 does not compile, so the patch is not a pure extraction, and it is not build-only (the pre manifest compares 0 files, since `.txt` is not a source type). Gate G2 therefore applies.

## G2: what the paper check found

- A public scanned copy of CACM 11(2), pp. 116–117, was found at unibw.de (not the ACM publisher's copy). It is kept as `evidence/cacm-1968-alg322-webcopy.pdf`, with its PDF text layer in `evidence/paper-alg322-text-layer.txt`.
- Agreement: the parity values `a` and `b`, the `b = 1` branches, the first loop for `a = 1`, and the second loop are the article's own formulas, as transcribed.
- Differences of the shipped code from the article (these are the authors' code, not our patch):
  1. For `a ≠ 1` (even numerator df), the code uses Weissman's closed form `ZK = Z**((N-1)/2)`, not the article's recurrence `p := (p+w)·z` in the j-loop. The (10,10) claim point uses this branch.
  2. The caps `MIN(LM,300)` and `MIN(LN,5000)` are not in the article.
- The (10,10) value agreeing with the table to 2e-6 is evidence that the shipped even branch is numerically right at that point. It is not a paper check of the branch.

Our patch adds no new code, so G2's "each new piece cites the paper" has nothing to cite. Whether a deletion-only patch needs a G2 pass, and whether a shipped-code divergence from the paper is a G2 failure or a documented finding, is the scout's call. Until that is decided the gate says `na` and the verdict stays `blocked`.

## Recipe and pins

- `recipe.sh` (fetch, original attempt, patch, manifests pre/mid/post, two passes, values, record).
- Archive: netlib TOMS 322.gz, sha256 `f90c2156…eb294ecd`, checked. Text `322.txt` sha256 `c6b619e2…ddee03b`.
- Toolchain: GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, installed in the sandbox by micromamba.
- Command: `gfortran -std=legacy -w -o tstprob DORRER.FOR`, then `./tstprob < /dev/null`.

## Licence

The archive is TOMS code under the ACM licence of the archive. The licence text is in the archive; not separately recorded here.

## What would change the verdict

- Scout decides deletion-only is G2-na and documents the even-branch divergence as a finding: then G2 becomes `pass` by decision, and the verdict is `reproduced` (basis patched), with the divergence noted.
- Scout decides the divergence must be checked: the verdict stays blocked until a check of the a ≠ 1 branch against the article exists, or the claim is re-scoped (scout only).
- A changed replay would be diagnosed before anything else (G5 applies only after a reproduced verdict).
