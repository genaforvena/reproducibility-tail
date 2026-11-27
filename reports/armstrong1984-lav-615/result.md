# armstrong1984-lav-615: TOMS 615 (SUBL1), best-subset L1 regression

**Verdict: blocked.** Basis: `patched` (extraction of the program's lines and build flags). No value was produced, so there is no reproduced or not-reproduced verdict.

**Cause: the authors' program does not terminate on its own input** in the build the recipe makes. It reads the whole data block, then loops inside `L1NORM`. This is recorded as a finding, not fixed.

## Claim

- Quantity: SUM OF ABSOLUTE VALUES for the LAV subset of size 3 (DL1BL3, BLISS vol II p.294), as printed by the authors' run.
- Paper (shipped sample output): **3.877**.
- Tolerance (registered, not edited): absolute **1e-3**.
- Our value: none. The run does not print.

## Original attempt (G1)

- The archive as delivered is the program (lines 1-1701), the TAPE5 data (1702-1781) and the shipped output (1782-1817) in one text file. gfortran rejects it: "Invalid character in name", "Non-numeric character in statement label". Log: `evidence/original-attempt-compile.log`.

## Patch and build

- Extraction: lines 1-1701 copied verbatim to `subl1.f` (one range). Manifests `pre`, `mid`, `post` in `evidence/manifests/`.
- Compile: gfortran 16, `-O2 -fdefault-real-8 -fdefault-double-8`. The two flags are needed because the caller at line 316 types `D1MACH` implicitly REAL, while the program's own `DOUBLE PRECISION FUNCTION D1MACH` (line 1201) returns double. The file's header says it is the DOUBLE PRECISION version. Build succeeds (`evidence/pass1-build.log`).

## Run and the hang

- The run reads `TAPE5` (lines 1702-1781, 1503 bytes). `strace` shows the read returns EOF, and after that the process makes no syscalls: it spins.
- `gdb` interrupt (batch, SIGINT) during the spin: `l1norm_ <- kbest_ <- MAIN__`, hot spot inside `L1NORM` (the main iterative loop, which increments `ITER` and jumps back with no cap).
- Same hang at `-O0 -g` (30 s bounded run, `rc=124`, no output). So it is not an optimisation artefact.
- Stdout is buffered, so an empty file alone would not prove a hang; the `strace` and `gdb` evidence does.

## Passes

| pass | build | result |
|---|---|---|
| original (G1) | gfortran 16, authors' file as delivered | does not compile |
| 1 | gfortran 16 -O2 + DP flags, extracted subl1.f | builds; run does not terminate |
| 2 | -O0 clean rebuild | not completed in this record (the stale `pass2-run.log` shows an old link error from a removed `d1mach.f` stub; it is not evidence about the current build) |

## What is not established

- Whether the hang is a defect of the authors' code or a consequence of the DP build. The archive carries single-precision alternates (`C++` lines, `R1MACH`). A single-precision variant would test this. I started it and did not finish it: it needs more conversion than switching the `C++` lines on (DABS/DSIGN type mismatches). It is a diagnostic, not the verdict build.
- Whether the sample output (lines 1782-1817) came from the DP or the single-precision build.

## Command

See `recipe.sh`. Run steps are wrapped in `timeout 120`, so a hang becomes a recorded failure rather than an open-ended wait.

## What would change the verdict

- A terminating run under a documented build that prints a value. If it is within 1e-3 of 3.877, it is `reproduced`, basis `patched`. If not, `not-reproduced` after a second pass.
- A finding that the single-precision variant terminates and gives 3.877: the record then gets a second build and the hang is a finding about the DP build.

Evidence: `evidence/` (compile log, build log, `pass1-run.log`, `recipe-run.log`, manifests). Scratch directory is deleted when this report is committed.
