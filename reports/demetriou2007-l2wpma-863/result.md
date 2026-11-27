# demetriou2007-l2wpma-863: TOMS 863, L2WPMA (Fortran 77)

**Verdict: reproduced.** Basis: `patched`, build-only (grade B). Claimed on 2026-11-27 (see `claimed`).

## Claim

The shipped reference output of DRIVER1 (Appendix B of `Doc/INSTDE04.txt`, and `Data/Appndx_B/WIVAPP` in 863.zip,
sha256 `c6b56ede...b767`, verified). The claim is the data indices of the extrema of the best monotone fit to
`Data/Appndx_B/XFWDAT` with KSECTN = 5 and default weights. Tolerance 0 (integers, exact match), fixed in the queue entry.

| claim | paper (shipped) | ours | match |
|---|---|---|---|
| extremum index 0 | 1 | 1 | yes |
| extremum index 1 | 8 | 8 | yes |
| extremum index 2 | 27 | 27 | yes |
| extremum index 3 | 46 | 46 | yes |
| extremum index 4 | 69 | 69 | yes |
| extremum index 5 | 75 | 75 | yes |

## What was run

- Archive: `863.zip` from netlib, sha256 `5947abca...7657` (checked in the sandbox fetch step).
- Original attempt (G1): the authors' Fortran with no compiler (host and sandbox have no gfortran). Failed; log
  `evidence/original-attempt.log`.
- Toolchain: conda-forge `gfortran_linux-64` 16.2.0, installed inside the sandbox.
- Build (basis `patched`, build-only): `gfortran -std=legacy -O2 -o driver1 Drivers/driver1.f Src/src.f`, built from
  the unedited authors' tree. The manifests pre, mid and post show no source change (`result.json` `patch.kind`
  = `build-only`). The shipped `Doc/Makefile` has every compiler choice commented out, so the builder names the compiler.
- Run: DRIVER1 with `XFWDAT` in a clean directory, KSECTN 5 on stdin, two passes (G3). Both passes agree.
- Recipe: `recipe.sh`. Log: `evidence/recipe-run.log`.

## Notes

- The paper text was not read: the ACM DL copy is paywalled. The claim rests on the shipped reference output only.
- The claim is an artifact match: it shows that the code still reproduces its own published output on a modern
  compiler. It does not check the paper's theory.
- Replay (G5) is pending and recorded in `result.json` `replayed` once run.
