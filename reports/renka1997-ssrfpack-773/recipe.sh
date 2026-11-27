#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for renka1997-ssrfpack-773 (TOMS 773, SSRFPACK: interpolation of scattered
# data on the sphere with a surface under tension; Fortran 77, single precision REAL).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only reads text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 773.gz (sha256 checked against the queue entry)
# and TOMS 772.gz (STRIPACK, needed to link, as the driver's header says), both shell archives unpacked with sh
# into /work/tree; gfortran and make (conda-forge, via micromamba) into /work/env if missing.
#
# Build (G1): the archive ships no build file. The driver header says "must be linked to STRIPACK and SSRFPACK".
# No source file is edited; the compile lines are ours: gfortran -O2, each source compiled separately, then linked.
# Run: SSRFTEST as shipped (MFLAG=1 INTRC1 with GRADL, VT=TRUE, SCALE=TRUE, 33 nodes in Drivers/Sp/data).
# The driver opens 'data' in the working directory and writes 'RES' (STATUS='NEW'), so each run uses an empty
# directory that holds only a copy of data. The shipped Drivers/Sp/RES is NOT used as input or oracle.
#
# Claim: FF(16,16) of the SSRFTEST output grid, i.e. line 562 of RES (header 2 lines, 32 PLAT, 32 PLON, then FF
# from line 67, K = 496). Paper value 0.4441613 (shipped reference output), tol_abs 1e-6 (queue entry, fixed before any run).
# Fourth pass: the default -O2 build with a different gfortran (conda-forge gfortran 13 in /work/env13, a second
# environment for the not-reproduced verdict). Passes: pass 1 gfortran -O2 (the default build, the value VALUE reports); pass 2 the same -O2 build repeated
# from scratch (G3); pass 3 gfortran -O0 (a different environment). Each pass is a clean rebuild in its own
# directory and runs in its own working directory.
set -uo pipefail
ID=renka1997-ssrfpack-773
URL773=https://netlib.org/toms/773.gz
SHA773=410dc35305f8f08c27f318bcf459e572c52daef78b8470ed4b8288ba85bd1807
URL772=https://netlib.org/toms/772.gz
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
PATHSET='export PATH=/work/env/bin:$PATH'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

# Unpack a shell archive: keep the text from the '#! /bin/sh' line on, then run it with sh.
UNSHAR='unshar() { mkdir -p "$2" && awk "f{print} /^#! \/bin\/sh/{f=1; print}" "$1" > "$2.sh" && (cd "$2" && sh "$2.sh"); }'

echo "== fetch: 773.gz (sha256 checked) and 772.gz (STRIPACK) unpacked to /work/tree; toolchain into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o /work/773.gz '$URL773'; echo '$SHA773  /work/773.gz' | sha256sum -c -; gzip -dc /work/773.gz > /work/773.shar; curl -fsSL -o /work/772.gz '$URL772'; gzip -dc /work/772.gz > /work/772.shar; $UNSHAR; rm -rf /work/tree && mkdir -p /work/tree && unshar /work/773.shar /work/tree/773; unshar /work/772.shar /work/tree/772; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }" || { echo "FETCH-FAILED"; exit 1; }

build_and_run() {  # $1 = pass number, $2 = optimisation flag, $3 = toolchain prefix
  local p=$1 opt=$2 env=$3
  tools/sandbox.sh "$ID" -- sh -c "export PATH=$env/bin:\$PATH && rm -rf /work/build$p && mkdir -p /work/build$p && cd /work/build$p && \
    gfortran $opt -c /work/tree/772/Fortran77/Src/Sp/src.f -o stripack.o && gfortran $opt -c /work/tree/773/Src/Sp/src.f -o ssrfpack.o && \
    gfortran $opt /work/tree/773/Drivers/Sp/driver.f stripack.o ssrfpack.o -o ssrftest; echo build_exit=\$?" > "$E/pass$p-build.log" 2>&1
  cat "$E/pass$p-build.log"
  # The RES file goes to pass$p-RES.txt; the driver stdout and exit status go to pass$p-run.log.
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run$p && mkdir -p /work/run$p && cd /work/run$p && cp /work/tree/773/Drivers/Sp/data . && /work/build$p/ssrftest > /work/run$p/stdout.txt 2>&1; echo run_exit=\$? >&2; cat /work/run$p/RES" > "$E/pass$p-RES.txt" 2> "$E/pass$p-run.log"
  echo "run_exit: $(grep -a run_exit "$E/pass$p-run.log")  RES lines: $(wc -l < "$E/pass$p-RES.txt")"
}

echo "== G1 original attempt, pass 1: unmodified sources, gfortran -O2, compile and link as the driver header says"
build_and_run 1 -O2 /work/env
echo "== G3 pass 2: clean rebuild with -O2 again, run in a second working directory (repeat of pass 1)"
build_and_run 2 -O2 /work/env
echo "== pass 3: clean rebuild with -O0 (different environment: optimisation level), run in a third working directory"
build_and_run 3 -O0 /work/env
echo "== pass 4: clean rebuild with -O2 under a second gfortran (13), run in a fourth working directory"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; test -x /work/env13/bin/gfortran || { test -x /work/bin/micromamba || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; /work/bin/micromamba create -y -q -p /work/env13 -r /work/mamba -c conda-forge 'gfortran=13' make; }" || { echo "ENV13-FETCH-FAILED"; exit 1; }
build_and_run 4 -O2 /work/env13

# One VALUE line per claimed value (name as in result.json), from pass 1 RES line 562 (K=496, I=16, J=16).
val() { sed -n '562p' "$E/pass$1-RES.txt" 2>/dev/null | awk '{print $1}'; }
v1=$(val 1); v2=$(val 2); v3=$(val 3); v4=$(val 4)
echo "PASS2 FF(16,16) of SSRFTEST grid ${v2:-MISSING}"
echo "PASS4 (-O2, gfortran 13) FF(16,16) of SSRFTEST grid ${v4:-MISSING}"
echo "PASS3 (-O0) FF(16,16) of SSRFTEST grid ${v3:-MISSING}"
echo "VALUE FF(16,16) of SSRFTEST grid ${v1:-MISSING}"
