#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for clemm1969-mathieu-352 (Algorithm 352, Mathieu characteristic values, Clemm 1969).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 352.gz, sha256 checked, then gunzip.
# gfortran 16 from conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk (this directory) copies the text of
# each here-document body into the tree verbatim.
# Original attempt (G1): the authors' Makefile as shipped (Fortran/Dp/Drivers/Makefile) calls $(F77), which is unset
# and absent, so make fails. Log kept in evidence/original-attempt-make.log.
# Build (patched, build-only): the authors' driver.f and src.f are compiled unmodified with gfortran -O2 in a build
# directory outside the tree (/work/build). Only the compiler name changes; no source edit.
# Run: the driver takes no input and writes its tables to stdout. Each pass is bounded by timeout 120.
# Value: VALUE line prints the computed a_5(5) (even, R = 5, Q = 5) from the TEST05 table.
set -uo pipefail
ID=clemm1969-mathieu-352
URL=https://netlib.org/toms/352.gz
SHA=00efa50bee19a19e7b4e5c0475d75d72bf2ab1260a01cae65056d28a2a4b1fee
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 352.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; mkdir -p raw; \
  test -s raw/352.gz || curl -fsSL -o raw/352.gz '$URL'; echo '$SHA  raw/352.gz' | sha256sum -c - > raw/sha.txt 2>&1; \
  gunzip -kf raw/352.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/raw/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"
cp "$here/../snyder1993-fresnel-723/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the archive's directory tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/raw/352 > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && cat "$E/unpack-listing.txt"
cp "$SCR/tree/Fortran/Dp/Drivers/res" "$E/shipped-res.txt"

echo "== G1 original attempt: the authors' Makefile as shipped (no compiler variables), before any substitution"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && cp /work/tree/Fortran/Dp/Drivers/Makefile . && \
  cp /work/tree/Fortran/Dp/Drivers/driver.f /work/tree/Fortran/Dp/Src/src.f . && make 2>&1; echo make_exit=$?' > "$E/original-attempt-make.log" 2>&1
tail -1 "$E/original-attempt-make.log"

echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none in the tree (compiler name only, on the command line)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

BUILD=(
  'gfortran -O2 -c /work/tree/Fortran/Dp/Drivers/driver.f -o driver.o'
  'gfortran -O2 -c /work/tree/Fortran/Dp/Src/src.f -o src.o'
  'gfortran -O2 -o driver driver.o src.o'
)
echo "== build pass: gfortran -O2 on the authors' driver and src (3 commands)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  for c in "$@"; do sh -c "$c" || exit 1; done; echo build_exit=$?' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" \
  --command 'gfortran -O2 -c /work/tree/Fortran/Dp/Drivers/driver.f -o driver.o' \
  --command 'gfortran -O2 -c /work/tree/Fortran/Dp/Src/src.f -o src.o' \
  --command 'gfortran -O2 -o driver driver.o src.o' || echo "record_exit=$?"

echo "== run pass 1: timeout 120, stdout is the driver's tables"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && \
  timeout 120 /work/build/driver > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"
echo "== run pass 2: fresh run directory, same built binary"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run2 && mkdir -p /work/run2 && cd /work/run2 && \
  timeout 120 /work/build/driver > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/run-pass2.txt" 2> "$E/run-pass2.log"
tail -1 "$E/run-pass2.log"

# Observed value: the TEST05 row with R = 5 and Q = 5; the Computed column is the fourth field.
val() { awk '$1==5 && $2==5 && $4 ~ /^[0-9.]+$/ {print $4; exit}' "$1"; }
echo "OBSERVED pass1 a_5(5) $(val "$E/run-pass1.txt")"
echo "OBSERVED pass2 a_5(5) $(val "$E/run-pass2.txt")"
echo "VALUE a_5(5) (even) $(val "$E/run-pass1.txt")"
