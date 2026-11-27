# akima1991-uvip3p-697: reproduced (basis: patched, extraction)

**Claim (registered, queue commit ecbf0e0):** the one-call result YI2 of UVIP3P agrees with the expected values YIE in
the shipped test driver TTUVIP, at all 31 abscissas, for NP = 3 and NP = 6, absolute tolerance 0.0005. The claim is
artifact-reference: the oracle is the driver's own DATA statement, not a value printed in the paper (the ACM article was
not read; its page is unreachable from this host).

**Our value:** the largest printed |YI2 − YIE| is 0.000 for NP = 3 and 0.000 for NP = 6 (driver prints F9.3, so each
difference is below 0.0005). The repeated-call and inverted-data calls (DYI1, DYI3) also print 0.000 everywhere.

**Verdict:** reproduced. **Basis:** patched (extraction, G2 satisfied without a paper check).

## What was done

1. **Original attempt (G1).** The file as shipped (`697.f`, sha256 946b9d16…, 1073 lines) does not compile:
   `Error: Two main PROGRAMs at (1) and (2)`. The program TTUVIP and the subroutine UVIP3P appear twice (lines 1–538 and
   539–1073; the second copy differs only in one comment and an uncommented `10 OPEN` line). Log:
   `evidence/original-attempt.log`.
2. **Patch (extraction).** The build copies lines 1–538 verbatim into `UVIP.f` (the first copy, with the ACM notice,
   the driver and UVIP3P), then compiles with `gfortran -std=legacy -w -o ttuvip UVIP.f`. No statement, DATA value or
   comment is changed. `tools/verify_sources.py record` checks the copied bytes against the archive lines (range sha256
   `ee32dfeb…`) and the manifests show that the only change is the added `UVIP.f`.
3. **Two passes (G3).** Each pass starts from a fresh copy of the unpacked tree, applies the same patch, builds and runs
   the driver. Both print identical tables (`cmp` clean): `evidence/pass1-stdout.txt`, `evidence/pass2-stdout.txt`.
4. **Values.** `evidence/values.txt`: `VALUE YI2 vs YIE, NP=3, all 31 points 0.0` and the NP=6 line.

## Environment pins

- Archive: netlib `697.gz`, sha256 `4ffb5556…` (matches the queue entry); `697.f` sha256 `946b9d16…`.
- Compiler: gfortran from conda-forge through micromamba, installed in the sandbox at `/work/env` during the fetch step.
  The recipe does not record its version; `evidence/build.log` shows only the build.
- Sandbox: `tools/sandbox.sh`, read-only root, no network after the fetch, memory/CPU/time caps.

## Exact command

`bash reports/akima1991-uvip3p-697/recipe.sh` (fetch, original attempt, patch, build, record, two runs, values).

## What would change the verdict

- A replay that prints a value other than 0.0 for either NP (the registered tolerance is 0.0005; the number is compared
  with 1e-6 relative slack, so a replay that disagrees makes this result CHANGED).
- Printed precision is 0.001. The result says the difference is below 0.0005; it does not give a finer value. A finer
  number would need a separate harness, which would be an added file and a different patch kind, so it is not claimed here.
