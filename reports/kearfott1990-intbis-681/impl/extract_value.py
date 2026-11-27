# Reads the GENBIS run output (stdout of intbis) and prints the VALUE line for test problem no. 1
# (cubic-parabola): the integer after "Number of roots found:" that follows its header.
import sys
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
in_p1 = False
for ln in lines:
    s = ln.strip()
    if s.startswith("Test problem no. 1:"):
        in_p1 = True
        continue
    if in_p1 and s.startswith("Number of roots found:"):
        print("VALUE test problem 1 cubic-parabola, number of roots found %s" % s.split()[-1])
        break
    if in_p1 and s.startswith("Test problem no. 2"):
        break
else:
    print("VALUE-MISSING test problem 1", file=sys.stderr)
    sys.exit(1)
