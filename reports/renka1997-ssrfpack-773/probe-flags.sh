#!/usr/bin/env bash
# Diagnosis probe (not part of the verdict): which gfortran flag changes FF(16,16) of the shipped SSRFTEST run.
# Rebuilds the unmodified sources from the sha-checked 773/772 archives (fetched by recipe.sh into /work/tree)
# with each flag set, runs SSRFTEST in a fresh directory and prints the RES line-562 value.
set -uo pipefail
ID=renka1997-ssrfpack-773
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
mkdir -p "$E"
cd "$root"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH; for o in "-O1" "-O0" "-O2" "-O2 -fno-tree-vectorize" "-O2 -ffloat-store" "-O2 -ffp-contract=off"; do d="/work/probe/$(echo "$o" | tr -d " -")"; rm -rf "$d"; mkdir -p "$d/r" && cd "$d" && gfortran $o -c /work/tree/772/Fortran77/Src/Sp/src.f -o s.o && gfortran $o -c /work/tree/773/Src/Sp/src.f -o f.o && gfortran $o /work/tree/773/Drivers/Sp/driver.f s.o f.o -o t && cd r && cp /work/tree/773/Drivers/Sp/data . && ../t >/dev/null 2>&1; echo "$o : $(sed -n 562p RES | tr -d " ")"; cd /work; done' > "$E/probe-flags.txt" 2>&1
cat "$E/probe-flags.txt"
