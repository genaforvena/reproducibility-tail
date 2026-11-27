# griewank2000-revolve-799: Revolve (ACM TOMS Algorithm 799), C driver

**Claim** (artifact-reference, deterministic, pre-registered in `queue/griewank2000-revolve-799.json`): the shipped reference output `C/Drivers/res` (sha256 `1bb5a2b8…`, inside `799.gz`) gives, for STEPS=14, SNAPS=3, INFO=3, advances 27, takeshots 6, commands 47 and slowdown factor 1.9286. Counts are exact; the slowdown factor has absolute tolerance 5e-5.

**Paper value:** not read (paywalled). The shipped transcript is the oracle.

**Our value:** advances 27, takeshots 6, commands 47, slowdown factor 1.9286. Every value matches the registered value (diff 0). The full run output equals the shipped `res` after whitespace normalisation.

**Verdict:** reproduced. **Basis:** patched (build-only).

**Why patched:** the archive unpacks its own makefile with `$(CC)` and `$(LIBS)` expanded to nothing (unquoted here-document), so `make -f makefile_c` builds nothing. The original attempt failed and its log is kept (`evidence/original-attempt.log`). The build then ran the makefile's own compile and link lines by hand on the unedited tree. No authors' file was edited: `patch.kind` is `build-only` with 7 source files compared and no difference between the pre, mid and post manifests.

**Exact command:** `reports/griewank2000-revolve-799/recipe.sh`. Each step runs in `tools/sandbox.sh`, except the host-side hashing and parsing.

**Environment pins:** gcc (system, `/usr/bin/gcc`, version as in the sandbox image). netlib `799.gz` sha256 `8587175531d158f0c6f95f3bd507f149f04bbe0f1928810819c913d2c773a657`, checked at fetch. Driver stdin is the archive's `C/Drivers/data` (14, 3, 3).

**Evidence:** `reports/griewank2000-revolve-799/evidence/` (unpack, original attempt, build, run output, shipped res, values, manifests pre, mid, post, recipe run log).

**Limits:** only the C driver was run. The Fortran 77 driver in the same archive shipped with its own `res`, and was not run. The paper was not read. The result is an artifact match (the code still computes the authors' shipped trace), not a check of the paper's own table.
