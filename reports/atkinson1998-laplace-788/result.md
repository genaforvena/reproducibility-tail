# Rerun result: atkinson1998-laplace-788 (ACM TOMS Algorithm 788, Atkinson and Jeon 1998, NEUMAN)

## Verdict

**not-reproduced** (cause: numerical-discrepancy, as detailed below), basis **patched** (one documented source edit to `d1mach.f`, see below).

Under the registered tolerance, our value does not match the shipped reference value. The difference is 5.9e-8, against a registered tolerance of 5e-12. The reference value is also not the analytic solution at this point. See "Cause".

## Claim (registered, not edited)

- Source: artifact-reference. The shipped output `Fortran77/Drivers/Dp/RES1` inside `netlib.org/toms/788.gz` (sha256 86e9c5c9ae7abcee40dbc4afe303e559416a91dd9a0383d6c09edb9d8706a775).
- Value: U(X,Y) at the interior point (0.1112, 1.3695), IBD=0, from the NEUMAN run on `data1` (boundary function 3, curve 1 (ellipse A=1, B=4), EPS=1.0E-7, NTHETA=5, NR=10).
- Paper (shipped reference): -0.77655693670 (printed as -7.7655693670D-01).
- Tolerance: abs 5e-12 (half unit of the printed 11th decimal). Not loosened.

## Our value

- -0.77655687809 (printed as -7.7655687809D-01), from the authors' own NEUMAN code and driver, built with gfortran 16.2.0 (`-O2 -std=legacy`).
- Difference from the reference: 5.86e-8. Outside the tolerance.

## Cause

The reference value is not the analytic solution at this point. The test function for NUMF=3 is F = exp(x)cos(y) - 1 (`GVFCN` in `driver1.f`). At the point the driver actually uses (x = 0.111246117975, y = 1.369521383465, from the ellipse parameterisation with theta = i·2π/5 and R = 2f - f², f = j/10, i=1, j=2), F = -0.776556878092. Our value agrees with that to 1e-11. The shipped RES1 is about 6e-8 away from it. The shipped RES1 also reports a "true error" (ERROR column) of 7.77D-16 at this point, which is inconsistent with its own value; our run reports 5.55D-16.

So the shipped reference output is internally inconsistent with its own test function, by an amount inside the requested EPS (1e-7). The cause of that shipped discrepancy (the HP C200 build or run, per the README) is not established here. We did not try to reproduce the HP environment.

We ruled out the following as the cause of our difference from the shipped value:

- The machine constants `d1mach.f`: the shipped file is configured for big-endian IEEE machines (SGI, HP). We activated the file's own documented block for 8087/little-endian machines (a source patch, see below). The value did not change (-0.77655687809 both with and without the patch).
- Optimisation level: a `-O0` build gives the same value.
- Uninitialised variables: a build with `-fcheck=all -finit-real=snan` runs clean and gives the same value. No uninitialised-read warning was reported for the numerical routines.

## Basis and patch

- The shipped Makefile sets `FC=epcf90`, which is not on this host. The original attempt fails with exit 2 (`epcf90: No such file or directory`). Log: `evidence/original-attempt-build.log`.
- We build the authors' own sources with gfortran, running the Makefile's `neuman` commands directly. No source is edited except one patch to `Fortran77/Src/Dp/d1mach.f`: the lines 49-53 (big-endian IEEE block) are commented out and lines 59-63 (the file's documented 8087 block) are activated. The file's header says to do this for other machines. Evidence: `evidence/patch-d1mach.txt`.
- Because a source file was changed before the build, the verify_sources record reports `kind: source` (exit 2), so the full G2 paper check applies. That check is the comparison above.

## Second pass (G6)

The verdict is not final until a second pass confirms it. Two further builds were run in fresh directories, as diagnostics in `evidence/diagnostic-O0-and-checks.txt`:

- `-O0` build: -0.77655687809.
- Checked build (`-O0 -g -fcheck=all -finit-real=snan`): -0.77655687809.

Both match the first pass to 11 digits. The independent oracle is the analytic test function above. The unpatched `d1mach.f` build is also in `evidence/diagnostic-unpatched-d1mach-run.txt` (same value).

## Commands and environment

- Recipe: `reports/atkinson1998-laplace-788/recipe.sh` (run inside `tools/sandbox.sh`; no network after fetch).
- Archive sha256 check: `evidence/archive-sha256-check.txt`.
- Compiler: GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, `evidence/gfortran-version.txt`.
- Manifests (pre, mid, post) and the build-only/patch record: `evidence/manifests/`, and `result.json` "patch".
- Run log: `evidence/run-pass1.txt` (the full driver output, res1 file).
- Shipped reference copy: `evidence/shipped-RES1`.

## What would change the verdict

- A shipped reference or a second archive version giving the value -0.77655687809 (or the analytic value) would close the discrepancy in the reference, not in our build.
- Running the authors' code on the HP C200 or a comparable machine would test whether the shipped RES1 reflects a platform effect. We have not done this.
- A different value for the test point (if the driver's point rounding differs on another platform) would also explain it. We checked the point against the formula; the driver's own point is what we used.
