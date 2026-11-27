# gil2002-scorer-822: TOMS 822 (GIZ, HIZ), complex Scorer functions

**Verdict: reproduced.** Basis: `patched`, build-only (no source file edited; the three manifests prove it).
Grade B: the authors' code with build fixes.

## Claim

- Quantity: the maximum modulus of the addition-formula residual for the unscaled GI(Z) (IFAC=1, GITEST),
  printed by SCTEST into `Res1` as `MAXIMUM VALUE OF THE MODULUS OF THE CHECK`.
- Paper value (shipped reference, `Fortran77/Drivers/Dp/res1` in netlib 822.gz): **9.1704421834038e-14**.
- Tolerance (registered in the queue entry, not edited): absolute **1e-12**.
- Our value (three passes, identical): **9.1704421834037930e-14**.
- Difference: about 7e-27, far inside the tolerance.

## Passes

| pass | build | value |
|---|---|---|
| 1 | gfortran 16.2.0 -O2 (the original attempt, unmodified sources) | 9.1704421834037930E-014 |
| 2 | gfortran 16.2.0 -O2, clean rebuild | 9.1704421834037930E-014 |
| 3 | gfortran 16.2.0 -O0 | 9.1704421834037930E-014 |
| replay | `tools/replay.py` from empty scratch, final recipe | agrees with the record (G5) |

The other lines of `Res1` differ from the shipped `res1` only in the last digits of residuals of order 1e-15
(`evidence/diff-shipped-vs-run1.txt`), which is round-off on a different machine and does not touch the registered value.

## Basis and the original attempt

- The archive's own `Doc/Makefile` cannot run here: it sets `FC=epcf90`, which is not installed, and lists `airy.f`,
  which the archive does not ship. Log: `evidence/original-attempt-make.log` (`make: epcf90: No such file or directory`, exit 2).
- We therefore wrote the compile and link lines ourselves (`recipe.sh`) and edited no source. `impl/unshar.py` unpacks the
  shell archive without executing it.
- `verify_sources.py record` classifies the patch as **build-only** (`result.json` `patch`): pre and mid manifests match,
  post matches as well, 10 build commands recorded between the second and third manifest calls.

## Command and pins

- Rebuild and rerun: `reports/gil2002-scorer-822/recipe.sh` (all runs inside `tools/sandbox.sh`).
- Toolchain: `GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0` (`evidence/gfortran-version.txt`), via micromamba from conda-forge.
- Archive: netlib `822.gz`, sha256 `ae6c947ece8fea8ba98d2f10ce44e3370e14af7a9e14a92217dfcfc5a65e8a50` (matches the queue entry).
- Shipped reference: `evidence/shipped-res1.txt`, sha256 `89e7b3c7f283e1ecdeac431a6ff1dfa862a3dad4b928dde0091a01a7ac6d9468`.

## Evidence

- `evidence/pass{1,2,3}-Res1.txt` (each file starts with the build and run status lines, then the driver output),
  `evidence/pass*-run.log`, `evidence/recipe-run.log`, `evidence/replay-2026-11-27T074805Z.log`.
- Manifests: `evidence/manifests/manifest.{pre,mid,post}`.

## Limits

- The article text (ACM, dl.acm.org) was not read; the claim rests on the shipped reference value, as registered.
- The authors' Makefile was never run to success; the compile lines are ours. The number is a round-off-level residual,
  so a different compiler would be expected to move it by a small factor only.

## What would change the verdict

- A replay that disagrees with 9.17e-14 beyond 1e-6 relative (the replay rule) makes the entry CHANGED; diagnose it first.
