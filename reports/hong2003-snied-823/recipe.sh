#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for hong2003-snied-823 (TOMS 823, Snied: scrambled Niederreiter sequences,
# Fortran 77, double precision). Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 823.zip, sha256 checked against the queue entry,
# unpacked with python3's zipfile into /work/tree; gfortran 16 (env16) and gfortran 13 (env13) from conda-forge via micromamba.
# Build: the archive's Drivers/Makefile includes a makefile.inc that the archive does not ship, so the compile lines
# are ours: gfortran <opt> on Src/src.f, Src/extra.f and Drivers/driver.f, then linked. No source file is edited.
# Run: TSNIED as shipped (DIMEN=2, IFLAG=1, ATMOST=4096). The program writes to stdout; each run uses its own work dir.
# Claim: EI at I=4096 (last printed EI line). Shipped reference Drivers/res1 = 0.9999468969847435, tol_abs 1e-9.
set -uo pipefail
ID=hong2003-snied-823
URL=https://netlib.org/toms/823.zip
SHA=de5eaa5face30d4590a8679a94f0b830229771087afbdd4bdc1b75d11b3f9785
SRC=/work/tree/823/Fortran77/Dp/Snied
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 823.zip (sha256 checked) unpacked to /work/tree; gfortran 16 and 13 into /work/env16 and /work/env13 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o /work/823.zip '$URL'; echo '$SHA  /work/823.zip' | sha256sum -c -; rm -rf /work/tree && python3 -I -m zipfile -e /work/823.zip /work/tree; \
  test -x /work/bin/micromamba || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran make; \
  test -x /work/env13/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env13 -r /work/mamba -c conda-forge 'gfortran=13' make" || { echo "FETCH-FAILED"; exit 1; }

build_and_run() {  # $1 = pass number, $2 = optimisation flag, $3 = toolchain prefix
  local p=$1 opt=$2 env=$3
  tools/sandbox.sh "$ID" -- sh -c "export PATH=$env/bin:\$PATH && rm -rf /work/build$p && mkdir -p /work/build$p && cd /work/build$p && \
    gfortran $opt -c $SRC/Src/src.f -o src.o && gfortran $opt -c $SRC/Src/extra.f -o extra.o && gfortran $opt -c $SRC/Drivers/driver.f -o driver.o && \
    gfortran $opt driver.o src.o extra.o -o tsnied; echo build_exit=\$?" > "$E/pass$p-build.log" 2>&1
  cat "$E/pass$p-build.log"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run$p && mkdir -p /work/run$p && cd /work/run$p && /work/build$p/tsnied > stdout.txt 2> stderr.txt; echo run_exit=\$? >&2; cat stdout.txt" > "$E/pass$p-stdout.txt" 2> "$E/pass$p-run.log"
  echo "run_exit: $(grep -a run_exit "$E/pass$p-run.log")  lines: $(wc -l < "$E/pass$p-stdout.txt")"
}

echo "== G1 original attempt, pass 1: unmodified sources, gfortran 16 -O2"
build_and_run 1 -O2 /work/env16
echo "== G3 pass 2: clean rebuild, gfortran 16 -O2 again"
build_and_run 2 -O2 /work/env16
echo "== pass 3: gfortran 16 -O0"
build_and_run 3 -O0 /work/env16
echo "== pass 4: gfortran 13 -O2"
build_and_run 4 -O2 /work/env13

# One value per pass: EI on the line after 'I = 4096' in the driver output (name as in result.json).
val() { awk '$1=="I" && $3==4096 {f=1; next} f && $1=="EI" {print $3; exit}' "$E/pass$1-stdout.txt" 2>/dev/null; }
v1=$(val 1); v2=$(val 2); v3=$(val 3); v4=$(val 4)
echo "PASS2 EI at I=4096 ${v2:-MISSING}"
echo "PASS3 (-O0) EI at I=4096 ${v3:-MISSING}"
echo "PASS4 (-O2, gfortran 13) EI at I=4096 ${v4:-MISSING}"
echo "VALUE EI at I=4096, Snied IFLAG=1, DIMEN=2 ${v1:-MISSING}"
