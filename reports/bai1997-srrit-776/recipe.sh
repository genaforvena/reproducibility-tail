#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for bai1997-srrit-776 (TOMS 776, SRRIT: dominant invariant subspace of a
# nonsymmetric matrix, Bai and Stewart 1997). Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 776.gz, sha256 checked against the value below,
# then gunzip. gfortran 16 from conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk copies the text of each here-document
# body into its directory (Doc/, Drivers/Dp, Drivers/Sp, Src/Dp, Src/Sp) verbatim, following the archive's own cd lines.
# Original attempt (G1): the authors' Doc/Makefile, documented build (epcf90 -sloppy -C -d1 -g), is run first; it fails
# because epcf90 is not installed here. Log kept in evidence/original-attempt-make.log.
# Build (patched, compiler substitution only): the authors' double-precision sources are compiled unmodified with
# gfortran -O2 (no source edit, no flags beyond -O2). Basis: patched.
# Run: the driver reads the Drivers/Dp/data input from stdin and writes its output to the file 'doutput' (OPEN in
# driver.f). The run is bounded by timeout 300.
# Observed (not a verdict): the shipped claim's value, which the registered claim calls the RWK 496x496 problem, is
# printed here by the BWM block (test matrix size 200). See result.md.
set -uo pipefail
ID=bai1997-srrit-776
URL=https://netlib.org/toms/776.gz
SHA=11341f825b8c12bb7f51bf58affe513255d14206fa8147310284249c2e6d1d34
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 776.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o /work/776.gz '$URL'; echo '$SHA  /work/776.gz' | sha256sum -c -; gunzip -kf /work/776.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt" || { echo "FETCH-FAILED"; exit 1; }
cp "$SCR/gfortran-version.txt" "$E/"
cp "$here/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the archive's directory tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/776 && find . -type f | sort' > "$E/unpack-listing.txt" || { echo "UNPACK-FAILED"; exit 1; }
cat "$E/unpack-listing.txt"
cp "$SCR/tree/Drivers/Dp/DRES" "$E/shipped-DRES-double.txt"

echo "== G1 original attempt: the authors' documented make (epcf90), before any compiler substitution"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && cp /work/tree/Doc/Makefile . && \
  cp /work/tree/Drivers/Dp/driver.f /work/tree/Src/Dp/dsrrit.f /work/tree/Src/Dp/dblas.f /work/tree/Src/Dp/dlapack.f . && make double 2>&1; echo make_exit=$?' > "$E/original-attempt-make.log" 2>&1
tail -1 "$E/original-attempt-make.log"

echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none (no authors' source file is edited; the compiler is gfortran, not epcf90)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== build: gfortran 16 -O2 on the authors' double-precision driver and routines"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  gfortran -O2 -c /work/tree/Drivers/Dp/driver.f -o driver.o && gfortran -O2 -c /work/tree/Src/Dp/dsrrit.f -o dsrrit.o && \
  gfortran -O2 -c /work/tree/Src/Dp/dblas.f -o dblas.o && gfortran -O2 -c /work/tree/Src/Dp/dlapack.f -o dlapack.o && \
  gfortran -O2 driver.o dsrrit.o dblas.o dlapack.o -o dsubspiter && echo build_exit=$?' > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" \
  --command 'gfortran -O2 -c /work/tree/Drivers/Dp/driver.f -o driver.o' \
  --command 'gfortran -O2 -c /work/tree/Src/Dp/dsrrit.f -o dsrrit.o' \
  --command 'gfortran -O2 -c /work/tree/Src/Dp/dblas.f -o dblas.o' \
  --command 'gfortran -O2 -c /work/tree/Src/Dp/dlapack.f -o dlapack.o' \
  --command 'gfortran -O2 driver.o dsrrit.o dblas.o dlapack.o -o dsubspiter' || exit 1

echo "== run: Drivers/Dp/data as input (stdin copy), the driver writes doutput; timeout 300"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run && mkdir -p /work/run && cd /work/run && cp /work/tree/Drivers/Dp/data input && \
  timeout 300 /work/build/dsubspiter < input > stdout.txt 2> stderr.txt; echo run_exit=$?; cat doutput 2>/dev/null' > "$E/run-doutput.txt" 2> "$E/run.log"
tail -1 "$E/run.log"

# Observed values, printed by the authors' own output (not a claimed VALUE line): the first converged WR of each
# problem block that prints one. The BWM block (200 x 200) holds the shipped value -1.235506919564D+03.
blockwr() { awk -v b="$2" 'index($0, "Type of Test problem: " b) {f=1} f && /Converged Eigenvalues/ {g=1; next} g && /WR =/ {print $3; exit}' "$1"; }
echo "OBSERVED RWK_first_WR $(blockwr "$E/run-doutput.txt" RWK)"
echo "OBSERVED BWM_first_WR $(blockwr "$E/run-doutput.txt" BWM)"
