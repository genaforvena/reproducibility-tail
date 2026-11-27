# kearfott1990-intbis-681: result (blocked)

**Claim.** Test problem 1 (cubic-parabola), number of roots found by ROOTS, as printed by the shipped GENBIS sample output. Paper value 3, tolerance abs 0.

**Verdict.** `blocked`, on gate G2. Basis `patched` (the intended route; the original attempt failed).

**Paper's value.** 3 (shipped sample output; the ACM article returned 403 here).

**Our value.** Not recorded as a verdict. Two clean runs of test problem 1 on the patched source printed "Number of roots found: 3", which matches the claim. The patch is not yet G2-cleared, so no `ours` value is graded.

**Why blocked.**
- The archive does not build as shipped. gfortran rejects the package routine `FREE` ("Too many arguments in call to 'free'", intbis.f:1397), which collides with the C library `free`.
- The fix is a two-line rename, `FREE` to `FREEBX` (evidence: `evidence/rename-diff-vs-archive-range.txt`).
- Compiler-flag routes to avoid the rename were tried and failed (`-fno-builtin`, `-fno-builtin -fno-builtin-free`), so the change is a source patch. The full G2 check stands.
- No paper section names the rename (see `g2-note.md`). The method text gives no exemption class for a token-proven identifier rename.

**What would change the verdict.** A written G2 rule for token-proven renames (then rerun with a `patch` record), or a decision that the full check cannot be met (then the verdict stays blocked).

**Original attempt.** Failed: `evidence/original-attempt-build.log`. This is a weak G1 record, because the build compiled the whole text file, prose included.

**Evidence and commands.** `recipe.sh` and the files under `evidence/`. Queue commit `aedeb1e`.
