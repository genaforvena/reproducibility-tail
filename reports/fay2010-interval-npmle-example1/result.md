# fay2010-interval-npmle-example1: reproduced (basis: original)

**Claim** (scout, `queue/fay2010-interval-npmle-example1.json`): Fay & Shaw, JSS 36(2), 2010, Section 6.3 and Table 2 ("NPMLE for example1", p. 29). `summary(icfit(L, R), digits = 12)` prints the NPMLE probability of the interval (2,3] as `0.285714285714` for the seven rows typed in the paper. Tolerance (fixed before any run): `|p - 2/7| <= 1e-6`.

**Paper value**: 2/7 = 0.285714285714.
**Rerun value**: **0.285714285714** (from `icfit`, two driver runs; the printed line is `1    (2,3] 0.285714285714`).
**Verdict**: reproduced, inside the tolerance.
**Basis**: `original`. The authors' `interval` 0.9-9.6 package was built with `R CMD INSTALL` in the sandbox (R 4.5.3 from conda-forge, installed in the `--fetch` step), with no source edits. The paper's listing is run as written.

## Attempts

1. `evidence/attempt1-conda-solve-failed.log`: conda-forge could not solve `r-icens`/`r-mlecens` (neither is on conda-forge). Failed.
2. `evidence/attempt2-mlecens-lib-missing.log`: Icens came from bioconda and the solve passed, but the MLEcens install into `/work/Rlib` failed because the directory was not created yet. A recipe bug, fixed.
3. `evidence/original-attempt.log`: the successful run (exit 0). The MLEcens install is in the log.

## Pins

- interval 0.9-9.6 (CRAN archive), sha256 `93a73d61…72dc0`, matches queue.
- Icens 1.82.0 (bioconda, `bioconductor-icens`).
- MLEcens 0.1.7.1 (current CRAN, not an archived release; the fetch step records it). The paper does not state its dependency versions.
- perm 1.0-0.4 and survival 3.8-12 (conda-forge).
- R 4.5.3.

## Independent check (analytic)

The likelihood factorises. With a = p1+p2 (mass of the two Turnbull intervals inside (1,7]) and b = p3+p4 (mass inside (9,12]), the observations give L ∝ (p1 p2) a² · b p3 p4, which is maximised at a = 4/7, b = 3/7 and p1 = p2 = a/2. So P((2,3]) = 2/7. The earlier Turnbull EM reimplementation (`impl/npmle_em.py`, `recipe-reimplemented.sh`) gives the same value to 12 digits and agrees with this check. It is kept as a cross-check, not as the verdict basis.

## Limits

- The claim is closed-form (see `note-to-scout.md`). The run shows that the authors' code returns the printed value for this data. It does not test the NPMLE algorithm on a case where the answer is not known in advance.
- The paper prints the value without stating the support-point convention. For (2,3] the value is unique by the factorisation, so the convention does not affect the verdict.

## Exact command

    reports/fay2010-interval-npmle-example1/recipe.sh

Fetches the pinned tarball and the dependencies (sandbox `--fetch` steps only), builds the authors' package, runs `impl/run_original.R` twice (G3 replay).
