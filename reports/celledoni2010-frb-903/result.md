# celledoni2010-frb-903: result

**Verdict: reproduced.** Basis: `patched` (build-only). Claim source: artifact-reference.

## Claim

Algorithm 903, FRB (Celledoni and Zanna, ACM TOMS 37(2), 2010). The claim is line 14 of the shipped reference output `Fortran77/Drivers/out_example0.dat` in `903.zip`. That line is PIOUT(1), the first component of the output angular momentum after one exact step (Np = 0, h = 0.1) of the free rigid body, computed from the shipped `init_example0.dat`.

- Registered value: -0.7088447919224319
- Absolute tolerance: 1e-10 (fixed before any run, not edited)
- This is the code's own printed output, not a table value from the paper. The paper's table or figure was not read.

## Our value

- Pass 1 (`gfortran -O`): line 14 = -0.7088447919224319. Difference from the claim: 0.
- Pass 2 (`gfortran -O2`, separate build directory): line 14 = -0.7088447919224319. Difference from the claim: 0.
- Largest difference between all 25 regenerated lines and the shipped file: 5.6e-17 in both passes.

## Original attempt (G1)

The archive's `Doc/Makefile`, unchanged, fails in the sandbox. Its `FC` is `/opt/NAGWare/bin/f95` (NAG, absent). It also expects the sources beside `Doc/`, but the archive ships them in `Fortran77/Src` and `Fortran77/Drivers`. The result is `make: No rule to make target 'driver_example0.f'`. Log: `evidence/original-attempt.log`.

## Patch (build-only)

The Makefile's only driver rule is `$(FC) $(FOPTS) -o driver_example0 driver_example0.f frb_step.f`. The recipe runs that exact command with:

- `FC` = the sandbox gfortran 16.2.0 (conda-forge, `/work/env`),
- `FOPTS` = `-O` (pass 1) and `-O2` (pass 2) instead of the NAG flags,
- the two sources' absolute paths in the archive tree.

`make`'s VPATH does not rewrite the command text, so the command is written out literally in `recipe.sh`. No archive file is edited or linked. The driver's output goes to a separate build directory.

`tools/verify_sources.py record` returns `build-only`: 8 archive source files compared, none modified before the build. The manifests are `evidence/manifest.{pre,mid,post}`.

## Environment pins

gfortran 16.2.0 (gfortran_linux-64 16.2.0, gfortran_impl_linux-64 16.2.0, gcc_linux-64 16.2.0, libgfortran5 16.2.0, conda-forge). See `evidence/env-pins.txt`.

## Limits

- Both passes use the same compiler and differ only in optimisation level. This tests the optimisation sensitivity, not a second compiler family.
- The shipped value and our value agree to all 16 printed digits. That is consistent with the shipped output coming from this same code, but it does not show that the code matches the paper's own numbers. The claim as registered is the shipped output.
- The recipe runs the Fortran code directly, not through the archive's Makefile. That is the compiler change the build-only route allows.

## Evidence

`recipe.sh`, `evidence/fetch.log`, `evidence/env-pins.txt`, `evidence/archive-read.txt`, `evidence/original-attempt.log`, `evidence/build.log`, `evidence/run.log`, `evidence/recipe-run.log`, `evidence/out_example0.{build,build2,shipped}.dat`, `evidence/manifest.{pre,mid,post}`. Machine-readable record: `result.json`.

## Re-run

`reports/celledoni2010-frb-903/recipe.sh` fetches `903.zip` (sha256 checked), builds, runs both passes, and prints `VALUE PIOUT1_h0p1 <number>`.
