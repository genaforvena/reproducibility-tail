# linhart2008-lnnorm-885: Algorithm 885, logarithm of the normal distribution, C

**Claim (pre-registered, unchanged):** -lnnorm(-5.0), computed by the authors' `C/lnnorm.c`, equals the
Sheppard (1939) Table IV value for row x = 5.0, 15.0649983939887257 (shipped in `C/sheppard.txt`), at absolute
tolerance 1.5e-8.

**Our value:** 15.064998393988725 on both clean passes. |ours - paper| is zero at the printed precision.

**Verdict:** `reproduced`. **Basis:** `patched`. The authors' makefile does not link as documented on this host;
the only change is one linker flag. The authors' sources are unedited (see below).

## What ran

- Fetch: `https://netlib.org/toms/885.zip`, sha256 `4415d85a...` (matches the registration), unpacked in the sandbox.
- Original attempt (G1, failed, log kept): `make -f ../Doc/makefile` in `C/`. Link stops with
  `undefined reference to log, exp, erf, ...`. The makefile puts `-lm` before the objects, which the default
  `--as-needed` linker rejects. `evidence/original-attempt.log`.
- Patched build: the same makefile, run unchanged, with `CFLAGS='-Wl,--no-as-needed -lm'`. No source file and no
  makefile line is edited. Build-only proof: `verify_sources.py record` reads manifests pre/mid/post and gives
  kind `build-only`, exit 0 (G2 pass). `evidence/build.log`.
- Probe (`impl/probe_lnnorm.c`, written from the claim text): the authors' driver `main` prints only maxima and
  means over the table, not the single claimed value. The probe calls the authors' `lnnorm()` at x = -5.0 and
  prints `-lnnorm(-5.0)` with 17 significant digits. It does not change any authors' file.
- Runs (G3): two clean directories, each with the binaries from the build tree. The probe prints
  `15.064998393988725` both times. The driver's whole-table stdout is kept as evidence
  (`evidence/run{1,2}-driver-stdout.txt`); it is not compared line by line here.
- Environment pins: gcc (Ubuntu 13.3, host default), `cc -O`, sandboxed via `tools/sandbox.sh`.

## Command

`reports/linhart2008-lnnorm-885/recipe.sh` (fetch, original attempt, build-only record, two runs, values).

## Open items

- G5 replay not yet run (`replayed` is empty).
- The paper (ACM DL) was not read; the claim rests on the shipped table alone.
