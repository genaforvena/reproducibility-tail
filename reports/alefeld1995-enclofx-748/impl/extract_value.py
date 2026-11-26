# Reads a driver.f stdout and prints the COMPUTED ROOT that follows
# 'PROBLEM NUMBER 1 WITH PROBLEM PARAMETER 1' (CC0 helper, rerun).
import re, sys

text = open(sys.argv[1], encoding="latin-1").read().split("\n")
for i, line in enumerate(text):
    if re.search(r"PROBLEM NUMBER\s+1\s+WITH PROBLEM PARAMETER\s+1\s*$", line):
        for later in text[i + 1:]:
            m = re.search(r"COMPUTED ROOT =\s*(\S+)", later)
            if m:
                print(m.group(1))
                sys.exit(0)
sys.exit("no value found")
