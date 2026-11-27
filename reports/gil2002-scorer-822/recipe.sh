#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for gil2002-scorer-822 (TOMS 822, GIZ/HIZ: complex Scorer functions,
# Fortran 77, double precision). Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 822.gz, sha256 checked against the queue entry.
# The archive is a shell archive: impl/unshar.py UNPACKS it (a parser; the .sh is never executed).
# gfortran 16 from conda-forge via micromamba into /work/env16 when missing.
# Build: the archive's Doc/Makefile uses epcf90 and lists airy.f, which the archive does not ship, so the compile
# and link lines below are ours. No source file is edited: the patch is build-only, and the three manifests
# (pre, mid, post) prove it from bytes.
# Run: SCTEST as shipped; it writes Res1 (the unscaled GI(Z) addition-formula check) in its working directory.
# Claim: MAXIMUM VALUE OF THE MODULUS OF THE CHECK in Res1. Shipped reference = 9.1704421834038D-14, tol_abs 1e-12.
set -uo pipefail
ID=gil2002-scorer-822
URL=https://netlib.org/toms/822.gz
SHA=ae6c947ece8fea8ba98d2f10ce44e3370e14af7a9e14a92217dfcfc5a65e8a50
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
UNSHAR="$(cat "$here/impl/unshar.py")"

echo "== fetch: 822.gz (sha256 checked); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o /work/822.gz '$URL'; echo '$SHA  /work/822.gz' | sha256sum -c -; gunzip -kf /work/822.gz; \
  test -x /work/bin/micromamba || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran make; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt" || { echo "FETCH-FAILED"; exit 1; }
cp "$SCR/gfortran-version.txt" "$E/"
echo "== unpack: impl/unshar.py parses the shell archive (not executed) into /work/tree"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir -p /work/tree" && \
  tools/sandbox.sh "$ID" -- python3 -I -c "$UNSHAR" /work/822 /work/tree >/dev/null || { echo "UNPACK-FAILED"; exit 1; }
rm -rf "$E/manifests"; mkdir -p "$E/manifests"

echo "== manifest pre (right after unpack, before any patch)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none (no source file is edited; the build uses the authors' sources as unpacked)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== G1 original attempt, pass 1: gfortran 16 -O2"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build1 /work/run1 && mkdir -p /work/build1 /work/run1 && cd /work/build1 && \
  gfortran -O2 -c /work/tree/Fortran77/Src/Dp/src.f -o src.o && \
  gfortran -O2 -c /work/tree/Fortran77/Src/Dp/src_819.f -o src819.o && \
  gfortran -O2 -c /work/tree/Fortran77/Drivers/Dp/driver.f -o driver.o && \
  gfortran -O2 -c /work/tree/Fortran77/Drivers/Dp/port.f -o port.o && \
  gfortran -O2 driver.o src.o src819.o port.o -o sctest && echo build_exit=$? && \
  cd /work/run1 && /work/build1/sctest > stdout.txt 2> stderr.txt; echo run_exit=$?; cat /work/run1/Res1' > "$E/pass1-Res1.txt" 2> "$E/pass1-run.log"
tail -1 "$E/pass1-run.log"

echo "== G3 pass 2: clean rebuild, gfortran 16 -O2 again"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build2 /work/run2 && mkdir -p /work/build2 /work/run2 && cd /work/build2 && \
  gfortran -O2 -c /work/tree/Fortran77/Src/Dp/src.f -o src.o && \
  gfortran -O2 -c /work/tree/Fortran77/Src/Dp/src_819.f -o src819.o && \
  gfortran -O2 -c /work/tree/Fortran77/Drivers/Dp/driver.f -o driver.o && \
  gfortran -O2 -c /work/tree/Fortran77/Drivers/Dp/port.f -o port.o && \
  gfortran -O2 driver.o src.o src819.o port.o -o sctest && echo build_exit=$? && \
  cd /work/run2 && /work/build2/sctest > stdout.txt 2> stderr.txt; echo run_exit=$?; cat /work/run2/Res1' > "$E/pass2-Res1.txt" 2> "$E/pass2-run.log"
tail -1 "$E/pass2-run.log"

echo "== pass 3: gfortran 16 -O0"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build3 /work/run3 && mkdir -p /work/build3 /work/run3 && cd /work/build3 && \
  gfortran -O0 -c /work/tree/Fortran77/Src/Dp/src.f -o src.o && \
  gfortran -O0 -c /work/tree/Fortran77/Src/Dp/src_819.f -o src819.o && \
  gfortran -O0 -c /work/tree/Fortran77/Drivers/Dp/driver.f -o driver.o && \
  gfortran -O0 -c /work/tree/Fortran77/Drivers/Dp/port.f -o port.o && \
  gfortran -O0 driver.o src.o src819.o port.o -o sctest && echo build_exit=$? && \
  cd /work/run3 && /work/build3/sctest > stdout.txt 2> stderr.txt; echo run_exit=$?; cat /work/run3/Res1' > "$E/pass3-Res1.txt" 2> "$E/pass3-run.log"
tail -1 "$E/pass3-run.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

# The shipped Res1 next to ours (bytes from the archive, read-only comparison).
tools/sandbox.sh "$ID" -- sh -c 'diff /work/tree/Fortran77/Drivers/Dp/res1 /work/run1/Res1 > /work/diff-shipped-vs-run1.txt; echo diff_exit=$?' || true
cp "$SCR/diff-shipped-vs-run1.txt" "$E/" 2>/dev/null || true

# One value per pass: the maximum modulus of the GI(Z) addition-formula check in Res1.
val() { awk -F'=' '/MAXIMUM VALUE OF THE MODULUS OF THE CHECK/ {v=$2} END {gsub(/ /,"",v); print v}' "$E/pass$1-Res1.txt" 2>/dev/null; }
echo "PASS2 max modulus $(val 2)"
echo "PASS3 (-O0) max modulus $(val 3)"
echo "VALUE max_modulus_unscaled_GI $(val 1)"
