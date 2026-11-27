#!/usr/bin/env bash
# Rebuilds the rerun verdict for li2010-elrint3d-906 (basis: original; see result.md).
# Fetch (the only network step, inside the sandbox): netlib TOMS 906.zip, sha256 checked, unzipped.
# Claim: Cubature of the Gaussian over [0,1]^3 printed by Drivers/test01.cc, against the shipped
# reference output Drivers/res1 (value 0.88505988548101766, tol_abs 1e-9). The authors' C++ sources
# are compiled unchanged (no patch, no manifests). Pass 1: the Doc Makefile's flags (-Wall -Weffc++ -O3).
# Pass 2: a clean directory with no optimisation flag.
set -uo pipefail
ID=li2010-elrint3d-906
URL=https://netlib.org/toms/906.zip
SHA=6fc791c6f307eebdece7b369bd9ce2a06316c5ffe33f466c086fe3870d2d9d66
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
S=/work/src/906/C++/Src
D=/work/src/906/C++/Drivers

echo "== fetch: 906.zip (sha256 checked) and unzip into the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/src; mkdir -p /work/src && cd /work/src; \
  curl -fsSL -o 906.zip '$URL'; echo '$SHA  906.zip' | sha256sum -c -; unzip -q 906.zip" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- test -f $S/elrint3d.cc -a -f $D/test01.cc -a -f $D/res1 || { echo "UNPACK-FAILED"; exit 1; }

echo "== shipped reference output (Drivers/res1), copied into the report"
tools/sandbox.sh "$ID" -- cat $D/res1 > "$E/reference/res1" || { echo "REF-FAILED"; exit 1; }
sha256sum "$E/reference/res1" | tee "$E/reference/res1.sha256"

# G1: the authors' sources, as shipped. The first build log is kept and never overwritten.
ORIG="$E/original-attempt-build.log"
build_and_run() { # $1 = build directory, $2 = compiler flags, $3 = output file name
  tools/sandbox.sh "$ID" -- sh -c "rm -rf $1 && mkdir $1 && cd $1 && \
    g++ $2 -I$S -o test01 $S/*.cc $D/test01.cc; echo build_exit=\$?; \
    ./test01 > run.out; echo run_exit=\$?" > "$E/$3.build.tmp" 2>&1
  tools/sandbox.sh "$ID" -- cat $1/run.out > "$E/$3"
}
echo "== pass 1: build the authors' sources with the Doc Makefile's flags (no source edit) and run"
build_and_run /work/build1 "-Wall -Weffc++ -O3" run-pass1.txt
if [ ! -s "$ORIG" ]; then cp "$E/run-pass1.txt.build.tmp" "$ORIG"; fi
cat "$E/run-pass1.txt.build.tmp"; rm -f "$E/run-pass1.txt.build.tmp"

echo "== pass 2: clean directory, no optimisation flag, run"
build_and_run /work/build2 "" run-pass2.txt
cat "$E/run-pass2.txt.build.tmp"; rm -f "$E/run-pass2.txt.build.tmp"

echo "== values (VALUE lines) from pass 1 and pass 2"
python3 -I "$here/impl/extract_value.py" "$E/run-pass1.txt" | tee "$E/values-run1.txt"
python3 -I "$here/impl/extract_value.py" "$E/run-pass2.txt" | tee "$E/values-run2.txt"
cmp -s "$E/values-run1.txt" "$E/values-run2.txt" && echo "pass 1 and pass 2 values identical" || echo "pass 1 and pass 2 values differ"

echo "== comparison with the shipped reference output (res1), whole file"
cmp -s "$E/run-pass1.txt" "$E/reference/res1" && echo "pass 1 output identical to res1" || echo "pass 1 output differs from res1"
cmp -s "$E/run-pass2.txt" "$E/reference/res1" && echo "pass 2 output identical to res1" || echo "pass 2 output differs from res1"
