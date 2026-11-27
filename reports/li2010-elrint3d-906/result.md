# li2010-elrint3d-906: result

**Verdict: reproduced.** Basis: **original**. The authors' C++ sources (ACM TOMS Algorithm 906, `elrint3d`), unchanged, compile with the archive's own driver flags and reproduce the shipped reference output `Drivers/res1` byte for byte in both passes.

## Claim

Cubature of the Gaussian integrand over [0,1]^3 printed by `C++/Drivers/test01.cc` at requested relative error 1e-12, against the registered value 0.88505988548101766 (shipped reference output `C++/Drivers/res1`), tolerance abs 1e-9. Fixed at registration (2026-11-27T09:40Z). Neither the claim nor the tolerance was edited.

## Values

| name | paper (shipped output) | ours pass 1 | ours pass 2 | tol_abs | result |
|---|---|---|---|---|---|
| Gaussian cubature over unit cube (test01) | 0.88505988548101766 | 0.88505988548101766 | 0.88505988548101766 | 1e-9 | within tolerance |

Pass 1 and pass 2 are identical (`evidence/values-run1.txt`, `evidence/values-run2.txt`). Both full outputs are identical to `res1` (`cmp`, recorded in `evidence/recipe-run.log`). The estimated error printed by the driver is 1.69e-14, far below the tolerance.

## Passes

- Pass 1: `g++ -Wall -Weffc++ -O3`, the flags in the archive's own `Doc/Makefile` (`CXXFLAGS=-Wall -Weffc++ -O3`), built in a fresh directory.
- Pass 2: `g++` with no optimisation flag, in a clean directory.

The two passes differ in optimisation level and give the same output to all 17 printed digits. An `-O2` build run during investigation (not a recipe pass) also matched `res1` exactly.

## Commands and environment

- Command: `reports/li2010-elrint3d-906/recipe.sh` (fetch, build, two passes, comparison). Every build and run goes through `tools/sandbox.sh`; only the fetch step had network.
- Archive: `https://netlib.org/toms/906.zip`, sha256 `6fc791c6f307eebdece7b369bd9ce2a06316c5ffe33f466c086fe3870d2d9d66` (checked by the recipe).
- Compiler: g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, from the sandbox's read-only `/usr`. No toolchain install was needed.
- Sources compiled: `C++/Src/*.cc` with `C++/Drivers/test01.cc`, linked as `test01`.
- Reference output: `evidence/reference/res1`, sha256 `41ff42ae9c5a4931bb981537f0040a56cc3ad03179705ca00f883e56074f287a`.

## Caveats

- The paper's own table was not read (ACM pages return 403 from this host). The registered value is the shipped reference output of the authors' driver, which is what the claim was registered as.
- The build flags come from the archive's `Doc/Makefile`, not a driver-specific build file. Both flag sets give the same output here.
- The driver's claim is one integral at one tolerance. It does not test the whole algorithm family.

## Evidence

- `evidence/original-attempt-build.log`: the build and run of pass 1 (the G1 attempt, kept once; it succeeded).
- `evidence/run-pass1.txt`, `evidence/run-pass2.txt`: full driver output for each pass.
- `evidence/recipe-run.log`: the recipe's log of the run that produced this verdict.
- `impl/extract_value.py`: reads the `Cubature` line and prints the `VALUE` line.

## Gates

G1 pass (the authors' sources ran as documented on the first attempt). G2 na (no patch, no reimplementation). G3 pass (two passes, identical). G5 not yet run (scheduled replay). G6 na (verdict is not `not-reproduced`).

## What would change the verdict

If a clean rebuild with the authors' flags gave a value outside 0.88505988548101766 ± 1e-9, the verdict would change.
