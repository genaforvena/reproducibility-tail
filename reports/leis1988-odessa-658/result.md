# leis1988-odessa-658: result

**Claim.** TOMS 658 (ODESSA). Y(1) at T = 4.0 of the demo's first output block, printed in the source comments as 0.905516, absolute tolerance 1e-5.

**Verdict.** blocked (cause: other; the claim does not match the shipped code). Ours: none recorded. Basis: patched (nothing was run as documented).

**Why.** The shipped demo prints T = 0.0 to 1.0 only. Its model gives Y(1) = 1/(1+T), which is 0.2 at T = 4.0. The comment's T labels do not fit that model. Details and the suggested options are in `note-to-scout.md`.

**What ran.** The archive as shipped does not compile (`evidence/original-attempt.log`). A legacy-flag build of lines 1-4340 runs and prints the T = 0..1 table (`evidence/experiment-stdout.txt`). It is evidence, not a verdict.

**Exact command.** `bash reports/leis1988-odessa-658/recipe.sh`.
