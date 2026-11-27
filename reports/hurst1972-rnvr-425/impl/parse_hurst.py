#!/usr/bin/env python3
"""Print the TEST02 values of TOMS 425's driver output as 'VALUE <name> <number>' lines.

TEST02 prints a 2x2 covariance table (two rows of two numbers) and then 10 data rows of two numbers.
Only the 10 rows after the covariance table are data. Numbers are printed as the driver wrote them.
Usage: parse_hurst.py STDOUT
"""
import sys


def is_number(token):
    try:
        float(token)
        return True
    except ValueError:
        return False


lines = open(sys.argv[1]).read().splitlines()
start = next(i for i, l in enumerate(lines) if l.strip() == "TEST02")
end = next(i for i in range(start + 1, len(lines)) if lines[i].strip() == "TEST03")
rows = [l.split() for l in lines[start:end] if len(l.split()) == 2 and all(is_number(t) for t in l.split())]
data = rows[-10:]
if len(data) != 10:
    sys.exit("expected 10 data rows, found %d" % len(data))
for s, (a, b) in enumerate(data, 1):
    print("VALUE TEST02 sample %d component 1 %s" % (s, a))
    print("VALUE TEST02 sample %d component 2 %s" % (s, b))
