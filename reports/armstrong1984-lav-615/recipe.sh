#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for armstrong1984-lav-615 (TOMS 615, SUBL1: best-subset least absolute
# value regression, Fortran 77 style, double precision not required). Everything that runs the authors' code goes
# through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 615.gz, sha256 checked against the value below,
# then gunzip. The archive is NOT a shell archive: it is the program SUBL1 and its subroutines (lines 1-1701 of
# 615), the BLISS p.294 data block as TAPE5 input (lines 1702-1781), and the shipped sample run output (1782-end).
# gfortran 16 from conda-forge via micromamba into /work/env16 when missing.
# Original attempt (G1): the file as delivered does not compile (the data and output follow the END). Log kept.
# Patch (extraction): lines 1-1701 are copied to /work/tree/subl1.f (one verbatim range, no statement changed).
# Build: the authors' statements are compiled unmodified; the program's own DOUBLE PRECISION FUNCTION D1MACH (line 1201
# of the archive) is used. The only compiler flags are -fdefault-real-8 -fdefault-double-8: the file is the DOUBLE
# PRECISION version (its header says so; the REAL lines are commented 'C++'), but the caller at line 316 types D1MACH
# implicitly REAL, which gfortran rejects (Return type mismatch). Basis: patched (extraction + build flags).
# Claim: SUM OF ABSOLUTE VALUES for LAV SUBSET OF SIZE=3, DL1BL3, shipped value 3.877, tol_abs 1e-3.
set -uo pipefail
ID=armstrong1984-lav-615
URL=https://netlib.org/toms/615.gz
SHA=96a1bdcc048a50dd6043028fef594c19f7dcf350559ef77c1e49b0018a7ff832
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 615.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o /work/615.gz '$URL'; echo '$SHA  /work/615.gz' | sha256sum -c -; gunzip -kf /work/615.gz; \
  test -x /work/bin/micromamba || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran make; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt" || { echo "FETCH-FAILED"; exit 1; }
cp "$SCR/gfortran-version.txt" "$E/"

echo "== unpack: the archive is copied, not parsed (it is plain text, not a shell archive)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir -p /work/tree && cp /work/615 /work/tree/615" || { echo "UNPACK-FAILED"; exit 1; }
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
cp "$SCR/tree/615" "$E/archive-615.txt"
sed -n '1782,1817p' "$E/archive-615.txt" > "$E/shipped-sample-output.txt"

echo "== G1 original attempt: the authors' file as delivered (before any patch)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && \
  cp /work/tree/615 /work/orig/615.f && gfortran -O2 -c /work/orig/615.f -o orig.o; echo compile_exit=$?' > "$E/original-attempt-compile.log" 2>&1
tail -1 "$E/original-attempt-compile.log"

echo "== manifest pre (right after unpack, before any patch)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step (extraction): lines 1-1701 of the archive file to subl1.f; data and output are not source"
tools/sandbox.sh "$ID" -- sh -c "sed -n '1,1701p' /work/tree/615 > /work/tree/subl1.f" || exit 1
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== pass 1 build: gfortran 16 -O2 (the build commands)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build1 && mkdir -p /work/build1 && cd /work/build1 && \
  gfortran -O2 -fdefault-real-8 -fdefault-double-8 -c /work/tree/subl1.f -o subl1.o && \
  gfortran -O2 subl1.o -o subl1 && echo build_exit=$?' > "$E/pass1-build.log" 2>&1
tail -1 "$E/pass1-build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

echo "== pass 1 run: TAPE5 = archive lines 1702-1781 (the data block, cut from the archive each run)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && sed -n "1702,1781p" /work/tree/615 > data && \
  timeout 120 /work/build1/subl1 < data > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/pass1-stdout.txt" 2> "$E/pass1-run.log"
tail -1 "$E/pass1-run.log"

echo "== pass 2: clean rebuild at -O0 and rerun (second pass, different optimization)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build2 && mkdir -p /work/build2 && cd /work/build2 && \
  gfortran -O0 -fdefault-real-8 -fdefault-double-8 -c /work/tree/subl1.f -o subl1.o && gfortran -O0 subl1.o -o subl1 && echo build_exit=$? && \
  rm -rf /work/run2 && mkdir -p /work/run2 && cd /work/run2 && sed -n "1702,1781p" /work/tree/615 > data && \
  timeout 120 /work/build2/subl1 < data > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/pass2-stdout.txt" 2> "$E/pass2-run.log"
tail -1 "$E/pass2-run.log"

# The value: the SUM OF ABSOLUTE VALUES line that follows 'SUBSET OF SIZE=  3' in the printed output.
val() { awk '/BEST RESULTS FOR LAV SUBSET OF SIZE= *3/{f=1} f && /SUM OF ABSOLUTE VALUES/{print $NF; exit}' "$1" 2>/dev/null; }
echo "PASS2 (-O0) SUM3 $(val "$E/pass2-stdout.txt")"
echo "VALUE SUM_ABS_SIZE3 $(val "$E/pass1-stdout.txt")"
