# Extracts the double-precision units the DTEST1 sample needs from the TOMS 706 listing.
# The listing is not a compilable unit: it has a makefile fragment in its text and several
# PROGRAM units (DTEST1, DTEST2, STEST1, ...), and Fortran allows one main program per file.
# This copies each needed subprogram verbatim (header through its END line) and nothing else.
# Usage: python3 -I extract.py LISTING OUT.f
import re, sys, pathlib

WANT = ["D1MACH", "DCUTRI", "DCHTRI", "DADTRI", "DRLTRI", "DTRTRI", "DTEST1", "F"]
HDR = re.compile(r"^ {6}(?:DOUBLE PRECISION\s+)?(?:FUNCTION|SUBROUTINE|PROGRAM)\s+(\w+)", re.I)
END = re.compile(r"^ {6}END\s*$", re.I)

lines = pathlib.Path(sys.argv[1]).read_text(errors="replace").splitlines(keepends=True)
out, taken = [], {}
i = 0
while i < len(lines):
    m = HDR.match(lines[i])
    if m and m.group(1).upper() in WANT and m.group(1).upper() not in taken:
        name = m.group(1).upper()
        j = i
        while not END.match(lines[j]):
            j += 1
        taken[name] = (i + 1, j + 1)
        out.append(f"C ---- extracted from listing lines {i+1}-{j+1}: {name}\n")
        out.extend(lines[i:j + 1])
        i = j + 1
        continue
    i += 1

missing = [n for n in WANT if n not in taken]
if missing:
    sys.exit(f"extract: missing units {missing}")
pathlib.Path(sys.argv[2]).write_text("".join(out))
for n in WANT:
    print(f"unit {n}: listing lines {taken[n][0]}-{taken[n][1]}")
