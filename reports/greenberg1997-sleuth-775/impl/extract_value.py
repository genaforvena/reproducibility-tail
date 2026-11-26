#!/usr/bin/env python3
"""Print the ELAM of problem 1 (first pass, BETA=10): the first 'Eigenvalue approximation:'
line after the 'Problem Number: 1' header in the driver's unit-7 output file."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
start = next(i for i, ln in enumerate(text) if re.match(r"\s*Problem Number:\s+1\s*$", ln))
for ln in text[start:]:
    m = re.search(r"Eigenvalue approximation:\s+([-+0-9.EeDd]+)", ln)
    if m:
        print(m.group(1).replace("D", "E").replace("d", "e"))
        break
else:
    sys.exit("no eigenvalue line after Problem Number 1")
