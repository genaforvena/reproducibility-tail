#!/usr/bin/env bash
# Rebuilds the rerun record for smith2010-fm-911 (TOMS 911, FM/ZM multiple-precision package, Fortran 95).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes sources
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 911.zip (sha256 checked), unzipped to /work/pre;
# gfortran from conda-forge (micromamba) into /work/fortran if missing.
#
# Original attempt (G1): the archive as shipped. Doc/Makefile holds the authors' build rules but reads its compiler
# from makefile.inc, which the archive does not ship, so `make` in the unedited tree stops with no compiler set.
# Log: evidence/original-attempt.log.
#
# Build (basis patched, build-only): no source file and no build file is edited. The authors' Doc/Makefile is
# staged flat with the four Fortran sources in /work/build, and make runs its own rules with the compiler and flags
# on the command line: gfortran -O3 (the flag the Makefile's makefile.inc comment names). Nothing in the unpacked
# tree changes between the pre manifest, the mid manifest and the build.
#
# Claim: the real root of x**5-3x**4+x**3-4x**2+x-6 printed by SampleFM sample 2 (500 digits), rounded to double,
# compared with the shipped SampleFM.out value, tol_abs 1e-15. Two passes (G3): pass 1 is the build at -O3,
# pass 2 is a clean build with no optimisation flags.
set -uo pipefail
ID=smith2010-fm-911
URL=https://netlib.org/toms/911.zip
SHA=7ab4881d8495c8eca2d633835827e5c14c037dd5c0d8d1ea4729facc8234065c
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 911.zip (sha256 checked), unzipped to /work/pre; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && curl -fsSL -o /work/911.zip '$URL'; echo '$SHA  /work/911.zip' | sha256sum -c -; python3 -I -c \"import zipfile;zipfile.ZipFile('/work/911.zip').extractall('/work/pre')\"; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the archive as shipped, the authors' Doc/Makefile in place"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp -r /work/pre/911 /work/orig/ && cd /work/orig/911/Doc && make; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'build_exit=|makefile.inc|No rule|F95' "$E/original-attempt.log" | head -5

echo "== unpack: the authors' tree, unedited (manifest pre: before any build step)"
tools/sandbox.sh "$ID" -- sh -c "ls /work/pre/911/Doc /work/pre/911/Fortran95/Src /work/pre/911/Fortran95/Drivers" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/pre/911" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== pass 1: copy the unpacked tree to /work/build/911 (no edit), then manifest (mid) of that copy"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && mkdir /work/build && cp -r /work/pre/911 /work/build/911 && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build/911" > "$SCRATCH/manifest.mid"

echo "== pass 1 build: the Makefile's rules, flags on the command line (-O3)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/out1 && mkdir /work/out1 && cd /work/out1 && make -f /work/build/911/Doc/Makefile VPATH=/work/build/911/Fortran95/Src:/work/build/911/Fortran95/Drivers F95=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran F95FLAGS=-O3 SampleFM > /work/build1.log 2>&1; echo build_exit=\$?; tail -5 /work/build1.log" > "$E/pass1-build.log" 2>&1
cat "$E/pass1-build.log"

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build/911" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: ./SampleFM (writes SampleFM.out in the build directory)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/out1 && ./SampleFM > /work/run1.txt 2>&1; echo run_exit=\$?; cp SampleFM.out /work/SampleFM1.out" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"

echo "== pass 2 (clean directory, gfortran with no optimisation flags)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && mkdir /work/pass2 && cd /work/pass2 && make -f /work/pre/911/Doc/Makefile VPATH=/work/pre/911/Fortran95/Src:/work/pre/911/Fortran95/Drivers F95=$G F95FLAGS= SampleFM > /work/build2.log 2>&1 && ./SampleFM > /work/run2.txt 2>&1; echo rc=\$?; cp SampleFM.out /work/SampleFM2.out" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"

echo "== copy the outputs out of the sandbox"
tools/sandbox.sh "$ID" -- sh -c "cat /work/SampleFM1.out" > "$E/pass1-SampleFM.out" 2>/dev/null
tools/sandbox.sh "$ID" -- sh -c "cat /work/SampleFM2.out" > "$E/pass2-SampleFM.out" 2>/dev/null
cp "$E/pass1-SampleFM.out" "$E/pass1-output.txt"; cp "$E/pass2-SampleFM.out" "$E/pass2-output.txt"
cp "$root/reports/$ID/evidence/reference/SampleFM.out" "$E/reference/SampleFM.out" 2>/dev/null || \
  tools/sandbox.sh "$ID" -- sh -c "cat /work/pre/911/Fortran95/Drivers/SampleFM.out" > "$E/reference/SampleFM.out"

echo "== values: the sample 2 root (500 digits) from each pass, as a double, and the shipped value"
python3 -I - "$E" <<'PY'
import os, re, sys
E = sys.argv[1]
def sample2_root(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    start = next(i for i, l in enumerate(lines) if "Sample 2." in l)
    digits = []
    for l in lines[start + 1:]:
        s = l.strip()
        if not s:
            if digits:
                break
            continue
        if re.fullmatch(r"[0-9.]+", s):
            digits.append(s)
    return "".join(digits)
for name, path in (("pass1", os.path.join(E, "pass1-output.txt")), ("pass2", os.path.join(E, "pass2-output.txt")),
                   ("reference", os.path.join(E, "reference", "SampleFM.out"))):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        print(f"{name}: no output"); continue
    s = sample2_root(path)
    print(f"{name} digits={len(s)} first80={s[:82]}")
    print(f"{name} as double {float(s):.17g}")
PY
python3 -I - "$E" <<'PY' > "$E/values.txt"
import os, re, sys
E = sys.argv[1]
def sample2_root(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    start = next(i for i, l in enumerate(lines) if "Sample 2." in l)
    digits = []
    for l in lines[start + 1:]:
        s = l.strip()
        if not s:
            if digits:
                break
            continue
        if re.fullmatch(r"[0-9.]+", s):
            digits.append(s)
    return "".join(digits)
print("VALUE real root of x**5-3x**4+x**3-4x**2+x-6 (SampleFM.out sample 2, 500-digit value rounded to double; the first 16 significant digits are 3.120656215326726) %.17g" % float(sample2_root(os.path.join(E, "pass1-output.txt"))))
PY
cat "$E/values.txt"
