# hu1998-schwarzchristoffel-785: reproduced (basis: patched, build-only)

**Claim (registered, scout 73030b9):** example 1 of the shipped transcript `Fortran77/Drivers/Dp/RES`
(problem 1, NPTQ=7, M=4, N=4): U = 0.4559381277686, C = (1.8134230823216, -1.8134230823303),
absolute tolerance 1e-7. Claim and tolerance are as registered; not edited here.

**Our value (block 1 of our session run):** U = 0.4559381277686, C = (1.8134230823216, -1.8134230823303).
All three agree with the registered values exactly at the printed precision. Blocks 2 to 7 print but are
not claimed.

**Verdict:** reproduced. **Basis:** patched. The archive ships no build file. The unedited `driver.f` and
`src.f` compile with `gfortran -std=legacy`, and no source file was edited. The build-only proof is in
`result.json` `patch` (`manifest.pre` and `manifest.mid` identical, 2 files; `manifest.post` identical to `mid`).

**Exact command:** `bash reports/hu1998-schwarzchristoffel-785/recipe.sh`. Every step runs in
`tools/sandbox.sh`. The data file is fed to the driver as its keyboard stream.

**Environment pins:** gfortran from conda-forge (micromamba, installed in the sandbox `/work/env` during
the fetch step). Archive `785.gz`, sha256 `55965a41f823fb161c5df7b59933092f3879b7a8b57636859511be5c3f4f9175`
(checked by the recipe).

**Original attempt:** partial. The compile and run worked only after the `-std=legacy` flag was added;
the plain compile was not run and is not logged (`evidence/original-attempt.log`).

**Limits:** the paper (ACM TOMS 24(3), 1998) was not read. The shipped transcript is the only value checked.
The earlier blocked verdict (commit 93fa8a1) was against the example-6 claim, which named the wrong block.
That claim is superseded by the scout's example-1 re-registration.

**Evidence:** `evidence/run-session.txt`, `evidence/values.txt`, `evidence/shipped-RES.txt`,
`evidence/original-attempt.log`, `evidence/unpack.log`, `evidence/manifests/`, `note-to-scout.md`.

**Replay (G5):** pending at the time of writing. `replayed` is appended by `tools/replay.py`.
