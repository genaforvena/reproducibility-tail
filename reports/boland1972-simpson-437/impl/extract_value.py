# Reads the driver output of TOMS 437 (Fortran/Dp/Drivers/driver.f) and prints the VALUE line
# for the TEST02 product-Simpson row at N = 10 (the registered claim).
import sys
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
in_t2 = False
for ln in lines:
    s = ln.strip()
    if s == "TEST02":
        in_t2 = True
        continue
    if in_t2 and s.startswith("10 ") and s.split()[0] == "10":
        print("VALUE TEST02 product Simpson, N=10 %s" % s.split()[1])
        break
else:
    print("VALUE-MISSING TEST02 N=10", file=sys.stderr)
    sys.exit(1)
