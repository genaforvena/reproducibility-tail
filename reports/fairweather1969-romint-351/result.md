# fairweather1969-romint-351: TOMS 351 (ROMINT, Romberg quadrature)

**Verdict: reproduced.** Basis `patched` (build-only). The shipped TEST02 reference reproduces.

- Claim (shipped reference `Drivers/res`, TEST02, MAXE in = 5): VAL 0.886227 (tol 1e-5), N 65 (exact).
- Our run: VAL 0.886227, N 65. Both match.
- Build-only: the Makefile expects `src.f` in `Drivers/`, but the archive ships it in `Src/`. The recipe uses
  `make VPATH=../Src driver` and an f77 shim outside the source tree (`impl/f77-shim.sh`) that maps `src.f` to
  `../Src/src.f` and runs `gfortran -std=legacy`. Manifests pre, mid and post are identical (3 files), so no source file changed.
- Original attempt (G1): `make Res` as documented fails at once: `make: f77: No such file or directory`. Kept in `evidence/original-attempt.log`.
- Not claimed: the ERR column differs in the last digits for MAXE in = 2 and 3 (e.g. 0.567320E-02 against the shipped 0.567326E-02). Recorded, not graded.

Evidence: `evidence/` (fetch, unpack, original attempt, build, run logs, `shipped-res.txt` sha256 36b295ef...).
Command: `reports/fairweather1969-romint-351/recipe.sh`. Pins: archive `351.gz` sha256 afeb019f...; gfortran 16.2 (conda-forge) in the sandbox.
