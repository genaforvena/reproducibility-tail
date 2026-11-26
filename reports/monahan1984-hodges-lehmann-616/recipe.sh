#!/usr/bin/env bash
# Rebuilds the rerun verdict for monahan1984-hodges-lehmann-616 (TOMS 616, Hodges-Lehmann location estimator, Fortran).
# Fetch (the only network step, inside the sandbox): netlib TOMS 616.gz (sha256 checked), gunzipped to /work/616.txt;
# micromamba and gfortran (conda-forge) into the sandbox scratch. Everything else runs through tools/sandbox.sh.
# The archive is one file: Fortran source (lines 1-354), stdin data (355-365), printed run output (366-441).
# Original attempt (G1): the whole file compiled as shipped. It fails (lines 355-441 are not Fortran). Log kept once in
# evidence/original-attempt.log (rebuilt to original-attempt-rebuild.log if the first log exists).
# Patch (basis patched): the source is lines 1-354 of the archive, unchanged; the stdin is lines 355-365, supplied as
# unit 1 (fort.1, the file gfortran opens for TAPE1=INPUT). No edit inside the source.
# Claim: the HLQEST value printed for N=9, repetition 3, first test (random input), compared with the shipped 0.545388,
# absolute tolerance 1e-6. The shipped value is the reference (copied unedited to evidence/reference).
# Two passes (G3): pass 1 compiles and runs in one clean directory; pass 2 recompiles and runs in a second clean directory.
set -uo pipefail
ID=monahan1984-hodges-lehmann-616
URL=https://netlib.org/toms/616.gz
SHA=d81e3935449161431649327e1fa3c729db01af4475ebf1c7e9f3e881d1649c99
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
mkdir -p "$E/reference"
cd "$root"
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran

echo "== fetch: 616.gz (sha256 checked), gunzipped in the sandbox scratch; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; curl -fsSL -o 616.gz '$URL'; echo '$SHA  616.gz' | sha256sum -c -; gunzip -c 616.gz > 616.txt; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: the printed run output, lines 366-441 of the archive, copied unedited"
tools/sandbox.sh "$ID" -- sed -n 366,441p /work/616.txt > "$E/reference/printed-output.txt" || { echo "REF-FAILED"; exit 1; }
wc -l < "$E/reference/printed-output.txt"

# G1 original attempt: the whole archive file compiled as shipped. Expected to fail: the data and printed output are not Fortran.
ORIG="$E/original-attempt.log"
[ -s "$ORIG" ] && ORIG="$E/original-attempt-rebuild.log"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && mkdir /work/g1 && cp /work/616.txt /work/g1/616.f && cd /work/g1 && $G -O0 -o orig 616.f 2>&1; echo compile_exit=\$?" > "$ORIG" 2>&1
tail -1 "$ORIG"

# Patched build and runs, twice (G3). Source = archive lines 1-354; stdin = lines 355-365, as fort.1.
for pass in p1 p2; do
  echo "== $pass: compile the source (lines 1-354) and run with the stdin data (lines 355-365)"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cd /work/$pass && sed -n 1,354p /work/616.txt > main.f && sed -n 355,365p /work/616.txt > fort.1 && $G -O0 -o hl main.f > compile.txt 2>&1; echo compile_exit=\$?; ./hl > stdout.txt 2> stderr.txt; echo run_exit=\$?; cp fort.3 /work/$pass-fort3.txt; cp compile.txt /work/$pass-compile.txt"
  tools/sandbox.sh "$ID" -- cat /work/$pass-fort3.txt > "$E/$pass-output.txt"
  tools/sandbox.sh "$ID" -- cat /work/$pass-compile.txt > "$E/$pass-compile.txt"
  grep -m1 "N=  9 REP  3   H-L ESTIMATOR VIA HLQEST=" "$E/$pass-output.txt" | awk '{print $NF}' > "$E/$pass-value.txt"
done

echo "== claimed values per pass"
echo "pass1 $(cat "$E/p1-value.txt")  pass2 $(cat "$E/p2-value.txt")  shipped 0.545388"
echo "VALUE H-L estimator via HLQEST, N=9 rep 3, first test (random input) $(cat "$E/p2-value.txt")"
