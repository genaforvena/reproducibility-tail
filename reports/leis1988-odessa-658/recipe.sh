#!/usr/bin/env bash
# Rebuilds the evidence for the blocked verdict on leis1988-odessa-658 (TOMS 658, ODESSA, Fortran 77).
# Fetch (the only network step, inside the sandbox): netlib TOMS 658.gz (sha256 checked), gunzipped to /work/658.txt;
# gfortran from conda-forge (micromamba) into the sandbox scratch at /work/fortran. Everything else runs through tools/sandbox.sh.
# Original attempt (G1): the archive as shipped, compiled with gfortran -O0. It fails: line 4469 is an unprefixed line
# of printed output (the output of the demo, not a comment), and the file holds two PROGRAM MAIN units. Log: evidence/original-attempt.log.
# Experiment (not a verdict): lines 1-4340 (the first demo and the ODESSA package) compile with -std=legacy
# -fallow-argument-mismatch (Fortran 77 argument mismatches) and run. The demo's output schedule is T = 0.0 .. 1.0; no T = 4.0 row is printed.
# Claim under test: Y(1) at T = 4.0 printed as 0.905516 in the source comments. The model is YDOT(1) = -P(1)*Y(1)**2, P(1) = 1,
# Y(1; T=0) = 1, whose exact solution is Y(1) = 1/(1+T); at T = 4.0 that is 0.2. See note-to-scout.md.
set -uo pipefail
ID=leis1988-odessa-658
URL=https://netlib.org/toms/658.gz
SHA=7a49de7ea689790c1f36fc6c9397344618b37c9d22d694d6c18b4b5951f40494
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 658.gz (sha256 checked), gunzipped to /work/658.txt; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; curl -fsSL -o 658.gz '$URL'; echo '$SHA  658.gz' | sha256sum -c -; gunzip -c 658.gz > 658.txt; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the archive as shipped"
ORIG="$E/original-attempt.log"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && mkdir /work/g1 && cp /work/658.txt /work/g1/658.f && cd /work/g1 && $G -O0 -o orig 658.f 2>&1; echo compile_exit=\$?" > "$ORIG" 2>&1
tail -1 "$ORIG"

echo "== experiment: lines 1-4340 (first demo + ODESSA package), legacy Fortran 77 flags, run"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/t1 && mkdir /work/t1 && cd /work/t1 && head -n 4340 /work/658.txt > src.f && $G -O0 -std=legacy -fallow-argument-mismatch -o odessa src.f > compile.txt 2>&1; echo compile_exit=\$?; ./odessa > stdout.txt 2>&1; echo run_exit=\$?" > "$E/experiment-build.log" 2>&1
tools/sandbox.sh "$ID" -- sh -c "cat /work/t1/compile.txt; cat /work/t1/stdout.txt" > "$E/experiment-stdout.txt" 2>&1
grep -m1 -n "^ *1.00000E+00 " "$E/experiment-stdout.txt" || true
tail -1 "$E/experiment-build.log"

# The printed reference block (source comments, lines 539-600 of the unpacked file), copied unedited.
tools/sandbox.sh "$ID" -- sed -n 539,600p /work/658.txt > "$E/reference/printed-output.txt"
