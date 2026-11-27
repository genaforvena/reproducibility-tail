#!/usr/bin/env python3
"""Print 'VALUE Gaussian cubature over unit cube (test01) <number>' from test01 output.

Reads the 'Cubature' line that Drivers/test01.cc prints (cout precision 17) and prints the
number exactly as the driver wrote it. Run with -I so no local module can shadow the standard library.
"""
import re
import sys

NAME = "Gaussian cubature over unit cube (test01)"
ROW = re.compile(r"^Cubature\s*=\s*([-+]?\d+\.\d+(?:[eE][-+]?\d+)?)\s*$")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract_value.py OUTPUT", file=sys.stderr)
        return 2
    with open(sys.argv[1], encoding="ascii", errors="replace") as fh:
        for line in fh:
            match = ROW.match(line.rstrip("\n"))
            if match:
                print(f"VALUE {NAME} {match.group(1)}")
                return 0
    print("no 'Cubature' line in output", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
