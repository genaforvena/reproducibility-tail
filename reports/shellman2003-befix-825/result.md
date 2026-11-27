# shellman2003-befix-825: reproduced (basis: patched, build-only)

**Paper.** Shellman and Sikorski, "A deep-cut bisection envelope algorithm for fixed points" (Algorithm 825, ACM TOMS 29(3), 2003). Artifact: netlib CALGO `825.gz` (sha256 `b28e369b226302276dfb83188d493c3029ebfca1714f66123495015b5dbf9b07`, scout download 2026-11-27).

**Claim (registered, not edited).** The `average number of evaluations` printed for the first BEFix block of the large test (65025 cases, epsilon = 0.0001, q = 1, residual criterion), as shipped in `C/Drivers/bigtest.res` (line 42). Value `20.417255`, absolute tolerance `1e-6`. The claim is the code's own printed output, not a table value from the paper.

**Our value.** `20.417255`, identical in both passes (`-O2` and `-O0`), and identical to the shipped reference. The whole large-test output matches `bigtest.shipped.txt` except the interactive prompt line, which the shipped file contains because it was produced interactively.

**Verdict:** `reproduced`. **Basis:** `patched` (build-only). No archive file was edited.

## Original attempt (G1)

The readme's documented command is `gcc -lm fp.c -o fp`. The archive ships no `fp.c`: it ships `C/Src/src.c` and `C/Drivers/driver.c`. The documented command, unchanged, fails with `gcc_exit=1` (log `evidence/original-attempt.log`). Only then was the build patched.

## Patch (build-only)

The same documented GNU C compile (`-lm`), applied to the archive's own two files, written to a build directory outside the archive:

- `gcc -O2 -o driver /work/pre/C/Src/src.c /work/pre/C/Drivers/driver.c -lm`
- `gcc -O0 -o driver /work/pre/C/Src/src.c /work/pre/C/Drivers/driver.c -lm`

`tools/verify_sources.py record` returns `build-only`: 2 archive sources compared, none modified, none added or removed. The build-tool diff is empty.

## Exact command

`reports/shellman2003-befix-825/recipe.sh`, which fetches, unpacks, records and runs everything. The value is read from `./driver 1` (the large test) by a host-side parser that finds the first `BEFix residual criterion method, epsilon = 0.000100, q = 1.000000` header and its `average number of evaluations` line.

## Environment pins

- Sandbox compiler: gcc 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1), `evidence/env-pins.txt`.
- Kernel: 6.8.0-149-generic.
- Sandbox: `tools/sandbox.sh` (read-only root, `/work` on the spare drive, no network after the `--fetch` step).

## Evidence

`reports/shellman2003-befix-825/evidence/`: `fetch.log`, `fetch-probe.log`, `original-attempt.log`, `build.log` (gcc warnings only, no errors), `run.log`, `out.build.txt`, `out.build2.txt`, `bigtest.shipped.txt`, `manifest.{pre,mid,post}`, `env-pins.txt`, `recipe-run.log`.

## Status and what remains

- G3 (recipe exists and reproduces end to end): pass. The recipe was run twice; the second run wrote the `patch` record and printed the same value.
- G5 (replay): pending. It is not due yet. The `replay-due` duty will name it when it is.

## What would change the verdict

If a replay produced a value other than `20.417255`, or if the sandbox build differed from the recorded commands, the verdict would be revisited.
