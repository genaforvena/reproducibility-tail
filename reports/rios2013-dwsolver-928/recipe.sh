#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for rios2013-dwsolver-928 (TOMS 928, DWSOLVER, Dantzig-Wolfe decomposition, C with
# pthreads and a bundled GLPK 4.44). Registered claim: the final master objective of the book_test example is -36.666667
# (tol_abs 1e-5), as printed in the shipped Doc/exampleOutput.pdf. Everything that runs the authors' code goes through
# tools/sandbox.sh. Source: netlib TOMS 928.zip (sha256 checked).
#
# Basis: patched. The authors' tree as shipped does not configure (archive layout: C/Src/src, configure expects C/src).
# Build layout and flags only (impl/build-rios.sh, pat): a symlink, -I for config.h, -fcommon, and the same gcc link
# in place of the missing libtool wrapper. No source file is edited.
set -uo pipefail
ID=rios2013-dwsolver-928
URL=https://netlib.org/toms/928.zip
SHA=703ed2c2fd8c665b7e1552727cbfaf5f77dcaaac440b5ba6189622e7639b4dca
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1
cp "$here/impl/build-rios.sh" "$SCR/"

echo "== fetch: 928.zip (sha256 checked) and unzip into /work/src"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o 928.zip '$URL'; echo '$SHA  /work/928.zip' | sha256sum -c -; rm -rf /work/src && mkdir -p /work/src && cd /work/src && unzip -q /work/928.zip" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the authors' tree as shipped, ./configure and make"
tools/sandbox.sh "$ID" -- sh /work/build-rios.sh orig > "$E/original-build.txt" 2>&1
cat "$E/original-build.txt"
tools/sandbox.sh "$ID" -- sh -c 'tail -20 /work/configure-orig.log; echo ----; tail -20 /work/make-orig.log' > "$E/original-build-tail.txt" 2>&1

echo "== patched build (build layout and flags only, see impl/build-rios.sh)"
tools/sandbox.sh "$ID" -- sh /work/build-rios.sh pat | tee "$E/patched-build.txt"

echo "== run (pass 1, pass 2): dwsolver -g book_test from a fresh copy of Examples/book_dantzig each time"
for p in 1 2; do
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run$p && mkdir -p /work/run$p && cp /work/pat/Examples/book_dantzig/* /work/run$p/ && cd /work/run$p && timeout 600 /work/dwsolver -g book_test > run.log 2>&1; echo \"EXIT \$?\"; grep 'Master objective value' run.log | tail -1; cp run.log /work/run$p.log" > "$E/run-pass$p.log" 2>&1
  n=$(sed -n 's/.*Master objective value = \([-0-9.e+]*\).*/\1/p' "$E/run-pass$p.log" | tail -1)
  echo "pass $p: final master objective = ${n:-NONE}"
  echo "VALUE final_master_objective ${n:-NaN}"
done
