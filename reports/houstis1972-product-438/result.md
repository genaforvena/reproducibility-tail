# houstis1972-product-438: reproduced (basis patched, build-only)

**Paper.** Houstis, Mitchell and Rice (1972), CACM Algorithm 438, "Product type two-point Gauss-Legendre-Simpson
integration". The archive is netlib TOMS 438.gz (sha256 bda38a3451fc5c7f11334fcd459802c5eb895b69b6c27c4fc9fe3527237a74e7),
a shell archive with Fortran/Dp/Drivers (Makefile, driver.f, res) and Fortran/Dp/Src (src.f).

**Claim (registered by scout, not edited).** VINT for N = 10 on TEST01 is 2.65082 in the shipped `res` file.
Tolerance 2e-5 absolute.

**Our value.** `VALUE VINT_TEST01_N10 2.65082`. The difference from the claim is 0. The driver's whole output is
identical to the shipped `res` (`evidence/res-diff.txt` is empty).

**A note on the driver, not a change to the claim.** The TEST01 header says "from -1 to 1", but the code integrates
1/(1+x*x) over [-4,4] (`a = -4`, `b = 4`), and the driver's own Exact line, 2*atan(4) = 2.65164, uses [-4,4]. The
registered claim is the printed N = 10 value, and it is kept as registered.

**Verdict.** reproduced. **Basis:** patched, build-only.

- G1, original first: the Makefile in the shipped layout stops at once with
  `make: *** No rule to make target 'src.f', needed by 'src.o'.` The archive puts src.f in `Fortran/Dp/Src/`, while the
  Makefile expects it beside itself. Log: `evidence/original-attempt.log`.
- Build-only patch: nothing in the authors' source was changed. The Makefile's rules were run as separate commands from
  `Fortran/Dp/Drivers`, with src.f taken from `../Src`. The pre, mid and post manifests are identical
  (`evidence/manifest.*`), so `verify_sources.py record` wrote `kind: build-only`.
- Warnings from gfortran only; no flags were added.

**Environment pins.** gfortran 16.2.0 (conda-forge gcc 16.2.0-7, micromamba, `gfortran_linux-64`), installed in the
sandbox during the fetch step. Everything ran through `tools/sandbox.sh`.

**Replay (G5).** Not yet run. A replay is due by the replay-due duty.

**Command.** `reports/houstis1972-product-438/recipe.sh` rebuilds and reruns everything from a clean scratch directory.
