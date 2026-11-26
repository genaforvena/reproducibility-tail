# Reads a GKLS test001.txt (as printed by example.c) and prints the coordinates of the global minimizer:
# line 1 is x1, line 2 is x2. Reads the file named on the command line; prints nothing else.
import re
import sys

text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"number of the global minimizer is:\s*(\d+)", text)
if not m:
    sys.exit("no global minimizer line")
k = m.group(1)
p = re.search(rf"f\[{k}\] = f\(\s*(-?[\d.]+)\s+(-?[\d.]+)\)", text)
if not p:
    sys.exit("no coordinate line for minimizer " + k)
print(p.group(1))
print(p.group(2))
