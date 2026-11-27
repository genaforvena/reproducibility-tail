#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for wieder1999-hankel-794 (TOMS 794, HANKEL: numerical Hankel transform,
# Fortran 77, double precision). Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 794.gz, sha256 checked against the value below.
# The archive is a shell archive: impl/unshar.py UNPACKS it (a parser; the .sh is never executed). Its heredocs
# use an unquoted marker, which impl/unshar.py accepts.
# gfortran 16 from conda-forge via micromamba into /work/env16 when missing.
# Missing piece: the archive names SrcLibs: port, but does not ship D1MACH or I1MACH. The first build (original
# attempt, G1) fails at link; its log is evidence/original-attempt-link.log. impl/machine.f supplies the IEEE
# double-precision machine constants (written from the PORT description, not tuned to the output). Basis: patched.
# Build: the authors' sources are compiled unmodified; the only added file is impl/machine.f, copied to /work/impl.
# Run: the driver reads the data file on stdin (names res.err and res, mode 1, NU 1.0, XI 5.0, then 2) and writes
# the result row to res in its working directory.
# Claim: HT(XI=5.0, NU=1.0) = 0.208245531E-01, tol_abs 1e-9. Shipped reference: Fortran77/Drivers/Dp/res.
set -uo pipefail
ID=wieder1999-hankel-794
URL=https://netlib.org/toms/794.gz
SHA=bdbd599bf88d0062a161aa01880b4a271a9fca31df3b13bd662c0ecfc83cab29
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
UNSHAR="$(cat "$here/impl/unshar.py")"

echo "== fetch: 794.gz (sha256 checked); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o /work/794.gz '$URL'; echo '$SHA  /work/794.gz' | sha256sum -c -; gunzip -kf /work/794.gz; \
  test -x /work/bin/micromamba || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran make; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt" || { echo "FETCH-FAILED"; exit 1; }
cp "$SCR/gfortran-version.txt" "$E/"
echo "== unpack: impl/unshar.py parses the shell archive (not executed) into /work/tree"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir -p /work/tree" && \
  tools/sandbox.sh "$ID" -- python3 -I -c "$UNSHAR" /work/794 /work/tree >/dev/null || { echo "UNPACK-FAILED"; exit 1; }
mkdir -p "$SCR/impl" && cp "$here/impl/machine.f" "$SCR/impl/machine.f" || exit 1
rm -rf "$E/manifests"; mkdir -p "$E/manifests"

echo "== manifest pre (right after unpack, before any patch)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none to the authors' sources; impl/machine.f is a new file in /work/impl (not in the tree)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== G1 original attempt (no machine constants): link fails on D1MACH and I1MACH"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && \
  gfortran -O2 -c /work/tree/Fortran77/Src/Dp/src.f -o src.o && gfortran -O2 -c /work/tree/Fortran77/Src/Dp/specfun.f -o specfun.o && \
  gfortran -O2 -c /work/tree/Fortran77/Drivers/Dp/driver.f -o driver.o && gfortran -O2 driver.o src.o specfun.o -o hankel; echo link_exit=$?' > "$E/original-attempt-link.log" 2>&1
tail -1 "$E/original-attempt-link.log"

echo "== pass 1: gfortran 16 -O2, with impl/machine.f (the build commands)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build1 /work/run1 && mkdir -p /work/build1 /work/run1 && cd /work/build1 && \
  gfortran -O2 -c /work/impl/machine.f -o machine.o && \
  gfortran -O2 -c /work/tree/Fortran77/Src/Dp/src.f -o src.o && \
  gfortran -O2 -c /work/tree/Fortran77/Src/Dp/specfun.f -o specfun.o && \
  gfortran -O2 -c /work/tree/Fortran77/Drivers/Dp/driver.f -o driver.o && \
  gfortran -O2 driver.o src.o specfun.o machine.o -o hankel && echo build_exit=$? && \
  cd /work/run1 && cp /work/tree/Fortran77/Drivers/Dp/data . && /work/build1/hankel < data > stdout.txt 2> stderr.txt; echo run_exit=$?; cat /work/run1/res' > "$E/pass1-res.txt" 2> "$E/pass1-run.log"
tail -1 "$E/pass1-run.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

echo "== pass 2: clean rebuild at -O0 (second pass, different optimization)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build2 /work/run2 && mkdir -p /work/build2 /work/run2 && cd /work/build2 && \
  gfortran -O0 -c /work/impl/machine.f -o machine.o && \
  gfortran -O0 -c /work/tree/Fortran77/Src/Dp/src.f -o src.o && \
  gfortran -O0 -c /work/tree/Fortran77/Src/Dp/specfun.f -o specfun.o && \
  gfortran -O0 -c /work/tree/Fortran77/Drivers/Dp/driver.f -o driver.o && \
  gfortran -O0 driver.o src.o specfun.o machine.o -o hankel && echo build_exit=$? && \
  cd /work/run2 && cp /work/tree/Fortran77/Drivers/Dp/data . && /work/build2/hankel < data > stdout.txt 2> stderr.txt; echo run_exit=$?; cat /work/run2/res' > "$E/pass2-res.txt" 2> "$E/pass2-run.log"
tail -1 "$E/pass2-run.log"

# The shipped res next to ours (bytes from the archive, read-only comparison).
tools/sandbox.sh "$ID" -- sh -c 'diff /work/tree/Fortran77/Drivers/Dp/res /work/run1/res > /work/diff-shipped-vs-run1.txt; echo diff_exit=$?' || true
cp "$SCR/diff-shipped-vs-run1.txt" "$E/" 2>/dev/null || true

# One value per pass: the XI=5.0 row of res (second column), in the authors' printed format.
val() { awk '$1+0==5.0 {print $2; exit}' "$E/pass$1-res.txt" 2>/dev/null; }
echo "PASS2 (-O0) HT $(val 2)"
echo "VALUE HT_XI5_NU1 $(val 1)"
