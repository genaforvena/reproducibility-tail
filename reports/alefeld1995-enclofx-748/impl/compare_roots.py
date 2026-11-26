# Compares every COMPUTED ROOT of a run with the shipped testout, pair by pair (CC0 helper, rerun).
# Usage: python3 -I compare_roots.py TESTOUT RUNSTDOUT. Prints pairs, pairs within 1e-8 and max |diff|.
import re, sys

def roots(path):
    return [float(m.group(1).replace("D", "E")) for m in re.finditer(r"COMPUTED ROOT =\s*(\S+)", open(path, encoding="latin-1").read())]

ref, got = roots(sys.argv[1]), roots(sys.argv[2])
pairs = list(zip(ref, got))
within = sum(1 for a, b in pairs if abs(a - b) <= 1e-8)
print(f"roots in shipped testout {len(ref)}, in run {len(got)}, compared {len(pairs)}, within 1e-8 {within}, max abs diff {max(abs(a-b) for a,b in pairs):.3e}")
