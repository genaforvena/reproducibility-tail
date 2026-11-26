"""Reimplementation of the NPMLE for interval-censored data (Turnbull 1976 EM),
written from Fay & Shaw (JSS 36(2), 2010), Section 6.3 / Table 2, example1 data.

Observations are (L, R] intervals, as in icfit(L, R). Support is the set of
Turnbull intervals: non-empty intersections of observed intervals, with the
intersection of (a,b] and (c,d] being (max(a,c), min(b,d)].
EM: p_j <- (1/n) * sum_i [ p_j * 1{j in obs i} / sum_k p_k 1{k in obs i} ].
Public domain / CC0. Usage: python3 -I npmle_em.py
"""
from fractions import Fraction
import sys

L = [2, 5, 1, 1, 9, 8, 10]
R = [3, 6, 7, 7, 12, 10, 13]
TARGET = (2, 3)          # the interval (2,3]
EXPECTED = 2 / 7         # exact NPMLE value the paper prints as 0.285714285714
TOL = 1e-6


def turnbull_intervals(L, R):
    cands = set()
    for a, b in zip(L, R):
        for c, d in zip(L, R):
            lo, hi = max(a, c), min(b, d)
            if lo < hi:
                cands.add((lo, hi))
    return sorted(cands)


def contains(obs, cand):
    (a, b), (lo, hi) = obs, cand
    return a <= lo and hi <= b  # candidate lies inside the observed (a,b]


def em(L, R, cands, start=None, iters=20000, tol=1e-15):
    n = len(L)
    p = [1.0 / len(cands)] * len(cands) if start is None else list(start)
    inside = [[j for j, c in enumerate(cands) if contains((L[i], R[i]), c)]
              for i in range(n)]
    for _ in range(iters):
        new = [0.0] * len(cands)
        for i in range(n):
            denom = sum(p[j] for j in inside[i])
            for j in inside[i]:
                new[j] += p[j] / denom
        new = [x / n for x in new]
        delta = max(abs(a - b) for a, b in zip(new, p))
        p = new
        if delta < tol:
            break
    loglik = sum(__import__("math").log(sum(p[j] for j in inside[i])) for i in range(n))
    return p, loglik


def main():
    cands = turnbull_intervals(L, R)
    print("Turnbull support:", cands)
    p, ll = em(L, R, cands)
    for c, q in zip(cands, p):
        print(f"  ({c[0]},{c[1]}]  {q:.12f}")
    idx = cands.index(TARGET)
    prob = p[idx]
    print(f"P((2,3]) = {prob:.12f}  (2/7 = {EXPECTED:.12f})  loglik = {ll:.12f}")
    # Start-independence check: a skewed starting point should reach the same value.
    skew = [0.7 if c == TARGET else 0.3 / (len(cands) - 1) for c in cands]
    p2, _ = em(L, R, cands, start=skew)
    print(f"P((2,3]) from skewed start = {p2[idx]:.12f}")
    ok = abs(prob - EXPECTED) <= TOL and abs(p2[idx] - EXPECTED) <= TOL
    print("PASS" if ok else "FAIL", f"|p - 2/7| <= {TOL}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
