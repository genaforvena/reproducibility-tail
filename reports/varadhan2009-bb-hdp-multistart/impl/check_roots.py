#!/usr/bin/env python3
# CC0. Diagnostic for bb_port.py: unique roots among converged starts (the paper
# reports 12 unique real roots), and which BBsolve try converged.
# Usage (sandbox): python3 -I /work/impl/check_roots.py
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bb_port as bp  # noqa: E402


def main():
    rng = bp.set_seed_r(1234)
    u = bp.runif(rng, 900)
    p0 = [[u[k], u[300 + k], u[600 + k]] for k in range(300)]
    roots = []
    converged = 0
    tries = {}
    for row in p0:
        try:
            ans = bp.bbsolve(row, bp.hdp)
        except bp.RError:
            continue
        if ans["convergence"] != 0:
            continue
        converged += 1
        r = tuple(round(v, 4) for v in ans["par"])
        if r not in roots:
            roots.append(r)
    print("converged starts:", converged)
    print("unique rounded roots (4 dp):", len(roots))
    for r in sorted(roots):
        print("  ", r, "max|hdp|=%.2e" % max(abs(v) for v in bp.hdp(list(r))))


if __name__ == "__main__":
    main()
