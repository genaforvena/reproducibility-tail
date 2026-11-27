# richardson1973-jconsx-454: TOMS 454 (JCONSX, complex method for constrained optimization)

**Verdict: reproduced.** Basis `patched` (build-only). The shipped reference reproduces.

- Claim (shipped `Drivers/res1`, driver1, Box problem, seeded starts): ITERATION 20 corrected point 3.0000 1.7320,
  run ends at ITERATION 21 (tol 6e-5 on coordinates, exact on the count).
- Our run: 3.0000 and 1.7320 at ITERATION 20, count 21. Whole output equals the shipped `res1` except trailing blanks
  (`evidence/res1-compare.txt`, `diff -b` empty).
- The seed (123456789) is in the authors' source, not chosen by us.
- Build-only: the Makefile expects `src.f` in `Drivers/`, the archive ships it in `Src/`. The recipe uses
  `make VPATH=../Src driver1` and the f77 shim outside the tree (`impl/f77-shim.sh`). Manifests pre, mid and post are identical
  (5 files), so no source file changed.
- Original attempt (G1): `make Res` as documented stops at once, `make: f77: No such file or directory`. Kept in `evidence/original-attempt.log`.
- Replay (G5): clean rerun agrees with the record (`evidence/replay-2026-11-27T062445Z.log`). The first replay DIFFERED only
  because the recipe printed VALUE names that did not match `result.json`; the names were corrected and the replay then agreed.

Evidence: `evidence/` (fetch, unpack, original attempt, build, run logs, `shipped-res1.txt`, `res1-compare.txt`).
Command: `reports/richardson1973-jconsx-454/recipe.sh`. Pins: archive `454.gz` sha256 62edf4cc...; gfortran 16 (conda-forge) in the sandbox.
