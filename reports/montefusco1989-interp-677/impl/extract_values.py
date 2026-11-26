# Result extractor (not part of the computation): reads the program's stdout and prints one line per claimed value:
# "VALUE <name> <number>", the ERMAX and ERMEAN the program prints as "ON YOUR COMPUTER".
# Usage: python3 -I extract_values.py PATH_TO_STDOUT
import re, sys

text = open(sys.argv[1], encoding="ascii", errors="replace").read()
mx = re.search(r"MAX ERROR ON YOUR COMPUTER\s*=\s*([-+]?\d\.\d+E[-+]\d+)", text)
mn = re.search(r"MEAN ERROR ON YOUR COMPUTER\s*=\s*([-+]?\d\.\d+E[-+]\d+)", text)
if not (mx and mn):
    sys.exit("extract_values: ERMAX/ERMEAN not found in " + sys.argv[1])
print(f"VALUE ERMAX {float(mx.group(1)):.7E}")
print(f"VALUE ERMEAN {float(mn.group(1)):.7E}")
