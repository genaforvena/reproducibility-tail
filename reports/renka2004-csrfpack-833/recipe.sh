#!/usr/bin/env bash
# Rebuilds the rerun record for renka2004-csrfpack-833 (TOMS 833, CSRFPACK: C1 convexity-preserving scattered-data
# interpolation, Fortran 77). Everything that runs the authors' code goes through tools/sandbox.sh. The host only
# hashes source files (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 833.gz (sha256 checked), gunzipped to
# /work/pre/833.shar; the shell archive is cut from its '#! /bin/sh' line into /work/pre/archive.sh; gfortran from
# conda-forge (micromamba) into /work/fortran if missing.
#
# Original attempt (G1): run the archive as shipped, with its own Makefile in Fortran77/Drivers. The Makefile starts
# with `include makefile.inc`, and the archive does not ship that file, so make stops before any compile.
# Log: evidence/original-attempt.log.
#
# Build (basis patched, build-only): no source file and no build file is edited or added. The Makefile's own two
# rules and link line are run as written, with the compiler and flags on the command line: src.f (from ../Src), driver.f,
# link driver1. Nothing in the unpacked tree changes between the pre manifest, the mid manifest and the build.
#
# Claim: F at grid node (X,Y) = (-0.948717948717949, -1.0) from the author's driver with the shipped data file, printed
# in Fortran77/Drivers/res as 0.189783809135176E+01. The registered queue value is 0.189783809135176 (no exponent),
# so the registered value and the shipped output disagree by a factor of ten. The claim is not edited here: see result.md.
# Two passes (G3): pass 1 is the verdict's build at -O; pass 2 is a clean copy at -O2.
set -uo pipefail
ID=renka2004-csrfpack-833
URL=https://netlib.org/toms/833.gz
SHA=e40e3df805baca94da32f5b9bd460abb8f03049675da6573bf1b7439819a7720
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 833.gz (sha256 checked), shell archive cut from the #! /bin/sh line; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre /work/bin && cd /work/pre && curl -fsSL -o /work/833.gz '$URL'; echo '$SHA  /work/833.gz' | sha256sum -c -; gunzip -c /work/833.gz > /work/pre/833.shar; sed -n '/^#! \/bin\/sh/,\$p' /work/pre/833.shar > /work/pre/archive.sh; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the archive as shipped, its own Makefile in Fortran77/Drivers"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cd /work/orig && sh /work/pre/archive.sh && cd Fortran77/Drivers && make; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'build_exit=|makefile.inc' "$E/original-attempt.log" | head -5

echo "== unpack: the authors' shell archive, unedited, into /work/tree (manifest pre: before any build step)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir /work/tree && cd /work/tree && sh /work/pre/archive.sh && ls Fortran77/Drivers Fortran77/Src" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== pass 1: copy the unpacked tree to the build directory (no edit), then manifest (mid)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"

echo "== pass 1 build: the Makefile's rules and link line, flags on the command line (-O)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/Fortran77/Drivers && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O -c ../Src/src.f > /work/build1.log 2>&1 && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O -c driver.f >> /work/build1.log 2>&1 && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O -o driver1 driver.o src.o >> /work/build1.log 2>&1; echo build_exit=\$?; tail -5 /work/build1.log" > "$E/pass1-build.log" 2>&1
cat "$E/pass1-build.log"

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: the Makefile's Res target, ./driver1 < data > Res"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/Fortran77/Drivers && ./driver1 < data > /work/Res1 2>/work/run1.err; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/Res1" "$E/pass1-Res.txt"

echo "== pass 2 (clean copy, gfortran -O2)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && cp -r /work/tree /work/pass2 && cd /work/pass2/Fortran77/Drivers && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O2 -c ../Src/src.f && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O2 -c driver.f && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O2 -o driver1 driver.o src.o && ./driver1 < data > /work/Res2; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/Res2" "$E/pass2-Res.txt"

echo "== values: the grid node (X,Y) = (-0.948717948717949, -1.0) from each pass, and the whole grid against the shipped res"
python3 -I - "$E/pass1-Res.txt" "$E/pass2-Res.txt" <<'PY' > "$E/values.txt" || true
import sys
def grid(path):
    out = {}
    for line in open(path):
        f = line.split()
        if len(f) != 3:
            continue
        try:
            x, y, v = (float(t) for t in f)
        except ValueError:
            continue
        out[(round(x, 12), round(y, 12))] = v
    return out
def node(g):
    return g.get((round(-0.948717948717949, 12), round(-1.0, 12)))
p1 = grid(sys.argv[1]); p2 = grid(sys.argv[2])
print("pass1 node", repr(node(p1)))
print("pass2 node", repr(node(p2)))
print("pass1 cells", len(p1), "pass2 cells", len(p2))
print("pass1 max |pass1-pass2|", max(abs(p1[k] - p2[k]) for k in p1 if k in p2))
PY
cat "$E/values.txt"
python3 -I - "$E/pass1-Res.txt" "$SCRATCH/tree/Fortran77/Drivers/res" <<'PY' > "$E/vs-shipped-res.txt" || true
import sys
def grid(path):
    out = {}
    for line in open(path):
        f = line.split()
        if len(f) != 3:
            continue
        try:
            x, y, v = (float(t) for t in f)
        except ValueError:
            continue
        out[(round(x, 12), round(y, 12))] = v
    return out
ours = grid(sys.argv[1]); shipped = grid(sys.argv[2])
common = [k for k in shipped if k in ours]
print("shipped cells", len(shipped), "matched cells", len(common))
print("max |ours - shipped res|", max(abs(ours[k] - shipped[k]) for k in common) if common else "none")
PY
cat "$E/vs-shipped-res.txt"
V=$(python3 -I - "$E/pass1-Res.txt" <<'PY'
import sys
x0, y0 = -0.948717948717949, -1.0
for line in open(sys.argv[1]):
    f = line.split()
    if len(f) != 3:
        continue
    try:
        x, y, v = (float(t) for t in f)
    except ValueError:
        continue
    if abs(x - x0) < 1e-12 and abs(y - y0) < 1e-12:
        print(repr(v))
        break
PY
)
P2=$(python3 -I - "$E/pass2-Res.txt" <<'PY'
import sys
x0, y0 = -0.948717948717949, -1.0
for line in open(sys.argv[1]):
    f = line.split()
    if len(f) != 3:
        continue
    try:
        x, y, v = (float(t) for t in f)
    except ValueError:
        continue
    if abs(x - x0) < 1e-12 and abs(y - y0) < 1e-12:
        print(repr(v))
        break
PY
)
echo "VALUE F(X=-0.948717948717949, Y=-1.0) from CSRFTEST with the shipped data file ${V:-nan}"
echo "PASS2 VALUE F(X=-0.948717948717949, Y=-1.0) from CSRFTEST with the shipped data file ${P2:-nan}"
