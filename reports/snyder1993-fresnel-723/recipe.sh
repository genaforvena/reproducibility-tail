#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for snyder1993-fresnel-723 (TOMS 723, Fresnel integrals, Snyder 1993).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 723.gz, sha256 checked against the value below,
# then gunzip. gfortran 16 from conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk (this directory) copies the text of
# each here-document body into Doc/, Drivers/Dp, Drivers/Sp, Src/Dp and Src/Sp verbatim.
# Original attempt (G1): the authors' makefile (Doc/makefile, as shipped) is run in a directory holding the archive's
# files with their shipped names. It calls f77 (absent) and expects drdfrenl.f, while the archive ships the driver as
# driver.f. Log kept in evidence/original-attempt-make.log.
# Build (patched, build-only): the authors' double-precision sources are compiled unmodified with gfortran -O2 in a
# build directory outside the tree (/work/build). The only substitutions are the compiler (gfortran for f77) and the
# driver's object name (drdfrenl.o from Drivers/Dp/driver.f), both in the link/compile commands, no source edit.
# Run: the driver takes no input and writes its table to stdout. Each pass is bounded by timeout 120.
# Basis: patched. Build-only: no tree file changes; the paper check of G2 is not needed (verify_sources record exit 0).
# Value: VALUE line prints the computed C(1.0) (row X = 1.0000000E+00, column C(x)) from the double-precision driver.
set -uo pipefail
ID=snyder1993-fresnel-723
URL=https://netlib.org/toms/723.gz
SHA=335fe1d3d6d8e377cb3bcfc7ad2a394896f698e5c919be321232b295ca566b13
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 723.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/723.gz || curl -fsSL -o /work/723.gz '$URL'; echo '$SHA  /work/723.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/723.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"
cp "$here/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the archive's directory tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/723 > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && cat "$E/unpack-listing.txt"
cp "$SCR/tree/Drivers/Dp/RES" "$E/shipped-res-dp.txt"

echo "== G1 original attempt: the authors' Doc/makefile as shipped (no compiler variables), before any substitution"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && cp /work/tree/Doc/makefile Makefile && \
  cp /work/tree/Drivers/Dp/driver.f /work/tree/Src/Dp/*.f . && make drdfrenl 2>&1; echo make_exit=$?' > "$E/original-attempt-make.log" 2>&1
tail -1 "$E/original-attempt-make.log"
echo "== G1 retry after the toolchain is in the sandbox: the same makefile with F77=gfortran (compiler name only)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig2 && mkdir -p /work/orig2 && cd /work/orig2 && cp /work/tree/Doc/makefile Makefile && \
  cp /work/tree/Drivers/Dp/driver.f /work/tree/Src/Dp/*.f . && make F77=gfortran drdfrenl 2>&1; echo make_exit=$?' > "$E/retry-make-f77-gfortran.log" 2>&1
tail -1 "$E/retry-make-f77-gfortran.log"

echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none in the tree (the driver is staged by name in /work/build, outside the tree)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

# The build commands, one string each, exactly as the sandbox runs them (also passed to verify_sources record).
BUILD=(
  'gfortran -O2 -c /work/tree/Drivers/Dp/driver.f -o drdfrenl.o'
  'gfortran -O2 -c /work/tree/Src/Dp/dfrenl.f -o dfrenl.o'
  'gfortran -O2 -c /work/tree/Src/Dp/dcspxx.f -o dcspxx.o'
  'gfortran -O2 -c /work/tree/Src/Dp/dsnpxx.f -o dsnpxx.o'
  'gfortran -O2 -c /work/tree/Src/Dp/dcospx.f -o dcospx.o'
  'gfortran -O2 -c /work/tree/Src/Dp/dsinpx.f -o dsinpx.o'
  'gfortran -O2 -c /work/tree/Src/Dp/amach.f -o amach.o'
  'gfortran -O2 -c /work/tree/Src/Dp/erfin.f -o erfin.o'
  'gfortran -O2 -c /work/tree/Src/Dp/ermsg.f -o ermsg.o'
  'gfortran -O2 -c /work/tree/Src/Dp/derm1.f -o derm1.o'
  'gfortran -O2 -c /work/tree/Src/Dp/derv1.f -o derv1.o'
  'gfortran -O2 -o drdfrenl drdfrenl.o dfrenl.o dcspxx.o dsnpxx.o dcospx.o dsinpx.o amach.o erfin.o ermsg.o derm1.o derv1.o'
)
echo "== build pass: gfortran -O2 on the authors' double-precision driver and routines (13 commands)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  for c in "$@"; do sh -c "$c" || exit 1; done; echo build_exit=$?' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
CMDS=(); for c in "${BUILD[@]}"; do CMDS+=(--command "$c"); done
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" "${CMDS[@]}" || exit 1

echo "== run pass 1 (-O2 build): timeout 120, stdout is the driver's table"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && \
  timeout 120 /work/build/drdfrenl > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"

echo "== run pass 2: fresh run directory, same built binary (new directory, new process)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run2 && mkdir -p /work/run2 && cd /work/run2 && \
  timeout 120 /work/build/drdfrenl > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/run-pass2.txt" 2> "$E/run-pass2.log"
tail -1 "$E/run-pass2.log"

# Observed value: the row whose X column is exactly 1; the C(x) column is the second.
val() { awk '$1+0==1 && $1 ~ /E/ {print $2; exit}' "$1"; }
echo "OBSERVED pass1 C_1.0 $(val "$E/run-pass1.txt")"
echo "OBSERVED pass2 C_1.0 $(val "$E/run-pass2.txt")"
echo "VALUE C(1.0) $(val "$E/run-pass1.txt")"
