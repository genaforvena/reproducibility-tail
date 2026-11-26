# fay2010-interval-npmle-example1: reproduced (basis: reimplemented)

**Claim** (scout, `queue/fay2010-interval-npmle-example1.json`): Fay & Shaw, JSS 36(2), 2010,
Section 6.3 and Table 2 ("NPMLE for example1", p. 29). The interval package's
`summary(icfit(L, R), digits = 12)` prints the NPMLE probability of the interval (2,3] as
`0.285714285714` for the seven rows typed in the paper. Tolerance (fixed before any run):
`|p - 2/7| <= 1e-6`.

**Paper value**: 2/7 = 0.285714285714.
**Rerun value**: 0.285714285714 (EM from a uniform start; also 0.285714285714 from a skewed start).
**Verdict**: reproduced, inside the registered tolerance.
**Basis**: `reimplemented`. R is not installed on this host, and `icfit` was not run. The port
(`impl/npmle_em.py`, CC0) is a Turnbull (1976) EM over the intersections of the observed
intervals. It was written from the paper's text, not from the `interval` source. This is weaker
than `original`.

## Independent check (analytic)

The likelihood factorises. With a = p1+p2 (mass of the two Turnbull intervals inside (1,7]) and
b = p3+p4 (mass of the two intervals inside (9,12]), the observations give
L ∝ (p1 p2) a² · b p3 p4, which is maximised at a = 4/7, b = 3/7 and p1 = p2 = a/2. So
P((2,3]) = 2/7, and the (5,6] mass is 2/7 too. The EM output agrees with this to 12 digits.

## Exact command

    reports/fay2010-interval-npmle-example1/recipe.sh

It copies `impl/npmle_em.py` to the scratch dir and runs it only through `tools/sandbox.sh`
(read-only root, no network, memory/CPU/time caps). No data are downloaded.

## Output (through the sandbox, 2026-11-26 13:21Z)

    Turnbull support: [(1, 7), (2, 3), (5, 6), (8, 10), (9, 10), (9, 12), (10, 12), (10, 13)]
      (2,3]  0.285714285714
      (5,6]  0.285714285714
      (9,10]  0.214285714286
      (10,12]  0.214285714286
      (others) 0.000000000000
    P((2,3]) = 0.285714285714  (2/7 = 0.285714285714)  loglik = -7.552945455143
    P((2,3]) from skewed start = 0.285714285714
    PASS |p - 2/7| <= 1e-06

## Environment pins

- Python 3 from the host `/usr` (read-only in the sandbox); `-I` isolated mode; standard library only.
- Paper: JSS v36i02, doi 10.18637/jss.v036.i02 (the scout read p. 29 with `pdftotext -layout`).
- R `interval` 0.9-9.6 (scout's pinned CRAN archive, sha256 in the queue entry) was not fetched:
  the rerun needed no R code, only the seven typed rows.

## Limits

- Not an `icfit` run. The match shows that the NPMLE value is reproduced, not that the R package
  computes it the same way; `icfit`'s own convergence rule and tie handling were not exercised.
- The paper prints the value without stating the support-point convention; the value of (2,3] is
  unique here by the factorisation above, so the convention does not affect the verdict.
