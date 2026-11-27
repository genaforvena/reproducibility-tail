#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for verschelde1999-phcpack-795 (TOMS 795, PHCpack 1.0, Ada; registered claim:
# the black-box solver finds #sols = 70 for cyclic5). Source: netlib TOMS 795.gz (sha256 checked). Built with GNAT 13.3.0
# from Ubuntu noble (the .deb packages, unpacked into the sandbox; no GNAT on the host). Everything that runs the
# authors' code goes through tools/sandbox.sh.
#
# Basis: patched. The original tree (after the authors' own `make links`) builds, but its batch run stops with
# STORAGE_ERROR (getrusage overflows a 72-byte record) and then CONSTRAINT_ERROR; those runs are kept as the original
# attempt. Two source patches (impl/patch-src.sh) make the run complete. Neither changes the algorithm.
set -uo pipefail
ID=verschelde1999-phcpack-795
URL=https://netlib.org/toms/795.gz
SHA=6ff06dbba5bce3143881fdce40907a435fd687c246f917aa4e150993f6dd65ec
UB=http://nl.archive.ubuntu.com/ubuntu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1
cp "$here/impl/extract-tree.awk" "$here/impl/patch-src.sh" "$here/impl/build-phc.sh" "$SCR/"

echo "== fetch: 795.gz (sha256 checked, gunzip); GNAT 13.3.0 debs from Ubuntu noble, unpacked into /work/root"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o /work/795.gz '$URL'; echo '$SHA  /work/795.gz' | sha256sum -c -; gunzip -kf /work/795.gz; \
  if [ ! -x /work/root/usr/bin/gnatmake ]; then mkdir -p /work/debs /work/root; cd /work/debs; \
  for f in pool/universe/g/gcc-13/gnat-13_13.3.0-6ubuntu2~24.04.1_amd64.deb pool/universe/g/gcc-13/gnat-13-x86-64-linux-gnu_13.3.0-6ubuntu2~24.04.1_amd64.deb pool/universe/g/gcc-13/libgnat-13_13.3.0-6ubuntu2~24.04.1_amd64.deb pool/main/g/gcc-13/gcc-13-x86-64-linux-gnu_13.3.0-6ubuntu2~24.04.1_amd64.deb pool/main/g/gcc-13/gcc-13_13.3.0-6ubuntu2~24.04.1_amd64.deb pool/main/g/gcc-13/libgcc-13-dev_13.3.0-6ubuntu2~24.04.1_amd64.deb pool/main/g/gcc-13/cpp-13-x86-64-linux-gnu_13.3.0-6ubuntu2~24.04.1_amd64.deb pool/main/b/binutils/binutils-x86-64-linux-gnu_2.42-4ubuntu2.11_amd64.deb pool/main/b/binutils/libbinutils_2.42-4ubuntu2.11_amd64.deb pool/main/b/binutils/libctf0_2.42-4ubuntu2.11_amd64.deb pool/main/b/binutils/libctf-nobfd0_2.42-4ubuntu2.11_amd64.deb pool/main/b/binutils/libsframe1_2.42-4ubuntu2.11_amd64.deb pool/main/i/isl/libisl23_0.26-3build1.1_amd64.deb pool/main/m/mpclib3/libmpc3_1.3.1-1build1.1_amd64.deb pool/main/m/mpfr4/libmpfr6_4.2.1-1build1.1_amd64.deb pool/main/g/gmp/libgmp10_6.3.0+dfsg-2ubuntu6.1_amd64.deb; do curl -fsSL -o \$(basename \$f) $UB/\$f; done; \
  for d in *.deb; do dpkg-deb -x \$d /work/root; done; fi; \
  echo gnat-13 13.3.0-6ubuntu2~24.04.1 from Ubuntu noble debs, unpacked under /work/root > /work/gnat-version.txt; cat /work/gnat-version.txt" || { echo "FETCH-FAILED"; exit 1; }
cp "$SCR/gnat-version.txt" "$E/" 2>/dev/null; cat "$E/gnat-version.txt" 2>/dev/null

echo "== unpack: verbatim here-document bodies into the archive's tree; then the authors' own 'make links' in each GNAT/ dir"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/795 && cd GNAT && for d in System Math_Lib Homotopy Continuation Root_Counts Main Objects; do ( cd $d 2>/dev/null && [ -f makefile ] && make -s links >/dev/null 2>&1 ); done; cd /work/tree && find . -type f | sort' > "$E/unpack-listing.txt" || { echo "UNPACK-FAILED"; exit 1; }
wc -l < "$E/unpack-listing.txt"

echo "== original attempt: the authors' tree as shipped (no patch), built and run in batch mode on Demo/cyclic5"
tools/sandbox.sh "$ID" -- sh -c 'cd /work && sh /work/build-phc.sh /work/phc-orig > /work/build-orig.log 2>&1; echo "BUILD $?"; grep -c " error" /work/build-orig.log' | tee "$E/original-build.txt"
tools/sandbox.sh "$ID" -- sh -c 'export LD_LIBRARY_PATH=/work/root/usr/lib/x86_64-linux-gnu; rm -rf /work/run-orig && mkdir -p /work/run-orig && cd /work/run-orig && cp /work/tree/Demo/cyclic5 . && timeout 900 /work/phc-orig/phc -b cyclic5 out.txt; echo "EXIT $?"' > "$E/original-attempt-run.log" 2>&1
tail -3 "$E/original-attempt-run.log"

echo "== patch: impl/patch-src.sh on the authors' source (two compatibility fixes), then build"
tools/sandbox.sh "$ID" -- sh -c 'cd /work && sh /work/patch-src.sh patch && sh /work/build-phc.sh /work/phc > /work/build-patched.log 2>&1; echo "BUILD $?"' | tee "$E/patched-build.txt"

echo "== run (pass 1, pass 2): phc -b on Demo/cyclic5, from a fresh directory each time"
for p in 1 2; do
  tools/sandbox.sh "$ID" -- sh -c "export LD_LIBRARY_PATH=/work/root/usr/lib/x86_64-linux-gnu; rm -rf /work/run$p && mkdir -p /work/run$p && cd /work/run$p && cp /work/tree/Demo/cyclic5 . && timeout 900 /work/phc/phc -b cyclic5 out.txt > run.log 2>&1; echo \"EXIT \$?\"; cat out.txt; cat run.log" > "$E/patched-run-pass$p.log" 2>&1
  n=$(grep -o "Number of regular solutions *: *[0-9]*" "$E/patched-run-pass$p.log" | grep -o "[0-9]*$")
  echo "pass $p: regular solutions = ${n:-NONE}"
  echo "VALUE cyclic5_solutions_regular ${n:-NaN}"
done
