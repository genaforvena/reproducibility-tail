#!/usr/bin/env bash
# Rebuilds the rerun verdict for alvarez2016-vbf-s7-959 (basis: patched).
# Fetch (the only network step): CALGO 959.zip from netlib (sha256 checked). The archive bundles NTL 9.2.0
# and GMP under SupportPackages/, so nothing else is downloaded. Everything else runs through tools/sandbox.sh.
# The authors' VBF classes and ex.cpp are built and run unmodified (no edits, no new code).
# Original attempt (G1): `make ex` in CPP/Drivers as documented. It stops because the Makefile's prerequisite
# VBF.h is not in Drivers/ (it lives in CPP/Src/) and NTL is not in /usr/local. Log kept, never overwritten.
# Patch (the basis): NTL is built from the bundled support package into a scratch prefix, and the Makefile's
# compile line is run directly with the NTL prefix and -I../Src (the Makefile's rule cannot find VBF.h). No source is changed.
# Claim: the eight measures printed by ./ex.exe S7 7 plus the cycle count in S7.cy, compared with the
# shipped reference (CPP/Drivers/Res/S7/S7.out and S7.cy). Integers must match exactly.
set -uo pipefail
ID=alvarez2016-vbf-s7-959
URL=https://netlib.org/toms/959.zip
SHA=e22c4212904de71769091373d279dbaa3f605a95599fe0767ff676982ed287fd
REFOUT_SHA=719dd8e11ede83e028e295a04838024ab9a6c640b02875c9423cebadb26d253f
REFCY_SHA=cd2da89ee18697559abd1b7e1047671dc1fcf77b1bd0ab6a9ac92d856acd591d
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$root/reports/$ID/evidence/recipe-run.log}"
mkdir -p "$root/reports/$ID/evidence/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
D=/work/src/959/CPP/Drivers

echo "== fetch: 959.zip"
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/959.zip '$URL'" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "echo '$SHA  /work/959.zip' | sha256sum -c -" || { echo "SHA-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/src && python3 -I -m zipfile -e /work/959.zip /work/src" || { echo "UNZIP-FAILED"; exit 1; }

echo "== shipped reference (the oracle), copied into the report and hash-checked"
tools/sandbox.sh "$ID" -- cat /work/src/959/CPP/Drivers/Res/S7/S7.out > "$root/reports/$ID/evidence/reference/S7.out" || { echo "REF-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- cat /work/src/959/CPP/Drivers/Res/S7/S7.cy > "$root/reports/$ID/evidence/reference/S7.cy" || { echo "REF-FAILED"; exit 1; }
echo "$REFOUT_SHA  reports/$ID/evidence/reference/S7.out" | sha256sum -c - || { echo "REF-SHA-FAILED"; exit 1; }
echo "$REFCY_SHA  reports/$ID/evidence/reference/S7.cy" | sha256sum -c - || { echo "REF-SHA-FAILED"; exit 1; }

# G1: the authors' driver as documented, unpatched. The first attempt's log is kept and never overwritten.
ORIG="$root/reports/$ID/evidence/original-attempt.log"
if [ ! -s "$ORIG" ]; then
  echo "== G1 original attempt (make ex as documented, no NTL prefix, no -I../Src)"
  tools/sandbox.sh "$ID" -- sh -c "cd $D && make ex 2>&1; echo exit=\$?" > "$ORIG" 2>&1
  tail -4 "$ORIG"
fi

echo "== NTL 9.2.0 from the archive's SupportPackages into the scratch prefix"
tools/sandbox.sh "$ID" -- sh -c "cd /work/src/959/SupportPackages/ntl-9.2.0/src && ./configure PREFIX=/work/ntl && make -j2 && make install; echo exit=\$?" > "$root/reports/$ID/evidence/ntl-build.log" 2>&1
tail -2 "$root/reports/$ID/evidence/ntl-build.log"

echo "== build ex.exe with the NTL prefix and the source directory on the include path (patched build flags)"
# The Makefile's `ex` rule cannot be used: its prerequisite VBF.h is not in Drivers/ (make fails before compiling,
# see the G1 log). The same command line as the Makefile's rule is run directly, with -I../Src added.
tools/sandbox.sh "$ID" -- sh -c "cd $D && g++ -I/work/ntl/include -I../Src -L/work/ntl/lib -Wall ex.cpp -o ex.exe -lntl && ls -l ex.exe" || { echo "BUILD-FAILED"; exit 1; }

# Patched run, twice (G3): the authors' driver with its own inputs; outputs go to the scratch Drivers dir.
for i in 1 2; do
  echo "== driver run $i"
  tools/sandbox.sh "$ID" -- sh -c "cd $D && timeout 900 ./ex.exe S7 7 > /work/run$i.log 2>&1; echo exit=\$?; cp S7.cy /work/run$i-S7.cy"
  cp "$W/run$i.log" "$root/reports/$ID/evidence/run$i.log" && gzip -f "$root/reports/$ID/evidence/run$i.log"
  cp "$W/run$i-S7.cy" "$root/reports/$ID/evidence/run$i-S7.cy"
done

# G5 contract: VALUE lines come from the second driver run. Cycle count = sum of the per-length counts in S7.cy.
gz="$root/reports/$ID/evidence/run2.log.gz"
get() { zcat "$gz" | awk -v k="$1" 'index($0, k": ")==1{print $NF; exit}'; }
echo "VALUE Nonlinearity $(get 'Nonlinearity')"
echo "VALUE Algebraic_degree $(get 'Algebraic degree')"
echo "VALUE Algebraic_immunity $(get 'Algebraic immunity')"
echo "VALUE Absolute_indicator $(get 'Absolute indicator')"
echo "VALUE Sum_of_squares_indicator $(get 'Sum-of-squares indicator')"
echo "VALUE Linear_potential $(get 'Linear potential')"
echo "VALUE Differential_potential $(get 'Differential potential')"
echo "VALUE Cycles_S7_cy $(awk -F, '{s+=$2} END{print s}' "$root/reports/$ID/evidence/run2-S7.cy")"
echo "== cycle structure: run2 vs shipped S7.cy (diff must be empty)"
diff "$root/reports/$ID/evidence/run2-S7.cy" "$root/reports/$ID/evidence/reference/S7.cy" && echo "CY identical"
echo "== shipped reference S7.out vs run2 (the measures)"
diff <(grep -E '^(Nonlinearity|Algebraic|Absolute|Sum-of|Linear potential|Differential potential)' "$root/reports/$ID/evidence/reference/S7.out") \
     <(zcat "$gz" | grep -E '^(Nonlinearity|Algebraic|Absolute|Sum-of|Linear potential|Differential potential)') && echo "measures identical"
