# west1983-qap-608 (TOMS 608, HGW heuristic for the extended Koopmans-Beckmann QAP, Fortran 77)

**Verdict:** blocked (on gate G2, the paper check for a source edit). **Value:** reproduced under both single-alternative variants; no result record written yet.

## Claim (registered, not edited)

`HGW` on the 4x4 instance hard-coded in the shipped test PROGRAM MAIN returns OBJ = 406 (driver comment `OBJ=406, ASSIGNMENTS: 4,1,3,2`), tolerance 0.005.

## What happened

1. **Original attempt (G1), failed to build.** The shipped 608.gz (sha256 bac06089...; the file is 511 lines, `608.f`, sha256 1d0e7493...) contains two definitions each of `DELTA` (lines 190 and 250) and `DELTX` (lines 413 and 440). The first pair is the general version (its header says NEITHER F NOR D IS ASSUMED SYMMETRIC); the second pair is the symmetric version. gfortran `-std=legacy` stops with `Global name 'delta' ... already being used as a FUNCTION` and the same for `deltx`. Log: `evidence/original-attempt.log`. So, as shipped, the file does not compile.
2. **Variants (source edits, not build-only).** Variant `gen` deletes the symmetric pair (lines 250-312 and 440-469). Variant `sym` deletes the general pair (lines 190-249 and 413-439). Both build with `gfortran -std=legacy -O -w` and both print `OBJ= 406.00 ASSIGNMENT= 4 1 3 2` and `CORRECT`. `gen` at -O0 also gives 406.00. Log: `evidence/variants-run.log`.
3. **Why this is not yet a record.** Deleting lines from the authors' source is a source edit, so `tools/verify_sources.py` cannot mark it build-only and gate G2 needs a paper check (section or equation for the choice of alternative). The paper was not read and the ACM article is paywalled. The sandbox fetch (`evidence/fetch.log`) also ran only as far as the archive and toolchain.

## Not yet established

- Which alternative the paper's computation uses. Both give 406 on this symmetric instance (F is symmetrised and D is symmetric in MAIN), so the value does not depend on the choice here, but that is a property of this one instance, not a G2 check.
- The paper's own value, if any. The claim rests on the shipped driver's comment.

## Next (bounded)

- Resolver for G2: the operator (paper text for TOMS 608, the section that defines HGW's general vs symmetric case). Ask once, with the question: "Can you give me the paper section or equation that says whether HGW uses the general or the symmetric DELTA/DELTX for non-symmetric F, D?"
- Meanwhile: write `recipe.sh` for the `gen` variant with the three manifest calls, and record `patched` (not build-only) with the G2 status open, rather than a passing record.
