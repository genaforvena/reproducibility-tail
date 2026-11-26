#!/usr/bin/env bash
# Rebuilds the rerun verdict for preusser1990-c1c2-684 (TOMS 684, C1/C2 interpolation on triangles, Fortran).
# Fetch (the only network step, inside the sandbox): netlib TOMS 684.gz (sha256 checked), gunzipped into
# /work/pre/684.f (one file: the algorithm subroutines and PROGRAM DFC1C2 driver). gfortran from conda-forge
# (micromamba) into the sandbox scratch at /work/fortran if missing. Everything else runs through tools/sandbox.sh.
# Original attempt (G1, and the verdict's basis): the archive ships no Makefile or build line. The single file is
# compiled with gfortran default flags, no edit: gfortran -o dfc1c2 684.f, then ./dfc1c2 (reads no input).
# Log: evidence/original-attempt.log.
# Claim: Z(44,3) of DFC1C2, the first "COMPUTED VALUE" printed (the C2 grid value, before the driver overwrites
# Z with the C2-minus-C1 difference), compared with the author's expected constant 3.035646151154, tol_abs 1e-3.
# The second WRITE in the driver prints the difference, not the claimed quantity, and is recorded but not claimed.
# Two passes (G3): pass 1 is the original attempt at default flags; pass 2 is -O2 in a clean directory.
set -uo pipefail
ID=preusser1990-c1c2-684
URL=https://netlib.org/toms/684.gz
SHA=d7370718ce36c41ae718fe3061cad733f664427cf78736abb5a0e20e3171dbe3
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 684.gz (sha256 checked), gunzipped to /work/pre/684.f; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && curl -fsSL -o /work/684.gz '$URL'; echo '$SHA  /work/684.gz' | sha256sum -c -; python3 -I -c \"import gzip,shutil;shutil.copyfileobj(gzip.open('/work/684.gz'),open('/work/pre/684.f','wb'))\"; test -s /work/pre/684.f; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: the unedited 684.f, which holds the author's expected constant in PROGRAM DFC1C2"
tools/sandbox.sh "$ID" -- cat /work/pre/684.f > "$E/reference/684.f"
sha256sum "$E/reference/684.f"

echo "== original attempt (G1, basis): source compiled as shipped, default flags, pass 1, run"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && mkdir -p /work/g1 && cp /work/pre/684.f /work/g1/ && cd /work/g1 && $G -o dfc1c2 684.f; echo build_exit=\$?; ./dfc1c2; echo run_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E '^(build_exit|run_exit)=' "$E/original-attempt.log"
cp "$E/original-attempt.log" "$E/pass1-output.txt"

echo "== pass 2 (gfortran, -O2, clean directory)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && mkdir -p /work/pass2 && cp /work/pre/684.f /work/pass2/ && cd /work/pass2 && $G -O2 -o dfc1c2 684.f && ./dfc1c2; echo run_exit=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^run_exit=' "$E/pass2-run.log" || echo "pass2: run did not finish"
cp "$E/pass2-run.log" "$E/pass2-output.txt"

echo "== values: first COMPUTED VALUE line (the C2 grid value of Z(44,3)) from each pass"
for p in pass1 pass2; do
  grep -m1 'COMPUTED VALUE' "$E/$p-output.txt" | awk '{print $3}' > "$E/$p-value.txt"
done
echo "EXPECTED-CONSTANT $(grep -m1 'EXPECTED VALUE' "$E/pass1-output.txt" | awk '{print $3}')"
echo "VALUE Z(44,3) of DFC1C2 (default REAL build) $(cat "$E/pass1-value.txt")"
echo "PASS2 VALUE Z(44,3) of DFC1C2 (default REAL build) $(cat "$E/pass2-value.txt")"
