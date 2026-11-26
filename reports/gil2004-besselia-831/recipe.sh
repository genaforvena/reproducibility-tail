#!/usr/bin/env bash
# Rebuilds the rerun verdict for gil2004-besselia-831 (TOMS 831, modified Bessel functions of imaginary order, Fortran 77).
# Fetch (the only network step, inside the sandbox): netlib TOMS 831.gz (sha256 checked), unpacked as a shell archive
# inside the sandbox scratch; micromamba and gfortran from conda-forge into the sandbox scratch. Everything else runs
# through tools/sandbox.sh.
# Original attempt (G1): the authors' Fortran 77 sources compiled exactly as shipped (Drivers/wktest.f with Src/src.f,
# Src/airy.f, Src/d1mach.f), no edits, no flags beyond -O2. The archive has no Makefile, so this is the authors'
# documented source set. Log kept once in evidence/original-attempt.log.
# Claim: WKTEST's last test (IFAC=2, scaled functions, grid X = 0.95 I, A = 0.9 J, I,J = 1..1000 step 10) prints
# "MAXIMUM VALUE OF THE WRONSKIAN CHECK = ..." (registered 6.814548925149211E-13, tol 1e-13 absolute).
# The shipped Drivers/Res is the reference (copied to evidence/reference unedited).
# The driver writes its report to TESTF.DAT (its OPEN on unit 1), not to stdout.
# Two passes (G3): run 1 is the original binary; run 2 is the same binary in a clean directory.
set -uo pipefail
ID=gil2004-besselia-831
URL=https://netlib.org/toms/831.gz
SHA=5d56edbba35b73c301c3abe6684b47dda84758b4df2dbf8f2f88cbabf49a885a
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran

echo "== fetch: 831.gz (sha256 checked), unpacked in the sandbox scratch; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; rm -rf pre; mkdir pre; curl -fsSL -o 831.gz '$URL'; echo '$SHA  831.gz' | sha256sum -c -; gunzip -kf 831.gz; \
  sed -n '/^#! \/bin\/sh/,\$p' 831 > pre/831.sh; cd pre && sh 831.sh >/dev/null 2>&1; test -f Fortran77/Drivers/wktest.f; \
  test -x /work/fortran/bin/x86_64-conda-linux-gnu-gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: Drivers/Res, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/Fortran77/Drivers/Res > "$E/reference/Res" || { echo "REF-FAILED"; exit 1; }
tail -1 "$E/reference/Res"

# G1 original attempt: the authors' sources, as shipped. The log is kept once and never overwritten.
ORIG="$E/original-attempt.log"
if [ ! -s "$ORIG" ]; then
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/Fortran77 /work/g1 && mkdir /work/g1/run && cd /work/g1 && $G -O2 -o run/wktest Drivers/wktest.f Src/src.f Src/airy.f Src/d1mach.f 2>&1; echo compile_exit=\$?" > "$ORIG" 2>&1
fi
tail -3 "$ORIG"

# Runs, twice (G3): run 1 executes the original binary in its build directory; run 2 copies it to a clean directory.
for pass in run1 run2; do
  echo "== $pass: the original binary, $( [ $pass = run1 ] && echo in the build directory || echo in a clean directory )"
  if [ $pass = run1 ]; then
    tools/sandbox.sh "$ID" -- sh -c "cd /work/g1/run && timeout 1500 ./wktest > stdout.txt 2> stderr.txt; echo ${pass}_exit=\$?; cp TESTF.DAT /work/$pass-fort1.txt; cp stdout.txt /work/$pass-stdout.txt"
  else
    tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/g1/run/wktest /work/$pass/ && cd /work/$pass && timeout 1500 ./wktest > stdout.txt 2> stderr.txt; echo ${pass}_exit=\$?; cp TESTF.DAT /work/$pass-fort1.txt; cp stdout.txt /work/$pass-stdout.txt"
  fi
  tools/sandbox.sh "$ID" -- cat /work/$pass-fort1.txt > "$E/$pass-fort1.txt" || echo "$pass: no fort.1 output"
  grep -m1 "MAXIMUM VALUE OF THE WRONSKIAN CHECK" "$E/$pass-fort1.txt" | awk '{print $NF}' > "$E/$pass-value.txt"
done

echo "== claimed value per pass"
paste "$E/run1-value.txt" "$E/run2-value.txt"
echo "VALUE WKTEST Wronskian maximum, IFAC=2 (shipped Res) $(cat "$E/run2-value.txt")"
