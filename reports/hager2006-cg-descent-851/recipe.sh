#!/usr/bin/env bash
# Rebuilds the rerun verdict for hager2006-cg-descent-851 (TOMS 851, CG_DESCENT, Fortran 77).
# Fetch (the only network step, inside the sandbox): netlib TOMS 851.zip (sha256 checked), unzipped into /work/pre
# (851/Fortran/Dp/Src/src.f, 851/Fortran/Dp/Drivers/driver1.f, data1, res1); gfortran from conda-forge (micromamba)
# into the sandbox scratch at /work/fortran. Everything else runs through tools/sandbox.sh.
# Original attempt (G1, and the verdict's basis): the User's Guide example as documented in driver1.f's header
# ("Compile src.f with driver1.f with gfortran and run it"): gfortran -O0 driver1.f src.f, cp data1 cg.parm, run
# driver1 < data1. It builds and runs with no change (outcome succeeded). Log: evidence/original-attempt.log.
# Claim: the three integer counters the driver prints for the 100-variable separable problem: cg iterations 32,
# function evaluations 55, gradient evaluations 45, compared exactly with the shipped res1 (tolerance 0).
# The shipped Makefile (Doc/Makefile) is not used: its rules expect src.f in the driver directory, which the archive
# does not provide; the documented compile line in driver1.f is the authors' route that runs.
# Two passes (G3): pass 1 is the original attempt's build at -O0; pass 2 is -O2 in a clean directory.
set -uo pipefail
ID=hager2006-cg-descent-851
URL=https://netlib.org/toms/851.zip
SHA=0ac7f494b814e7c7cb5eb13d8b5b2d569ed7c9d575486614a6f6dc7b681f4e95
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 851.zip (sha256 checked), unzipped into /work/pre; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/851.zip '$URL'; echo '$SHA  /work/851.zip' | sha256sum -c -; unzip -q /work/851.zip; test -f 851/Fortran/Dp/Drivers/driver1.f; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: res1, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/851/Fortran/Dp/Drivers/res1 > "$E/reference/res1"
grep -m1 "cg iterations" "$E/reference/res1"

echo "== original attempt (G1, basis): the documented compile line, pass 1 at -O0, run as documented"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/851/Fortran/Dp /work/g1 && cd /work/g1/Drivers && $G -O0 -o driver1 driver1.f ../Src/src.f; echo build_exit=\$?; cp data1 cg.parm && ./driver1 < data1 > res1.out; echo run_exit=\$?; cat res1.out" > "$E/original-attempt.log" 2>&1
grep -E '^(build_exit|run_exit)=' "$E/original-attempt.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/g1/Drivers/res1.out" > "$E/pass1-output.txt"

echo "== pass 2 (gfortran, -O2, clean directory)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && cp -r /work/pre/851/Fortran/Dp /work/pass2 && cd /work/pass2/Drivers && $G -O2 -o driver1 driver1.f ../Src/src.f && cp data1 cg.parm && ./driver1 < data1 > res1.out; echo run_exit=\$?; cat res1.out" > "$E/pass2-run.log" 2>&1
grep -E '^run_exit=' "$E/pass2-run.log" || echo "pass2: run did not finish"
tools/sandbox.sh "$ID" -- sh -c "cat /work/pass2/Drivers/res1.out" > "$E/pass2-output.txt"

echo "== values: the three counters, from each pass"
for p in pass1 pass2; do
  for k in "cg iterations" "function evaluations" "gradient evaluations"; do
    awk -v k="$k" 'index($0,k":")>0{print $NF; exit}' "$E/$p-output.txt" > "$E/$p-$(echo $k | tr ' ' '-').txt"
  done
done
echo "VALUE driver1 cg iterations $(cat "$E/pass1-cg-iterations.txt")"
echo "VALUE driver1 function evaluations $(cat "$E/pass1-function-evaluations.txt")"
echo "VALUE driver1 gradient evaluations $(cat "$E/pass1-gradient-evaluations.txt")"
echo "PASS2 VALUE driver1 cg iterations $(cat "$E/pass2-cg-iterations.txt")"
echo "PASS2 VALUE driver1 function evaluations $(cat "$E/pass2-function-evaluations.txt")"
echo "PASS2 VALUE driver1 gradient evaluations $(cat "$E/pass2-gradient-evaluations.txt")"
