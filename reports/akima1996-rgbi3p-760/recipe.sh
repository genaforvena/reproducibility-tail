#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for akima1996-rgbi3p-760 (ACM TOMS Algorithm 760, Akima 1996, RGBI3P).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 760.gz, sha256 checked, then gunzip.
# gfortran from conda-forge via micromamba into /work/env when missing (the host has no Fortran compiler).
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk (from the snyder1993 report) copies the
# text of each here-document body into the tree verbatim (driver.f, RES, src.f).
# Original attempt (G1): the authors' files as shipped, compiled with plain gfortran (default flags, no edit). The archive
# ships no Makefile or build instructions. Log kept in evidence/original-attempt-build.log.
# Build: the same three commands, run in a build directory outside the tree; no source is edited.
# Run: the driver opens unit 6 as file WFRG3P, so its tables are written to WFRG3P in the run directory (not stdout).
# Each pass is bounded by timeout 120.
# Value: the RGBI3P block, row YI = 5.00, the 9th XI column (XI = 3.50). The line is taken from the first
# "Program Check for RGBI3P ... Calculated" block, and the header is checked to read 3.50 before the value is printed.
set -uo pipefail
ID=akima1996-rgbi3p-760
URL=https://netlib.org/toms/760.gz
SHA=3f9058c03127be9d25940886425eb7fb5518356143078c2cb2c2fef32239b018
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 760.gz (sha256 checked, gunzip); gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; mkdir -p raw; \
  test -s raw/760.gz || curl -fsSL -o raw/760.gz '$URL'; echo '$SHA  raw/760.gz' | sha256sum -c - > raw/sha.txt 2>&1; \
  gunzip -kf raw/760.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; \
  /work/env/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/raw/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"
cp "$here/../snyder1993-fresnel-723/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/raw/760 > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && cat "$E/unpack-listing.txt"
cp "$SCR/tree/Drivers/Sp/RES" "$E/shipped-res.txt"

echo "== G1 original attempt: the shipped files compiled as they are, plain gfortran, before any other step"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH && rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && \
  cp /work/tree/Drivers/Sp/driver.f /work/tree/Src/Sp/src.f . && gfortran driver.f src.f -o driver 2>&1; echo build_exit=$?; \
  rm -rf /work/orig-run && mkdir -p /work/orig-run && cd /work/orig-run && timeout 120 /work/orig/driver > stdout.txt 2> stderr.txt; echo run_exit=$?; cat WFRG3P 2>/dev/null' > "$E/original-attempt-build.log" 2>&1
tail -2 "$E/original-attempt-build.log"

echo "== manifest pre (right after unpack, before any build step)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none (no source or build file is edited)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

BUILD=(
  'gfortran -c /work/tree/Drivers/Sp/driver.f -o driver.o'
  'gfortran -c /work/tree/Src/Sp/src.f -o src.o'
  'gfortran -o driver driver.o src.o'
)
echo "== build pass: plain gfortran on the shipped driver and src (3 commands)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  for c in "$@"; do sh -c "$c" || exit 1; done; echo build_exit=$?' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build; evidence only, no patch record)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
# No patch record: the shipped files compiled unmodified (basis original). The manifests above are evidence that no source changed.

echo "== run pass 1: fresh run directory, timeout 120; the tables are in WFRG3P"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && \
  timeout 120 /work/build/driver > stdout.txt 2> stderr.txt; echo run_exit=$?; cat WFRG3P' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"
echo "== run pass 2: fresh run directory, same built binary"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run2 && mkdir -p /work/run2 && cd /work/run2 && \
  timeout 120 /work/build/driver > stdout.txt 2> stderr.txt; echo run_exit=$?; cat WFRG3P' > "$E/run-pass2.txt" 2> "$E/run-pass2.log"
tail -1 "$E/run-pass2.log"

# Observed value: row YI = 5.00 of the first RGBI3P Calculated ZI block; the header field 9 must read 3.50.
val() { LC_ALL=C awk '/Program Check for RGBI3P/ && /Calculated/ {f=1; next} f && $1 ~ /^-?0?\.50$/ && $9=="3.50" {h=1; next} f && h && $1=="5.00" {print $10; exit}' "$1"; }
echo "OBSERVED pass1 ZI(3.50,5.00) $(val "$E/run-pass1.txt")"
echo "OBSERVED pass2 ZI(3.50,5.00) $(val "$E/run-pass2.txt")"
echo "VALUE ZI(3.5,5.0) (RGBI3P) $(val "$E/run-pass1.txt")"
