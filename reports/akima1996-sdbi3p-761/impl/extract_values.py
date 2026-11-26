# Result extractor (not part of the computation): reads the driver's output file `res`
# and prints one line per registered claim value: "VALUE <name> <number>".
# Usage: python3 -I extract_values.py PATH_TO_RES
# The registered values are ZI1(XI,YI) at (XI,YI) in the first table ("Calculation by points").
import re, sys

path = sys.argv[1]
text = open(path, encoding="ascii", errors="replace").read()
block = text.split("Calculation by columns")[0]
num = r"(-?\d+\.\d+)"
rows = {}
for m in re.finditer(r"^\s*(\d+\.\d+)\s+" + r"\s+".join([num] * 5) + r"\s+" + r"\s+".join([num] * 5) + r"\s*$",
                     block, re.M):
    xi = float(m.group(1))
    rows[xi] = [float(m.group(i)) for i in range(2, 7)]  # ZI1 values for YI = 0,5,10,15,20
yi_index = {0.0: 0, 5.0: 1, 10.0: 2, 15.0: 3, 20.0: 4}
claims = [("ZI1(XI=5, YI=5)", 5.0, 5.0), ("ZI1(XI=10, YI=10)", 10.0, 10.0),
          ("ZI1(XI=15, YI=10)", 15.0, 10.0), ("ZI1(XI=20, YI=15)", 20.0, 15.0),
          ("ZI1(XI=10, YI=15)", 10.0, 15.0), ("ZI1(XI=15, YI=5)", 15.0, 5.0)]
for name, xi, yi in claims:
    print(f"VALUE {name} {rows[xi][yi_index[yi]]:.2f}")
