# kraft1994-tomp-733: result

**Verdict: blocked** (G2 open; the value itself is reproduced under the local passes, but the verdict is not final).
Resolver: scout. Disposition: next rerun wake after scout answers the question in `note-to-scout.md`.

## Claim (registered in queue/kraft1994-tomp-733.json, not edited)

- Paper: D. Kraft, TOMS 733 (TOMP, Fortran modules for optimal control), ACM TOMS 20(3), Sep 1994.
- Value: the converged final cost of the shipped test driver, iteration 27, `0.17952392D+01` (1.7952392), tol_abs 1e-5.
- Source: the archive's own shipped output (`File TOMP.OUT`, lines 77-109 of 733.f). The article is paywalled and was not read.

## Our value

- Pass 1: 1.79523920 (`evidence/pass1-stdout.txt`, `evidence/pass1-tomp.out`)
- Pass 2: 1.79523920, output byte-identical to pass 1 (`evidence/pass2-stdout.txt`)
- Difference from the claim: 0 at the printed precision, inside tol_abs 1e-5.
- Iteration 27 constraint violation: 0.8375D-06 here; shipped TOMP.OUT shows 0.8371D-06. The claim is the cost, not this value.

## Why it is still blocked

- The gate that is open is G2 (paper check). The earlier note said the archive prose the driver depends on was not
  available. Reading the archive shows that its own prose (`TOMP.TXT`, the header of 733.f, lines 1-76) is present
  and describes the driver. What is still missing is the reference [1], D. Kraft, *TOMP -- FORTRAN Modules for
  Optimal Control Calculations* (VDI Fortschritt-Berichte 8 Nr. 254, 1991), and the TOMS article.
- Whether G2 applies to an artifact-reference claim is the open question for the scout. The same class of claim
  (resende1998-gmis-787, brankin1997-rksuite90-771) has G2 `na`.

## Build and run so far

No `recipe.sh` exists yet. The two passes were run by hand in the scratch tree with the micromamba gfortran
(`/mnt/mishe-scratch/reproducibility-tail/kraft1994-tomp-733`, 1.3 GiB, kept). Writing `recipe.sh` (sandboxed fetch,
build, two passes, manifests) is the next step once G2 is answered.

## Evidence

`reports/kraft1994-tomp-733/evidence/`: `pass1-stdout.txt`, `pass2-stdout.txt`, `pass1-tomp.out`, `pass1-stderr.txt`.
The earlier `claimed` (2026-11-26T17:20Z) and `result.json` (blocked, 472d3ce) are unchanged.
