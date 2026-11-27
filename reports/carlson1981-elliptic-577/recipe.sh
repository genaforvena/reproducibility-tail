#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for carlson1981-elliptic-577 (ACM TOMS Algorithm 577, Carlson and Notis 1981, RJ).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 577.gz, sha256 checked, gunzip; gfortran 16 from
# conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is one Fortran source file (no shell archive). It is copied verbatim into /work/tree/577.f.
# Original attempt (G1): the file as shipped, compiled and linked as one program with gfortran. It holds six unnamed
# main programs (the four RC/RF/RD/RJ subroutines are followed by six test drivers), so the authors' file has no single
# executable. Log kept in evidence/original-attempt-build.log.
# Build (basis patched): NO tree file is edited (manifest pre == mid == post). The build step copies verbatim line
# ranges of the authors' file into /work/build: RC (lines 27-128) and RJ (392-536) as the library, the RJ test driver
# (805-844) as the program, and its 42 input sets (846-887) as stdin. Compiled with gfortran -O2 -std=legacy.
# Value: the driver's output row whose X,Y,Z,P are 2,3,4,5 (the file's "check value" set 22), column RJ, D-format.
set -uo pipefail
ID=carlson1981-elliptic-577
URL=https://netlib.org/toms/577.gz
SHA=61ac0a82555128503bb1c0e7ad1b1911534377e0d1bb407a794579c4d2272c0e
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 577.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/577.gz || curl -fsSL -o /work/577.gz '$URL'; echo '$SHA  /work/577.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/577.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"

echo "== unpack: the single source file into the tree (verbatim copy; no archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cp /work/577 /work/tree/577.f && wc -l /work/tree/577.f'
echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1

echo "== G1 original attempt: the file as shipped, one gfortran compile and link, no change"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && \
  echo "== gfortran -O2 -std=legacy -o as_shipped /work/tree/577.f"; gfortran -O2 -std=legacy -o as_shipped /work/tree/577.f 2>&1; echo "gfortran exit=$?"' > "$E/original-attempt-build.log" 2>&1
tail -3 "$E/original-attempt-build.log"

echo "== patch step: none to the tree (verbatim line ranges are copied into the build directory below)"
tools/sandbox.sh "$ID" -- sh -c 'cmp /work/577 /work/tree/577.f && echo "tree identical to archive member"' > "$E/patch-none.txt" 2>&1
cat "$E/patch-none.txt"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

# The build commands, exactly as the sandbox runs them (also passed to verify_sources record).
BUILD=(
  'sed -n 27,128p /work/tree/577.f > /work/build/rc_rj_lib.txt'
  'sed -n 392,536p /work/tree/577.f >> /work/build/rc_rj_lib.txt'
  'sed -n 805,844p /work/tree/577.f > /work/build/rj_driver.txt'
  'sed -n 846,887p /work/tree/577.f > /work/build/data_rj'
  'gfortran -x f77 -O2 -std=legacy -c /work/build/rc_rj_lib.txt -o /work/build/rc_rj_lib.o'
  'gfortran -O2 -std=legacy -x f77 /work/build/rj_driver.txt -x none -o /work/build/rj_driver /work/build/rc_rj_lib.o'
)
echo "== build pass (verbatim extraction of RC, RJ and the RJ driver; gfortran -O2 -std=legacy)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && \
  for c in "$@"; do sh -c "$c" || { echo "failed: $c"; exit 1; }; done; echo build_exit=0; wc -l /work/build/data_rj' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -2 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
[ -f "reports/$ID/result.json" ] || echo '{}' > "reports/$ID/result.json"
CMDS=(); for c in "${BUILD[@]}"; do CMDS+=(--command "$c"); done
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" "${CMDS[@]}"; echo "record_exit=$? (2 = source patch before build: full G2 check applies)"

echo "== run pass 1: rj_driver fed the 42 input sets on stdin; timeout 300"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && \
  timeout 300 /work/build/rj_driver < /work/build/data_rj > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt; echo "== stderr"; cat stderr.txt' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"
grep -n "run_exit" "$E/run-pass1.txt"

# Observed value: the output row whose X,Y,Z,P are 2,3,4,5 (set 22), column RJ, D-format converted to a number.
val() { awk '{ if (NF>=6) { a=$2; b=$3; c=$4; d=$5; e=$6; gsub(/D/,"E",a); gsub(/D/,"E",b); gsub(/D/,"E",c); gsub(/D/,"E",d); gsub(/D/,"E",e);
  if (a+0==2 && b+0==3 && c+0==4 && d+0==5) { printf "%.17g\n", e+0; exit } } }' "$1"; }
echo "VALUE rj_2345 $(val "$E/run-pass1.txt")"
