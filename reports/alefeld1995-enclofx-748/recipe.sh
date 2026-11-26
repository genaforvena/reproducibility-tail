#!/usr/bin/env bash
# Rebuilds the rerun verdict for alefeld1995-enclofx-748 (TOMS 748, ENCLOFX, Fortran 77).
# Fetch (the only network step, in the sandbox): netlib TOMS 748.gz (sha256 checked), split into its five
# members with impl/split_748.py, gfortran from conda-forge via micromamba into the sandbox scratch.
# exdrive.f is the algorithm's separate standalone example program (its own MAIN, INIT and FUNC) and is NOT linked with driver.f; the shipped testout is the driver.f run. Everything else runs through tools/sandbox.sh.
# UNCHANGED (basis: original). Claim: NPROB=1, N=1, ROOT 1.8954942670340 (shipped testout), tol_abs 1e-8.
set -uo pipefail
ID=alefeld1995-enclofx-748
URL=https://netlib.org/toms/748.gz
SHA=d82ccafd0407e2bd3cdf89347d968348d02b070da7f46e793436500629f5ac92
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran

echo "== fetch: 748.gz (sha256 checked), split into members, micromamba gfortran (conda-forge) into the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; curl -fsSL -o 748.gz '$URL'; echo '$SHA  748.gz' | sha256sum -c -; gunzip -kf 748.gz; \
  rm -rf /work/pre; mkdir -p /work/pre/parts; \
  cd /work; mkdir -p bin; curl -fsSL -o mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf mm.tar.bz2 -C bin --strip-components=1 bin/micromamba; \
  MAMBA_ROOT_PREFIX=/work/mamba ./bin/micromamba create -y -q -p /work/fortran -c conda-forge 'gfortran_linux-64=16.2.0'" || { echo "FETCH-FAILED"; exit 1; }
cat "$here/impl/split_748.py" | tools/sandbox.sh "$ID" -- sh -c "cat > /work/split_748.py"
cat "$here/impl/extract_value.py" | tools/sandbox.sh "$ID" -- sh -c "cat > /work/extract_value.py"
tools/sandbox.sh "$ID" -- sh -c "cd /work && python3 -I /work/split_748.py /work/748 /work/pre/parts" || { echo "UNPACK-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- test -f /work/pre/parts/driver.f || { echo "UNPACK-FAILED"; exit 1; }

echo "== shipped members (archive and member hashes)"
tools/sandbox.sh "$ID" -- sh -c "sha256sum /work/748.gz /work/pre/parts/driver.f /work/pre/parts/enclofx.f /work/pre/parts/exdrive.f /work/pre/parts/testdata /work/pre/parts/testout" | tee "$E/reference/sources.sha256"
tools/sandbox.sh "$ID" -- cat /work/pre/parts/testout > "$E/reference/testout"
tools/sandbox.sh "$ID" -- cat /work/pre/parts/testdata > "$E/reference/testdata"

ORIG="$E/original-attempt.log"
echo "== G1 original attempt: authors' sources as shipped, no patch (kept once)"
if [ ! -s "$ORIG" ]; then
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && mkdir /work/g1 && cd /work/g1 && cp /work/pre/parts/driver.f /work/pre/parts/enclofx.f . && $G -O2 -o enclofx driver.f enclofx.f; echo compile_exit=\$?; timeout 600 ./enclofx < /work/pre/parts/testdata > stdout.txt 2> stderr.txt; echo run_exit=\$?; cat stdout.txt | head -6" > "$ORIG" 2>&1
fi
cat "$ORIG"

for pass in run1 run2; do
  if [ "$pass" = run1 ]; then OPT=-O2; else OPT=-O0; fi
  echo "== $pass: clean directory, $OPT build of the authors' sources, full testdata list"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cd /work/$pass && cp /work/pre/parts/driver.f /work/pre/parts/enclofx.f . && $G $OPT -o enclofx driver.f enclofx.f && timeout 900 ./enclofx < /work/pre/parts/testdata > stdout.txt 2>stderr.txt; echo ${pass}_exit=\$?; cp stdout.txt /work/$pass-stdout.txt; cat stderr.txt | head -5"
  tools/sandbox.sh "$ID" -- cat /work/$pass-stdout.txt > "$E/$pass-stdout.txt"
  python3 -I "$here/impl/extract_value.py" "$E/$pass-stdout.txt" > "$E/$pass-value.txt"
  python3 -I "$here/impl/compare_roots.py" "$E/reference/testout" "$E/$pass-stdout.txt" | sed "s/^/$pass: /"
done

echo "VALUE NPROB=1, N=1, ROOT $(cat "$E/run2-value.txt")"
echo "== run1 and run2 values"
paste "$E/run1-value.txt" "$E/run2-value.txt"
