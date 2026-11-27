#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for caliari2008-padua2d-886 (TOMS 886, Padua2D: Lagrange interpolation at
# Padua points; Fortran 77).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only reads text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 886.zip (sha256 checked against the queue entry),
# unzipped to /work/tree/886; gfortran and make (conda-forge, via micromamba) into /work/env if missing.
#
# Build (G1, original attempt): the authors' documented compile line from Doc/README, with the BLAS
# route they document as the alternative (blas/*.f in place of -lblas), gfortran -O2. No source file is edited.
# Run: drvrec (square, DEG = 60, FAMILY = 1, FTYPE = 1 Franke F1, NTG1 = 100). The driver writes fpd.dat, ftg.dat
# and intftg.dat in its working directory and prints "Actual error:" = MAXERR / MAXDEV, the normalized true error
# that Table I reports. The shipped Results/ files are not used.
#
# Claim: normalized true error, F1, degree 60, square; paper 2e-11, tol_abs 5e-12 (queue entry, fixed before any run).
# Two passes (G3): each a clean rebuild in its own directory, each run in its own working directory.
set -uo pipefail
ID=caliari2008-padua2d-886
URL=https://netlib.org/toms/886.zip
SHA=2c2978c2ccb0ac4a4395978d23881e36d1916af9099abfcdec1cc7956628cd40
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
PATHSET='export PATH=/work/env/bin:$PATH'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 886.zip (sha256 checked), unzipped to /work/tree; toolchain (gfortran, make) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/tree && cd /work/tree && curl -fsSL -o /work/886.zip '$URL'; echo '$SHA  /work/886.zip' | sha256sum -c -; python3 -I -m zipfile -e /work/886.zip /work/tree; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== G1 original attempt, pass 1: documented compile line (README, BLAS from blas/*.f), gfortran -O2, no source edit"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/build1 && mkdir -p /work/build1 && cp -r /work/tree/886/Fortran/Dp/Src /work/build1/Src && cp -r /work/tree/886/Fortran/Dp/Drivers /work/build1/Drivers && cd /work/build1/Drivers && gfortran -O2 drvrec.f ../Src/pdpts.f ../Src/cheb.f ../Src/padua2.f ../Src/pd2val.f tstfn2.f f.f ../Src/blas/*.f -o drvrec; echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
cat "$E/pass1-build.log"

echo "== pass 1 run (own working directory /work/run1)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && /work/build1/Drivers/drvrec; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
cat "$E/pass1-run.log"

echo "== G3 pass 2: clean rebuild in a second directory, run in a second working directory"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/build2 && mkdir -p /work/build2 && cp -r /work/tree/886/Fortran/Dp/Src /work/build2/Src && cp -r /work/tree/886/Fortran/Dp/Drivers /work/build2/Drivers && cd /work/build2/Drivers && gfortran -O2 drvrec.f ../Src/pdpts.f ../Src/cheb.f ../Src/padua2.f ../Src/pd2val.f tstfn2.f f.f ../Src/blas/*.f -o drvrec; echo build_exit=\$?; rm -rf /work/run2 && mkdir -p /work/run2 && cd /work/run2 && /work/build2/Drivers/drvrec; echo run_exit=\$?" > "$E/pass2.log" 2>&1
cat "$E/pass2.log"

# One VALUE line per claimed value (name as in result.json), from pass 1; pass 2 is reported separately.
v1=$(grep -a 'Actual error:' "$E/pass1-run.log" | awk '{print $NF}')
v2=$(grep -a 'Actual error:' "$E/pass2.log" | awk '{print $NF}')
echo "PASS2 normalized true error, F1, degree 60, square ${v2:-MISSING}"
echo "VALUE normalized true error, F1, degree 60, square ${v1:-MISSING}"
