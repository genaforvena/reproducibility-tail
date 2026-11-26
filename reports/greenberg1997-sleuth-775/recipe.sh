#!/usr/bin/env bash
# Rebuilds the rerun verdict for greenberg1997-sleuth-775 (TOMS 775, SLEUTH, Fortran 77).
# Fetch (the only network step, in the sandbox): netlib TOMS 775.gz (sha256 checked), unshar with sh,
# gfortran from conda-forge via micromamba into the sandbox scratch. Everything else runs through tools/sandbox.sh.
# The authors' driver.f and src.f are compiled UNCHANGED; the archive lacks the NAG routines they call
# (F06YAF F06PAF F06QFF F06QHF X01AAF X02AJF P01ABF C05AZF) and DTIME. impl/nag_shims.f supplies them
# (basis: reimplemented). Claim: ELAM, problem 1 (BETA=10) eigenvalue index 2, 4871.3813012287, tol 1e-3.
set -uo pipefail
ID=greenberg1997-sleuth-775
URL=https://netlib.org/toms/775.gz
SHA=193a6050951da6a0619b5299c9f5ebb56f72b0b763369dcebc1fe071d74c8c0c
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran

echo "== fetch: 775.gz (sha256 checked), unshar with sh, micromamba gfortran (conda-forge) into the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; curl -fsSL -o 775.gz '$URL'; echo '$SHA  775.gz' | sha256sum -c -; gunzip -kf 775.gz; \
  rm -rf /work/pre; mkdir -p /work/pre && cd /work/pre && n=\$(grep -n '^#! /bin/sh' /work/775 | head -1 | cut -d: -f1); tail -n +\$n /work/775 > /work/775.sh && sh /work/775.sh; \
  cd /work; mkdir -p bin; curl -fsSL -o mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf mm.tar.bz2 -C bin --strip-components=1 bin/micromamba; \
  MAMBA_ROOT_PREFIX=/work/mamba ./bin/micromamba create -y -q -p /work/fortran -c conda-forge 'gfortran_linux-64=16.2.0'" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- test -f /work/pre/Src/Dp/src.f || { echo "UNPACK-FAILED"; exit 1; }

echo "== shipped sources (registered archive and member hashes)"
tools/sandbox.sh "$ID" -- sh -c "sha256sum /work/775 /work/pre/Driver/Dp/driver.f /work/pre/Src/Dp/src.f" | tee "$E/reference/sources.sha256"

ORIG="$E/original-attempt.log"
echo "== G1 original attempt: authors' sources as shipped, no shims (kept once)"
if [ ! -s "$ORIG" ]; then
  tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/g1 && cd /work/g1 && $G -O2 -o sleuth /work/pre/Driver/Dp/driver.f /work/pre/Src/Dp/src.f; echo compile_exit=\$?" > "$ORIG" 2>&1
fi
tail -1 "$ORIG"

echo "== impl: NAG stand-ins and DTIME, written to the sandbox as a separate file (no authors' file edited)"
for pass in run1 run2; do
  if [ "$pass" = run1 ]; then OPT=-O2; else OPT=-O0; fi
  cat "$here/impl/nag_shims.f" | tools/sandbox.sh "$ID" -- sh -c "cat > /work/nag_shims.f"
  echo "== $pass: clean directory, $OPT build of the authors' driver.f and src.f plus nag_shims.f"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cd /work/$pass && cp /work/pre/Driver/Dp/driver.f /work/pre/Src/Dp/src.f /work/nag_shims.f . && $G $OPT -o sleuth driver.f src.f nag_shims.f && timeout 900 ./sleuth > stdout.txt 2>stderr.txt; echo ${pass}_exit=\$?; cp fort.7 /work/$pass-fort7; cp stdout.txt /work/$pass-stdout.txt"
  tools/sandbox.sh "$ID" -- cat /work/$pass-fort7 > "$E/$pass-fort7.txt"
  tools/sandbox.sh "$ID" -- cat /work/$pass-stdout.txt > "$E/$pass-stdout.txt"
  python3 -I "$here/impl/extract_value.py" "$E/$pass-fort7.txt" > "$E/$pass-value.txt"
done

echo "VALUE problem 1 (BETA=10), eigenvalue index 2, ELAM $(cat "$E/run2-value.txt")"
echo "== run1 and run2 values"
paste "$E/run1-value.txt" "$E/run2-value.txt"
