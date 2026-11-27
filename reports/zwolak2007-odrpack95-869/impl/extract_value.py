#!/usr/bin/env python3
"""Print 'VALUE BETA(1) (ODR, simple example) <number>' from ODRPACK95 simple_example output.

Reads the 'Estimated BETA(J)' table printed by Drivers/simple_example.f90 and takes the
BETA column of row J = 1. Run with -I so no local module can shadow the standard library.
"""
import re
import sys

NAME = "BETA(1) (ODR, simple example)"
ROW = re.compile(r"^\s*1\s+([-+]?\d+\.\d+E[-+]\d+)\s")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract_value.py OUTPUT", file=sys.stderr)
        return 2
    with open(sys.argv[1], encoding="ascii", errors="replace") as fh:
        lines = fh.read().splitlines()
    try:
        start = next(i for i, line in enumerate(lines) if "Estimated BETA(J)" in line)
    except StopIteration:
        print("no 'Estimated BETA(J)' table in output", file=sys.stderr)
        return 1
    for line in lines[start:]:
        match = ROW.match(line)
        if match:
            print(f"VALUE {NAME} {float(match.group(1))!r}")
            return 0
    print("row J = 1 not found in the BETA table", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
