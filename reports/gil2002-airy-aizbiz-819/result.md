# gil2002-airy-aizbiz-819: TOMS 819 (AIZ, BIZ complex Airy functions), Wronskian checks

**Verdict: reproduced. Basis: original. Grade: A (the authors' code, run as shipped).**

## Claim

Paper Section 4.1 (TOMS 28(3), pp. 331-332) states that the Wronskian checks for scaled Airy functions are
"consistent with a relative accuracy better than 10^-13". The shipped driver (Fortran77/Dp/Drivers/driver.f, program
WRTEST, IFAC=2) prints one maximum residual per check into res1..res4. Four values are registered, each with
absolute tolerance 1e-13.

| check | shipped (paper) | ours (pass 2) | abs diff |
|---|---|---|---|
| res1, CHECK1 (A&S 10.4.10) | 9.43689571e-15 | 9.5479180117763462e-15 | 1.1e-16 |
| res2, CHECK2 (A&S 10.4.11) | 5.23650405e-15 | 5.2218853419634024e-15 | 1.5e-17 |
| res3, CHECK3 (A&S 10.4.12) | 5.19100205e-15 | 5.1497626483375173e-15 | 4.1e-17 |
| res4, CHECK4 (BIZ Wronskian) | 9.37486625e-15 | 9.4061512267874000e-15 | 3.1e-17 |

All four are inside the registered tolerance, and all four are strictly below 1e-13, the paper's stated bound.

## Method

- Original attempt (G1): the authors' sources compiled as shipped with gfortran -O2
  (`Drivers/driver.f`, `Src/src.f`, `Src/port.f`). No edits. `compile_exit=0`. Log: `evidence/original-attempt.log`.
- Two passes (G3): run 1 is the original binary in its build directory; run 2 is the same binary in a clean directory.
  Both exit 0 and give identical maxima.
- The archive readme says port.f must be replaced on Fortran 77 compilers. gfortran accepts its Fortran 90 intrinsics as
  shipped, so no patch was made and no build-only record is needed.
- Environment: netlib TOMS 819.gz (sha256 26af2205d9c0d935ca5612d0ec4696d0045e5e6b09429b1d553b898ca0d3cb92, checked);
  gfortran from conda-forge into the sandbox scratch, same as the TOMS 831 rerun.
- The shipped res1..res4 are copied unedited to `evidence/reference/`.

## Command

`reports/gil2002-airy-aizbiz-819/recipe.sh` (fetch, original build, two runs, print VALUE lines).

## Evidence

- `evidence/recipe-run.log`: full run log.
- `evidence/run1-res*.txt`, `evidence/run2-res*.txt`: the driver's outputs per pass.
- `evidence/reference/res1..res4`: shipped outputs.

## Not yet done

- G5 replay: none yet. The next replay runs the recipe from nothing (`tools/replay.py --id gil2002-airy-aizbiz-819`).
- The scratch directory is removed after the commit, per the charter.
