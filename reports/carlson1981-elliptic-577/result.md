# carlson1981-elliptic-577: result

**Verdict: reproduced.** Basis: **patched** (workaround: the archive's single file cannot be built as one program, so verbatim line ranges are compiled as separate units; no line of the authors' source was edited).

## Claim

RJ(2,3,4,5) from ACM TOMS Algorithm 577 (Carlson and Notis, 1981), called with ERRTOL = 1.D-3 by the RJ test driver. The driver's comment gives the check value 0.14297 57966 71567 53833 23308. Registered as `paper` = 0.14297579667156753833 with `tol_abs` = 1.4297579667156755e-4 (ERRTOL times the value), fixed before the run.

## Result

- Paper (shipped check value): 0.14297579667156753833
- Ours: 0.1429757966715675 (driver output row for X,Y,Z,P = 2,3,4,5, column RJ, printed as `0.1429757966715675D+00`)
- Difference: about 4e-17, against a tolerance of 1.43e-4. Margin well under 1%.

## Original attempt (G1)

The archive is one Fortran file (`577.gz`, sha256 61ac0a82...). It holds four subroutines (RC, RF, RD, RJ) and six unnamed test drivers, each a main program. As shipped it cannot be compiled and linked as one program: `gfortran` reports `Error: Two main PROGRAMs`. Log: `evidence/original-attempt-build.log`. Outcome recorded as `failed`.

## What was run

1. Fetch (sandbox, network only here): `577.gz`, sha256 checked (`evidence/archive-sha256-check.txt`), gfortran 16 from conda-forge (`evidence/gfortran-version.txt`).
2. Unpack: the file copied verbatim to `tree/577.f`. Manifests `pre`, `mid`, `post` show no change to any file (`evidence/manifests/`).
3. Build (no edit): lines 27-128 (RC) and 392-536 (RJ) to one unit; lines 805-844 (RJ driver) to a second unit; lines 846-887 (42 input sets) to stdin. Compiled `gfortran -x f77 -O2 -std=legacy`. `tools/verify_sources.py record` classified the patch as `build-only` (exit 0). Log: `evidence/build.log`.
4. Run: `rj_driver < data_rj` inside the sandbox, exit 0. Output: `evidence/run-pass1.txt`.

## Environment pins

- GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, flags `-O2 -std=legacy`.
- Sandbox: `tools/sandbox.sh` (read-only root, scratch on the spare drive, no network after fetch).

## Gates and grade

G1 pass (original attempt logged). G2 pass (build-only; no paper check needed for the patch). G5 not yet replayed. Grade by the ledger rules: basis `patched`, verdict `reproduced`.

## Not established

- Single-run evidence. A second pass is required only for `not-reproduced`; this is reproduced, so none was made.
- Whether the authors' own build (any compiler) matches byte for byte: not tested; the claim is a numeric agreement to 17 digits.

Reproduce: `reports/carlson1981-elliptic-577/recipe.sh`.
