# hurst1972-rnvr-425: reproduced (basis patched, build-only)

Claim (artifact-reference): the TEST02 block of the shipped driver output `Fortran/Sp/Drivers/res` (inside 425.gz, sha256 000dc68c...): RNVR on the 2x2 covariance [1 0.3; 0.3 1], seed iarg=123456789, 10 samples x 2 components, printed g14.6. Tolerance 1e-5 absolute on each of the 20 printed variates. The paper text is paywalled, so the shipped output is the only value checked.

Verdict: **reproduced**. All 20 values equal the shipped values exactly at printed precision, identical in both passes.

Basis: **patched**, build-only (`verify_sources.py record`: pre = mid = post in the authors' source files; the manifests are in evidence/). The change is to how the authors' code is compiled, not to the code. The shipped Makefile names no compiler (F77 empty) and its src.o rule looks for src.f next to driver.f, but the archive places src.f in Src. So the build runs the Makefile's own compile and link rules by hand:

- `gfortran -O2 -c driver.f`
- `gfortran -O2 -c ../Src/src.f -o src.o`
- `gfortran -O2 -o driver driver.o src.o`

Original attempt (G1): `make Res` as shipped, no compiler on PATH; it fails at `f77: No such file or directory`. Log: evidence/original-attempt.log.

Environment pins: gfortran 16.2.0 (conda-forge gcc 16.2.0-7), make 4.4.1, bwrap sandbox with no network after fetch. The archive 425.gz was fetched from netlib.org/toms/425.gz and sha256-checked.

Toolchain note: the first micromamba install stalled (network under 30 bytes/s); the env used for the original build was copied from the hong2003-snied-823 scratch env16 (same gfortran 16.2.0 package). recipe.sh skips the install when /work/env16/bin/gfortran exists.

Evidence: recipe-run.log (both passes, `PASSES AGREE`), shipped-res.txt (the reference copy), impl/parse_hurst.py (the parser that turns the TEST02 block into VALUE lines; checked on the shipped res).

Replay (G5): clean replay from nothing agrees with the record (05:19Z, log evidence/replay-2026-11-27T051935Z.log). Two earlier replays (05:09Z, 05:14Z) failed at fetch: the conda install did not link a `bin/gfortran` name, so recipe.sh now links it.

Rebuild: `reports/hurst1972-rnvr-425/recipe.sh`.
