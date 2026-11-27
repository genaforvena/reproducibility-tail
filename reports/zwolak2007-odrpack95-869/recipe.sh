#!/usr/bin/env bash
# Rebuilds the rerun verdict for zwolak2007-odrpack95-869 (basis: original; see result.md).
# Fetch (the only network step, inside the sandbox): netlib TOMS 869.zip (sha256 checked) and gfortran
# from conda-forge via micromamba, into the sandbox scratch. Everything else runs through tools/sandbox.sh.
# Claim: BETA(1) of the explicit ODR fit in F95/Drivers/simple_example.f90, against the shipped reference
# value 1.63337057 (tol_abs 1e-6). The authors' sources are compiled unchanged (no patch, no manifests).
# Pass 1: gfortran -O2 from a fresh unpack. Pass 2: a clean directory and a -O0 rebuild.
set -uo pipefail
ID=zwolak2007-odrpack95-869
URL=https://netlib.org/toms/869.zip
SHA=404eb22d15122a6ce59959f39737cba198a3767eb1976ceb8f12b211c3a09550
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
S=/work/src/869/F95/Src
D=/work/src/869/F95/Drivers

echo "== fetch: 869.zip (sha256 checked), unzip, micromamba and gfortran (conda-forge) into the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; rm -rf /work/src /work/build1 /work/build2; mkdir -p /work/src && cd /work/src; \
  curl -fsSL -o 869.zip '$URL'; echo '$SHA  869.zip' | sha256sum -c -; unzip -q 869.zip; \
  cd /work; curl -fsSL -o mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p bin; tar -xjf mm.tar.bz2 -C bin --strip-components=1 bin/micromamba; \
  rm -rf /work/fortran; MAMBA_ROOT_PREFIX=/work/mamba ./bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- test -f $S/odr.f -a -f $S/lpkbls.f -a -f $S/real_precision.f -a -f $D/simple_example.f90 -a -x $G || { echo "UNPACK-FAILED"; exit 1; }

echo "== shipped reference output (simple_example.out), copied into the report"
tools/sandbox.sh "$ID" -- cat $D/simple_example.out > "$E/reference/simple_example.out" || { echo "REF-FAILED"; exit 1; }
sha256sum "$E/reference/simple_example.out" | tee "$E/reference/simple_example.out.sha256"

# G1: the authors' sources, as shipped. The first build log is kept and never overwritten.
ORIG="$E/original-attempt-build.log"
build_and_run() { # $1 = pass directory, $2 = optimisation flag, $3 = output file name
  tools/sandbox.sh "$ID" -- sh -c "rm -rf $1 && mkdir $1 && cd $1 && export PATH=/work/fortran/bin:\$PATH && \
    $G -c $S/real_precision.f && $G $2 -c $S/odr.f && $G $2 -c $S/lpkbls.f && $G $2 -c $D/simple_example.f90 && \
    $G -o simple_example real_precision.o odr.o lpkbls.o simple_example.o; echo build_exit=\$?; \
    ./simple_example > run.out; echo run_exit=\$?" > "$E/$3.build.tmp" 2>&1
  tools/sandbox.sh "$ID" -- cat $1/run.out > "$E/$3"
}
# The authors' makefile passes no optimisation flag (F95OPT is empty), so the documented build uses gfortran's
# default flags. Passes 1 and 2 are that build; the -O2 run is a sensitivity observation, not the verdict.
echo "== pass 1: build the authors' sources as their makefile does (no optimisation flag, no source edit) and run"
build_and_run /work/build1 "" run-pass1.txt
if [ ! -s "$ORIG" ]; then cp "$E/run-pass1.txt.build.tmp" "$ORIG"; fi
cat "$E/run-pass1.txt.build.tmp"; rm -f "$E/run-pass1.txt.build.tmp"

echo "== pass 2: clean directory, same build, run"
build_and_run /work/build2 "" run-pass2.txt
cat "$E/run-pass2.txt.build.tmp"; rm -f "$E/run-pass2.txt.build.tmp"

echo "== values (VALUE lines) from pass 1 and pass 2"
python3 -I "$here/impl/extract_value.py" "$E/run-pass1.txt" | tee "$E/values-run1.txt"
python3 -I "$here/impl/extract_value.py" "$E/run-pass2.txt" | tee "$E/values-run2.txt"
cmp -s "$E/values-run1.txt" "$E/values-run2.txt" && echo "pass 1 and pass 2 values identical" || echo "pass 1 and pass 2 values differ"

echo "== sensitivity (not the claim, not a VALUE line): the same sources built with gfortran -O2"
build_and_run /work/build-o2 -O2 run-sensitivity-O2.txt
python3 -I "$here/impl/extract_value.py" "$E/run-sensitivity-O2.txt" | sed 's/^VALUE/SENSITIVITY -O2/'
