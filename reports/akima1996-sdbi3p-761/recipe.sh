#!/usr/bin/env bash
# Rebuilds the rerun verdict for akima1996-sdbi3p-761 (basis decided by the original attempt below).
# Fetch (the only network step, inside the sandbox): netlib TOMS 761.gz (sha256 checked), micromamba and gfortran
# from conda-forge into the sandbox scratch. Everything else runs through tools/sandbox.sh.
# The archive is a shell archive with leading text: the lines from '#! /bin/sh' on are the shar; they are
# stripped to a file and run with sh. Unpacked: Drivers/Sp/{driver.f,res}, Src/Sp/{src.f,tripack.f}.
# The driver reads no input and writes its output to a file named res in its current directory, so the
# build and run happen in a scratch directory (never inside the shipped source tree, which holds the shipped res).
# Claim: ZI1(XI,YI) for six registered grid points, against the paper values printed by the shipped res, tol 0.011.
# G1 original attempt: driver.f + src.f + tripack.f compiled with gfortran as shipped, no source change (log kept once).
# Second pass (G3): a clean directory and a -O0 rebuild.
set -uo pipefail
ID=akima1996-sdbi3p-761
URL=https://netlib.org/toms/761.gz
SHA=373f95242dde88c78e9fb708287e4520e413094fdff9127e1b317b3960c2497f
REFSHA=ceb003ed2ce4a6659e016d8879ad34e6528c6bbec93577e4c6633371664ca8df
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
S=/work/src/Src/Sp
D=/work/src/Drivers/Sp

echo "== fetch: 761.gz (sha256 checked), strip to shar, unshar, micromamba, gfortran (conda-forge) into the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; curl -fsSL -o 761.gz '$URL'; echo '$SHA  761.gz' | sha256sum -c -; gunzip -kf 761.gz; \
  rm -rf /work/src && mkdir -p /work/src && sed -n '/^#! \/bin\/sh/,\$p' /work/761 > /work/src/761.sh && cd /work/src && sh 761.sh; \
  cd /work; curl -fsSL -o mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p bin; tar -xjf mm.tar.bz2 -C bin --strip-components=1 bin/micromamba; \
  MAMBA_ROOT_PREFIX=/work/mamba ./bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- test -f $D/driver.f -a -f $S/src.f -a -f $S/tripack.f || { echo "UNPACK-FAILED"; exit 1; }

echo "== shipped reference output (res), copied into the report"
tools/sandbox.sh "$ID" -- cat $D/res > "$E/reference/res" || { echo "REF-FAILED"; exit 1; }
grep -q "TPSD3P" "$E/reference/res" || { echo "REF-CHECK-FAILED"; exit 1; }
echo "reference sha256: $(sha256sum "$E/reference/res" | cut -d' ' -f1) (registered $REFSHA)"

# G1: the shipped sources, as they are. The first attempt's log is kept and never overwritten.
ORIG="$E/original-attempt.log"
echo "== build (G1 attempt, shipped sources, gfortran -O2, no source edit; the log is kept once and never overwritten)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run1 && mkdir /work/run1 && cp $D/driver.f /work/run1/ && cd /work/run1 && export PATH=/work/fortran/bin:\$PATH && $G -O2 -o driver driver.f $S/src.f $S/tripack.f 2>&1; echo compile_exit=\$?" > "$E/build-run1.tmp" 2>&1
if [ ! -s "$ORIG" ]; then cp "$E/build-run1.tmp" "$ORIG"; fi
tail -2 "$E/build-run1.tmp"
rm -f "$E/build-run1.tmp"

echo "== run 1: the driver built above (res written in its scratch directory)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/run1 && ./driver > /work/run1/stdout.txt 2>/work/run1/stderr.txt; echo run1_exit=\$?"
tools/sandbox.sh "$ID" -- cat /work/run1/res > "$E/run1-res.txt"

echo "== run 2: clean directory, -O0 rebuild"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && mkdir /work/pass2 && cp $D/driver.f /work/pass2/ && cd /work/pass2 && export PATH=/work/fortran/bin:\$PATH && $G -O0 -o driver driver.f $S/src.f $S/tripack.f && ./driver; echo run2_exit=\$?"
tools/sandbox.sh "$ID" -- cat /work/pass2/res > "$E/run2-res.txt"

echo "== values (VALUE lines) from pass 1 and pass 2"
python3 -I "$here/impl/extract_values.py" "$E/run1-res.txt" | tee "$E/values-run1.txt"
python3 -I "$here/impl/extract_values.py" "$E/run2-res.txt" | tee "$E/values-run2.txt"
cmp -s "$E/values-run1.txt" "$E/values-run2.txt" && echo "pass 1 and pass 2 values identical" || echo "pass 1 and pass 2 values differ"
