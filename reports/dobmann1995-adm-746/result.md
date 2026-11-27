# dobmann1995-adm-746: result

**Claim.** TOMS Algorithm 746 (ADM, automatic differentiation, Dobmann, Liepelt and Schittkowski, 1995). The shipped driver output `Results/tp1.res` prints the generated derivative error for TP1 (Rosenbrock, X = (-2, 1), MAXFUN = 10000) as **0.451D-03**. Registered tolerance: absolute 5e-6, the half unit of the printed third digit (fixed before any run).

**Verdict: reproduced**, basis **patched** (build-only).

- Paper value: 0.000451 (0.451D-03 as printed). Our value: 0.000451 in both passes. Difference 0.
- The printed value has three significant digits, so this match only shows the rounding-level agreement. It does not test more digits.

## Original attempt (G1)

- The archive's build file is `Doc/Makefile` (the shar places it under `Doc/`). It sets `FC = epcf90` (a compiler not on this host) and links `TIMER` from an NFS path.
- Run as shipped, `make -f Doc/Makefile -C Fortran77/Dp/Drivers tp1 VPATH=../Src` fails: `missing separator`. The `all:` continuation lines end in a literal `\\`, which make does not treat as continuation. Log: `evidence/original-attempt-build.log`.
- The archive's own `adm.f` already defines `EVLTIM` (timer), so no timer stub is needed. The `TIMER` object is not used.

## Patch (build-only)

- The Makefile's `tp1` rule was run as its commands, with gfortran 16 (conda-forge, `gfortran -O2 -std=legacy`), from a build directory outside the tree. Commands are in `recipe.sh` and `result.json` `patch.build_commands`.
- `verify_sources.py`: manifests pre and mid are identical (4 files compared, no change), so the patch is `build-only`. The build tool changed nothing. Manifests: `evidence/manifests/`.
- No source file was edited.

## Runs

- Two runs, fresh directory and new process each: `evidence/run-pass1.txt`, `evidence/run-pass2.txt`. Both print `Generated derivative error: 0.451D-03`.
- `VALUE tp1_generated_derivative_error 0.000451`.

## Environment

- Sandbox: `tools/sandbox.sh` (read-only root, scratch on the spare drive, no network after fetch).
- Archive: netlib TOMS 746.gz, sha256 `c68a4dff…8b5749`, checked against the queue entry.
- Compiler: GNU Fortran 16.2.0 (conda-forge gcc 16.2.0-7) via micromamba. `evidence/gfortran-version.txt`.

## Gates

- G1: original attempted and failed (Makefile), basis `patched` fits.
- G2: not needed (build-only).
- G3: two passes in one recipe run agree.
- G5: not yet replayed. The replay will be run by the next replay duty.

## Command

    bash reports/dobmann1995-adm-746/recipe.sh

Rebuilds from the archive and reruns both passes.

## Limits

- Only the tp1 claim is registered. The other 40+ tests in the archive are not claimed.
- Timing columns depend on the machine and are not part of the claim.
