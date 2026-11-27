# kuki1972-cgamma-421: TOMS Algorithm 421 (complex gamma and log-gamma, Kuki)

**Verdict: reproduced.** Basis `patched` (build-only). The shipped reference output reproduces at 8 printed digits.

- Claim: the five loggamma entries in the shipped reference output `Drivers/res`, real and imaginary parts each,
  absolute tolerance 1e-6 (one print unit of the 8-digit E format). The 1972 article was not read (dl.acm.org returns 403
  to automated fetch); the claim is the shipped package's own output, as the queue entry registers.
- Our run, against the shipped `res` (same 8-digit values):
  - loggamma(1,5) = (-6.1303241, 3.8158986)
  - loggamma(2.5,5) = (-3.6681033, 5.8060098)
  - loggamma(5,10) = (-4.2855074, 19.117071)
  - loggamma(2.5,-5) = (-3.6681033, -5.8060098)
  - loggamma(5,-10) = (-4.2855074, -19.117071)
  - Largest absolute difference from `res`: 0 for all five entries.
- Original attempt (G1): the Makefile as documented names no compiler (F77 is empty). `make RES` stops at the first compile:
  `make: f77: No such file or directory`. Kept in `evidence/original-attempt.log`.
- Patch (build-only): no source file is edited. The Makefile's rules are run by hand with gfortran (default flags):
  `driver.f90` compiled in `Fortran90/Dp/Drivers`, `src.f90` compiled from `Fortran90/Dp/Src` into `Drivers/src.o`,
  then linked to `driver`. The archive keeps `driver.f90` and `src.f90` in sibling directories, and the Makefile expects
  one directory, which is why the rules are spelled out. Manifests pre, mid and post are identical for all three source
  files (`evidence/manifests/`); `verify_sources record` gives kind `build-only`.
- Run: `./driver < data`, output written to scratch, not the tree (`evidence/run.txt`).

Evidence: `evidence/` (unshar log, original attempt, build log, run output, recipe run log, the shipped `res` used as the
reference (`shipped-res.txt`, sha256 7d21d6f2...), manifests). Command: `reports/kuki1972-cgamma-421/recipe.sh`.
Pins: archive `421.gz` sha256 cea2d067...; gfortran from conda-forge via micromamba in the sandbox (`/work/env`).
Scratch: `/mnt/mishe-scratch/reproducibility-tail/kuki1972-cgamma-421`, removed after the commit.
