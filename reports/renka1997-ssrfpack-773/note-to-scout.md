# renka1997-ssrfpack-773: note to scout

The registered claim is mis-specified as to tolerance, so the entry is `blocked`. I did not edit the claim or the tolerance.

**What the registered claim says.** FF(16,16) of the SSRFTEST run, equal to the shipped reference 0.4441613 within
abs 1e-6. The tolerance basis says single-precision noise over this fit is about 1e-7.

**What the rerun found.** Same sources, same driver, different toolchain or optimisation level:

- gfortran 16.2 -O2 (default): 0.44415909. Miss by 2.21e-6.
- gfortran 16.2 -O0 and -O1: 0.44416130. Hit (matches the shipped value to 8 digits).
- gfortran 13 -O2: 0.44416130. Hit.
- gfortran 16.2 -O2 -fno-tree-vectorize: 0.44416130. Hit.

So the spread between toolchains is about 2.2e-6, larger than the 1e-6 tolerance. The verdict depends on which toolchain
the claim names, and the claim names none.

**Why I did not grade it.** The method's single-value verdict is "not-reproduced" on a miss, but G6 needs a second pass to
confirm it, and the second toolchain (gfortran 13 -O2) reproduces. So the miss is not confirmed. Choosing the gfortran 13
value would be picking the friendlier environment after seeing the result. Recording the gfortran 16 -O2 value as
not-reproduced would be an unconfirmed verdict. Neither is a verdict the method allows.

**Question for the scout.** How should the claim be specified?

- Option A: keep abs 1e-6 and name the reference toolchain (for example "gfortran -O0 or -O1, or any -O2 without vectorisation"). The result would then be `reproduced`.
- Option B: widen the tolerance to a basis that covers toolchain spread (for example 5e-6, about twice the observed spread). The scout owns the tolerance. I will not choose it.
- Option C: keep the claim and accept a verdict that records the toolchain dependence explicitly, if the method has a form for it.

**Evidence.** `evidence/pass1-*` (gfortran 16 -O2), `pass2-*` (repeat), `pass3-*` (-O0), `pass4-*` (gfortran 13 -O2), and
`probe-flags.txt`. `recipe.sh` rebuilds all four passes. `evidence/shipped-RES.txt` is the shipped reference output.
