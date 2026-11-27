# watson1997-hompack90-777: result

**Verdict: reproduced.** Basis: **patched (build-only)**.

## Claim

TOMS 777 (HOMPACK90, Fortran 90 homotopy solvers). The shipped `Drivers/RES3`, produced by
`driver3.f`, prints for `TESTING FIXPQS WITH STORAGE MODE = 1` the first solution component
Y(1) at lambda = 1 as **4.00864019E-01**. Registered as a real value with `tol_abs` 1e-8, fixed
in the queue entry before any run. The TOMS article was not read (paywalled); the claim rests on
the shipped RES3.

## Our value

- Pass 1: **0.400864019**
- Pass 2: **0.400864019** (clean rebuild from the unpacked shar)
- Shipped RES3: **4.00864019E-01** (0.400864019)
- Difference 0 at the printed precision, inside tol_abs 1e-8.

The rest of the FIXPQS, FIXPNS and FIXPDS output in both storage modes matches RES3 except
the EXECUTION TIME lines (machine-dependent, not used).

## Basis and why

The archive was unpacked as shipped (the shar header above `#! /bin/sh` dropped) and no source
file was edited. The build-only record (`verify_sources record`, exit 0) shows no modified,
added or removed file among the nine source files; only `.o` and `.mod` files were produced.
`Info/README` gives the compile order (`hompack90.f`, `lapack.f`, `blas1.f`, `blas2.f`,
`blas3.f`, then `driver3.f`) and no compiler command. gfortran with default flags, and the
`-I../Src` module path for `driver3.f`, are ours, so the basis is `patched`, as in the
brankin1997 record.

The compiler warns about a shape mismatch in a `DNRM2` call and a type warning in
`hompack90.f`; the output does not change.

## Exact command

```
bash reports/watson1997-hompack90-777/recipe.sh
```

Pins: gfortran 16.2.0 (conda-forge gcc 16.2.0-7, via micromamba in the sandbox).
The archive sha256 is `a86547e59ee7b090691b1db16e9e4d07ab018334a28f60ae13ca11e7cfd46498`.

## Evidence

`reports/watson1997-hompack90-777/evidence/`: `fetch-toolchain.log`, `unpack.log`,
`pass1-build.log`, `pass1-run.log`, `pass1-output.txt`, `pass2-run.log`, `pass2-output.txt`,
`reference/RES3`, `reference-block.txt`, `values.txt`, `record.log`, `manifest.{pre,mid,post}`.
