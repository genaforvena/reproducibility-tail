#!/usr/bin/env bash
# Rebuilds the rerun verdict for wang2008-bacolr-874 (TOMS 874, BACOLR, Fortran 77).
# Fetch (the only network step, inside the sandbox): netlib TOMS 874.zip (sha256 checked), unzipped into /work/pre
# (874/Fortran/Dp/Src/src.f, blas.f; 874/Fortran/Dp/Drivers/driver1.f, res1); gfortran from conda-forge (micromamba)
# into the sandbox scratch at /work/fortran. Everything else runs through tools/sandbox.sh.
# Original attempt (G1, and the verdict's basis): the archive ships no Makefile or build line. The three sources
# the driver needs are compiled together with gfortran default flags, no edit: gfortran -o driver1 driver1.f
# ../Src/src.f ../Src/blas.f, then ./driver1 (driver1 reads no input). It builds and runs with no change
# (outcome succeeded). Log: evidence/original-attempt.log.
# Claim: UOUT(XOUT=0.91) at TOUT=1.0, KCOL=2, NINT=42, the solver's printed value in the TOUT = 1.0 block, compared
# with the shipped res1 (0.6602, tolerance 1e-3, fixed in the queue entry).
# Two passes (G3): pass 1 is the original attempt's build at default flags; pass 2 is -O2 in a clean directory.
set -uo pipefail
ID=wang2008-bacolr-874
URL=https://netlib.org/toms/874.zip
SHA=92131b07424008c41ecac9dd667412c84dd604e79cf8d58841df03db26acc58b
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 874.zip (sha256 checked), unzipped into /work/pre; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/874.zip '$URL'; echo '$SHA  /work/874.zip' | sha256sum -c -; python3 -I -c \"import zipfile; zipfile.ZipFile('/work/874.zip').extractall('/work/pre')\"; test -f 874/Fortran/Dp/Drivers/driver1.f; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: res1, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/874/Fortran/Dp/Drivers/res1 > "$E/reference/res1"
sha256sum "$E/reference/res1"

echo "== original attempt (G1, basis): sources compiled as shipped, default flags, pass 1, run"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/874/Fortran/Dp /work/g1 && cd /work/g1/Drivers && $G -o driver1 driver1.f ../Src/src.f ../Src/blas.f; echo build_exit=\$?; ./driver1 > res1.out; echo run_exit=\$?; cat res1.out" > "$E/original-attempt.log" 2>&1
grep -E '^(build_exit|run_exit)=' "$E/original-attempt.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/g1/Drivers/res1.out" > "$E/pass1-output.txt"

echo "== pass 2 (gfortran, -O2, clean directory)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && cp -r /work/pre/874/Fortran/Dp /work/pass2 && cd /work/pass2/Drivers && $G -O2 -o driver1 driver1.f ../Src/src.f ../Src/blas.f && ./driver1 > res1.out; echo run_exit=\$?; cat res1.out" > "$E/pass2-run.log" 2>&1
grep -E '^run_exit=' "$E/pass2-run.log" || echo "pass2: run did not finish"
tools/sandbox.sh "$ID" -- sh -c "cat /work/pass2/Drivers/res1.out" > "$E/pass2-output.txt"

echo "== values: UOUT at XOUT=0.91 in the TOUT=1.0 block, from each pass"
for p in pass1 pass2; do
  awk '/TOUT = 0\.10E\+01/{f=1} f && /0\.9100E\+00/{print $2; exit}' "$E/$p-output.txt" > "$E/$p-value.txt"
done
echo "VALUE UOUT(XOUT=0.91) at TOUT=1.0, KCOL=2, NINT=42 $(cat "$E/pass1-value.txt")"
echo "PASS2 VALUE UOUT(XOUT=0.91) at TOUT=1.0, KCOL=2, NINT=42 $(cat "$E/pass2-value.txt")"
