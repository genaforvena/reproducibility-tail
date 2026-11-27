# smith1991-fmpack-693: result (blocked)

**Claim.** TOMS 693 (D. M. Smith, FM floating-point multiple-precision package, ACM TOMS 17(2), 1991): SQRT(3) to 40
decimal places = `1.7320508075688772935274463415058723669428`, tolerance 5e-41, exact-string (narrow rule, commit 2e57688).

**Verdict: blocked** (cause of the block: G2 fidelity for a source patch; and the queue entry has no archive sha256).

**Our value (evidence, not a record).** At `-O0`, the FPPRNT line of the driver reads
`1.7320508075688772935274463415058723669428`, character for character the claim. `TEST COMPLETED. NO ERRORS.`
(`evidence/TEST-O0.OUT`).

**Why blocked, not reproduced:**

1. The authors' file does not compile as shipped. `gfortran -O2 693.f` fails with "Two main PROGRAMs at (1) and (2)"
   (PROGRAM ROOTS at line 9357, PROGRAM TEST at line 9534). Log: `evidence/original-attempt.log`.
2. The minimal build removes lines 9357-9533 (the ROOTS driver) before compiling. That is a source patch: two ranges
   are kept, so it is not a verbatim single-range extraction. Under `docs/method.md`, a source patch keeps the full G2
   check, which requires the paper's own text. The ACM article is not readable from this sandbox (403). G2 is open.
3. `queue/smith1991-fmpack-693.json` has no sha256 for `code.archive`, so the archive hash check of the gates cannot
   pass for any patch record. Asked scout to add `6491be48d95f425740778e99895cd31f8b2b6728c4b0b78b84f949b516fad1ba`.

**Diagnosis of a side result (not in the claim).** At `-O2` the SQRT(3) line still matches, but `SIN(1)` prints
`.9999999807278948647127421829626971114327` instead of `.8414709848078965066525023216302989996226`, and the self-check
reports `1 ERROR` (`evidence/TEST-O2.OUT`). The same source at `-O0` is correct. So the package's SIN(1) path is
sensitive to the optimizer under gfortran, not a fault in the sqrt path. Not diagnosed further (the claim does not depend
on it).

**Environment.** Sandbox `tools/sandbox.sh`; gfortran 16.2.0 (conda-forge gfortran_linux-64 via micromamba, in the
sandbox `/work/fortran`); archive `netlib.org/toms/693.gz`, sha256 `6491be48d95f425740778e99895cd31f8b2b6728c4b0b78b84f949b516fad1ba`;
raw source 9743 lines, sha256 of the decompressed file `b46faff4a9cb0e44df3b7b20fa8e1a7d4b11cf1d5221d0a67c5b29119458aa03`.

**Exact commands used.**

    tools/sandbox.sh --fetch smith1991-fmpack-693 -- sh -c 'curl -fsSL -o /work/693.gz https://netlib.org/toms/693.gz; gunzip -c /work/693.gz > /work/pre/693/693.raw; ...'
    tools/sandbox.sh smith1991-fmpack-693 -- sh -c 'cd /work/orig && gfortran -O2 693.f -o test693'          # fails, see evidence/original-attempt.log
    sed "9357,9533d" /work/pre/693/693.raw > p.f && gfortran -std=legacy -fallow-argument-mismatch -w -O0 p.f -o t693 && ./t693   # see evidence/

**Evidence.** `reports/smith1991-fmpack-693/evidence/`: `original-attempt.log`, `experiment-drop-roots.log`,
`TEST-O0.OUT`, `TEST-O2.OUT`.

**What would change the verdict.** A non-ACM copy of the paper text (for G2), or a queue-recorded archive sha256 (scout),
and then a `recipe.sh` that fetches, checks the sha, removes the ROOTS driver and builds at `-O0`, and two clean replays
with `tools/replay.py`. Until then this claim stays blocked; it is not `not-reproduced`.
