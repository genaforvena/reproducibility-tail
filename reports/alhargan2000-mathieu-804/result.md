# alhargan2000-mathieu-804: REPRODUCED (basis: patched, build-only)

**Claim** (registered from the artifact's own reference output, not the paper's table): row x = 19.790, column 4 (h = 9, Sn of order 3) of `CPP/Dp/Drivers/res1` in the TOMS 804 archive is **+2.750024**, absolute tolerance 1e-6.

**Our value:** +2.750024 (difference 0). The whole output of `./driver < data1` also matches the shipped `res1` line for line (`diff` exit 0, 206 lines).

**Verdict:** reproduced. **Basis:** patched. The build is build-only: `verify_sources` compared 12 source files, found no change before the build, and exits 0. The workaround is a compiler include path, not a source edit (see below).

## What happened

- **G1, original attempt (failed).** The archive Makefile, unchanged, begins with `include makefile.inc`. That file is not in the archive, so `make res1` stops at once (`make_exit=2`, log `evidence/original-attempt.log`).
- **Build as the Makefile's rules would run it, with the authors' own compile lines (failed first).** Under g++ 13.3.0 the shipped `bsslr.cpp` does not compile: its global `inline double abs(double)` (line 19) conflicts with the `using std::abs` that the C++ wrapper `<stdlib.h>` injects, and the calls `abs(n)` are ambiguous (log `evidence/build-original-abs.log`). `-std=gnu++98` does not help.
- **Workaround (patched).** `/work/shim/stdlib.h` (in the sandbox, outside the archive) contains only `#include </usr/include/stdlib.h>`. It is passed as `-I/work/shim` to every compile. The shim is written before the mid manifest. No archive file is created, edited or copied.
- **Build and run.** The six compile lines and the link line are the Makefile's own rules, with `-O2`. `./driver < data1` writes the table (`evidence/Res1`).

## Command

`reports/alhargan2000-mathieu-804/recipe.sh` (fetch the archive with the sha256 check, run the G1 attempt, write the shim, build, record the patch, run, extract the value). Environment: host `g++` 13.3.0 (Ubuntu 24.04) inside `tools/sandbox.sh`; archive sha256 `d6cb0600…dd02`.

## Evidence

`reports/alhargan2000-mathieu-804/evidence/`: `fetch.log`, `manifest.{pre,mid,post}`, `shim.log`, `original-attempt.log`, `build-original-abs.log`, `build.log`, `driver-run.log`, `Res1`, `res1.shipped`, `recipe-run.log`.

## Limits

- Only the row x = 19.790, column 4 is claimed. The remaining values in res1 match the shipped file as a whole, but only this one is registered.
- The `-O2` flag and the shim are our choices. The archive's `makefile.inc` was never seen, so its real flags are unknown.
- No second pass: the result is reproduced, so the two-pass rule for `not-reproduced` does not apply.
