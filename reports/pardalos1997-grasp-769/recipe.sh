#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for pardalos1997-grasp-769 (ACM TOMS Algorithm 769, Pardalos, Pitsoulis and
# Resende 1997, GRASP for sparse quadratic assignment). Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 769.gz, sha256 recorded (it was not registered in the queue),
# then gunzip. gfortran from conda-forge via micromamba into /work/env when missing (the host has no Fortran compiler).
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk (from the snyder1993 report) copies the text
# of each here-document body into the tree verbatim (Doc/Makefile, Fortran77/Drivers/Sp/driver.f, data, res, and
# Fortran77/Src/Sp/src.f).
# Original attempt (G1): the authors' Doc/Makefile as shipped (FC=epcf90, PGI flags -sloppy -C -d5 -g -temp=/tmp -u), run in a
# scratch directory with the two source files copied in. epcf90 is not installed in the sandbox; that failure is the log.
# Patch (build-only): the build is the same three gfortran commands, with the compiler substituted (epcf90 -> gfortran) and the
# PGI-only flags dropped. No source file is edited. Manifests pre/mid/post prove that (tools/verify_sources.py record).
# Run: the driver reads its problem from unit 5 (stdin) and prints the result to unit 6 (stdout). The data file is fed on stdin.
# Each pass is bounded by timeout 120.
# Value: the "cost of best permutation found" line of stdout (the claim, integer 4490, tol 0.5).
set -uo pipefail
ID=pardalos1997-grasp-769
URL=https://netlib.org/toms/769.gz
SHA=431c74438646c4f82fa52b2ffc6979bb899adad0825b61cae9466e5d3f2f6b98
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 769.gz (sha256 checked, gunzip); gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; mkdir -p raw; \
  test -s raw/769.gz || curl -fsSL -o raw/769.gz '$URL'; echo '$SHA  raw/769.gz' | sha256sum -c - > raw/sha.txt 2>&1; \
  gunzip -kf raw/769.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; \
  /work/env/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/raw/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"
cp "$here/../snyder1993-fresnel-723/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/raw/769 > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && cat "$E/unpack-listing.txt"
cp "$SCR/tree/Fortran77/Drivers/Sp/res" "$E/shipped-res.txt"

echo "== G1 original attempt: the authors' Doc/Makefile as shipped (epcf90 and PGI flags), before any other step"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH && rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && \
  cp /work/tree/Doc/Makefile . && cp /work/tree/Fortran77/Drivers/Sp/driver.f /work/tree/Fortran77/Src/Sp/src.f . && \
  make -f Makefile 2>&1; echo make_exit=$?; command -v epcf90 || echo "epcf90: not installed in the sandbox"; ls -la gqaps 2>/dev/null || echo "no gqaps binary produced"' > "$E/original-attempt-build.log" 2>&1
tail -3 "$E/original-attempt-build.log"

echo "== manifest pre (right after unpack, before any build step)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none to any source; the build below substitutes gfortran for epcf90 (build-only)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

BUILD=(
  'gfortran -c /work/tree/Fortran77/Drivers/Sp/driver.f -o driver.o'
  'gfortran -c /work/tree/Fortran77/Src/Sp/src.f -o src.o'
  'gfortran -o gqaps driver.o src.o'
)
echo "== build pass: gfortran on the shipped driver and src (3 commands)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  for c in "$@"; do sh -c "$c" || exit 1; done; echo build_exit=$?' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build; the build tool rewrote nothing in the tree)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
echo "== record the build-only patch (proves pre == mid and that the build commands are the recipe's)"
python3 -I tools/verify_sources.py record --repo . --id "$ID" \
  --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" \
  --command 'gfortran -c /work/tree/Fortran77/Drivers/Sp/driver.f -o driver.o' \
  --command 'gfortran -c /work/tree/Fortran77/Src/Sp/src.f -o src.o' --command 'gfortran -o gqaps driver.o src.o' \
  || echo "record exit=$? (see tools/verify_sources.py)"

run_pass() { # $1 = pass number
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run$1 && mkdir -p /work/run$1 && cd /work/run$1 && \
    cp /work/tree/Fortran77/Drivers/Sp/data . && \
    timeout 120 /work/build/gqaps < data > stdout.txt 2> stderr.txt; echo run_exit=\$?; cat stdout.txt"
}
echo "== run pass 1: fresh run directory, timeout 120, data on stdin"
run_pass 1 > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"
echo "== run pass 2: fresh run directory, same built binary, same seed"
run_pass 2 > "$E/run-pass2.txt" 2> "$E/run-pass2.log"
tail -1 "$E/run-pass2.log"

# Observed value: the 'cost of best permutation found' line of stdout (integer).
val() { LC_ALL=C awk -F: '/cost of best permutation found/ {gsub(/ /,"",$2); print $2; exit}' "$1"; }
echo "OBSERVED pass1 cost $(val "$E/run-pass1.txt")"
echo "OBSERVED pass2 cost $(val "$E/run-pass2.txt")"
echo "VALUE best QAP cost (GRASP, seed 270001) $(val "$E/run-pass1.txt")"
