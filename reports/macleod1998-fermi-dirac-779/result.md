# macleod1998-fermi-dirac-779: Algorithm 779, Fermi-Dirac functions of order -1/2, 1/2, 3/2, 5/2

**Verdict: reproduced.** Basis: `original`. Claim source: `artifact-reference` (the authors' own DP driver output, `Drivers/Dp/RES`).

## Claim

The DP test driver `fdtestdp.f` prints, for each of the four functions, 15 arguments per half-range, the EXACT VALUE (from a 16-digit table in its DATA statements) and COMP. VALUE. The registered claim is the 8th argument of each half-range block: FDM0P5(-4), FDM0P5(3), FDP0P5(-4), FDP0P5(3), FDP1P5(-4), FDP1P5(3), FDP2P5(-4), FDP2P5(3). Values and tolerances (1e-5 relative to the exact value) are in `queue/macleod1998-fermi-dirac-779.json` at commit 826c062 and were not edited.

| value | paper | ours (printed, 7 digits) | abs diff | tol_abs | within tol |
|---|---|---|---|---|---|
| FDM0P5(-4) | 0.01808192299 | 0.01808192 | 3.0e-9 | 1.8e-7 | yes |
| FDM0P5(3) | 1.853485089 | 1.853485 | 8.9e-8 | 1.9e-5 | yes |
| FDP0P5(-4) | 0.01819820351 | 0.0181982 | 3.5e-9 | 1.8e-7 | yes |
| FDP0P5(3) | 4.487547421 | 4.487547 | 4.2e-7 | 4.5e-5 | yes |
| FDP1P5(-4) | 0.01825672759 | 0.01825673 | 2.4e-9 | 1.8e-7 | yes |
| FDP1P5(3) | 7.788610770 | 7.788611 | 2.3e-7 | 7.8e-5 | yes |
| FDP2P5(-4) | 0.01828611841 | 0.01828612 | 1.6e-9 | 1.8e-7 | yes |
| FDP2P5(3) | 11.11289952 | 11.1129 | 4.8e-7 | 1.1e-4 | yes |

## Original attempt (G1)

The archive has no Makefile and no build command. The double-precision sources (`Drivers/Dp/fdtestdp.f`, `Src/Dp/src.f`) are already in double precision, so the comment instruction about conversion does not apply. They compile with plain gfortran and run without any source change. The first attempt succeeded, so no patch was needed. Log: `evidence/original-attempt.log`.

The only addition is the compiler: the host has no Fortran compiler, so gfortran (conda-forge) is installed in the sandbox during the fetch step (same method as the patterson recipe).

## Second pass (G3)

- Pass 1: built with `-O2`, run from the driver directory. Output: `evidence/run1-output.txt`.
- Pass 2: clean directory, `-O0` rebuild, run again. Output: `evidence/run2-output.txt`.
- Both passes have columns 1-3 (X, EXACT, COMP) identical to the shipped `RES`. Column 4 (REL. ERROR) differs in the last digits, around 1e-15. That is floating-point noise between builds: the shipped RES has the same magnitude of relative error. It does not touch any registered value.
- Pass 1 and pass 2 are byte-identical to each other.

## Limits

- The authors' build flags are unknown (the archive records none). `-O2` and `-O0` are our choices; the basis stays `original` because the source is unchanged and the first build of the shipped code succeeded. A reader who wants a stricter label can treat it as `patched`.
- The registered values are the printed 7-digit COMP VALUE, so the comparison is limited by the printing precision (about 5e-6 relative). The tolerance is 1e-5, so this is accounted for in the registration.
- The 16-digit EXACT table in the driver is the authors' own; the check is that the code agrees with that table, as the authors recorded it.

## Evidence

- `evidence/original-attempt.log`: compile of the shipped sources (G1).
- `evidence/recipe-run.log`: recipe output from an empty scratch directory.
- `evidence/run1-output.txt`, `evidence/run2-output.txt`: outputs of the two passes.
- `evidence/values.txt`: the 8 registered rows parsed from pass 1.
- `evidence/reference/RES`: the shipped reference output, sha256 f39caf7d…abab0 as in the queue entry.

## Rebuild

`reports/macleod1998-fermi-dirac-779/recipe.sh`: fetch (sha256 checked), build, two passes, VALUE lines. It was run from an empty scratch directory and gave the same values.
