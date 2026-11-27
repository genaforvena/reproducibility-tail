#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for dobmann1995-adm-746 (ACM TOMS Algorithm 746, ADM, Dobmann, Liepelt and Schittkowski 1995).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 746.gz, sha256 checked, gunzip; gfortran 16 from
# conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk (this directory) copies each here-document
# body verbatim into /work/tree.
# Original attempt (G1): the archive's build file is Doc/Makefile (FC = epcf90, a compiler not on this host, and a
# TIMER object on an NFS path). Its `all:` line ends in a literal `\\`, which make rejects. Run as shipped:
# `make -f Doc/Makefile -C Fortran77/Dp/Drivers tp1 VPATH=../Src`. Log kept in evidence/original-attempt-build.log.
# Retry (G1): the authors' sources compiled with gfortran 16 (no source edit), the same commands the Makefile's tp1 rule runs.
# Build (basis patched, build-only): the Makefile's tp1 rule cannot run as shipped (see G1 above), so its commands are run
# directly with gfortran, in a build directory outside the tree. EVLTIM (the timer) is the archive's own routine in
# adm.f; the Makefile's extra TIMER object (epcf90, NFS path) is not used. No tree file is edited: manifests pre and mid
# are identical (build-only by verify_sources).
# Value: ADM.RES prints "Generated derivative error:" for TP1 at X = (-2, 1), MAXFUN = 10000; VALUE is that number.
set -uo pipefail
ID=dobmann1995-adm-746
URL=https://netlib.org/toms/746.gz
SHA=c68a4dffe06114a5d59f4feff663a734adcaa930d6513d88c3efae22188b5749
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 746.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/746.gz || curl -fsSL -o /work/746.gz '$URL'; echo '$SHA  /work/746.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/746.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"
cp "$here/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the archive's directory tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/746 > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && wc -l "$E/unpack-listing.txt"

echo "== G1 original attempt: the authors' own make target as shipped (no compiler change, no source change)"
tools/sandbox.sh "$ID" -- sh -c 'cd /work/tree && for c in make gfortran f77 g77 epcf90; do command -v $c || echo "$c: not on PATH"; done; echo "== make tp1 (Doc/Makefile)"; make -f /work/tree/Doc/Makefile -C /work/tree/Fortran77/Dp/Drivers tp1 VPATH=../Src 2>&1; echo "make exit=$?"' > "$E/original-attempt-build.log" 2>&1
tail -2 "$E/original-attempt-build.log"

echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none in the tree (build commands run from a directory outside the tree)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

# The build commands, exactly as the sandbox runs them (also passed to verify_sources record).
BUILD=(
  'gfortran -O2 -std=legacy -c /work/tree/Fortran77/Dp/Src/src.f -o src.o'
  'gfortran -O2 -std=legacy -c /work/tree/Fortran77/Dp/Drivers/admfor.f -o admfor.o'
  'gfortran -O2 -o admfor admfor.o src.o'
  'gfortran -O2 -std=legacy -c /work/tree/Fortran77/Dp/Drivers/adm.f -o adm.o'
  'cp /work/tree/Fortran77/Dp/Drivers/Examples/tp1.inp ADM.INP'
  'cp /work/tree/Fortran77/Dp/Drivers/Examples/tp1.fun ADM.FUN'
  './admfor'
  'gfortran -O2 -std=legacy -c adm_gen.f -o adm_gen.o'
  'gfortran -O2 -o adm adm.o adm_gen.o src.o'
)
echo "== build pass (authors' tp1 rule, gfortran -O2 -std=legacy; generator admfor run inside the build directory)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  for c in "$@"; do sh -c "$c" || { echo "failed: $c"; exit 1; }; done; echo build_exit=0' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
[ -f "reports/$ID/result.json" ] || echo '{}' > "reports/$ID/result.json"
CMDS=(); for c in "${BUILD[@]}"; do CMDS+=(--command "$c"); done
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" "${CMDS[@]}" || exit 1

echo "== run pass 1: fresh directory, copy of the built adm, its inputs; timeout 900"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && cp /work/build/adm /work/build/ADM.INP /work/build/ADM.FUN . && \
  timeout 900 ./adm > stdout.txt 2> stderr.txt; echo run_exit=$?; cat ADM.RES' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"
echo "== run pass 2: fresh directory, new process"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run2 && mkdir -p /work/run2 && cd /work/run2 && cp /work/build/adm /work/build/ADM.INP /work/build/ADM.FUN . && \
  timeout 900 ./adm > stdout.txt 2> stderr.txt; echo run_exit=$?; cat ADM.RES' > "$E/run-pass2.txt" 2> "$E/run-pass2.log"
tail -1 "$E/run-pass2.log"

# Observed value: the generated derivative error, D-format, converted to a number (0.451D-03 -> 0.000451).
val() { awk '/Generated derivative error/ {s=$NF; gsub(/D/,"E",s); printf "%.10g\n", s+0; exit}' "$1"; }
echo "OBSERVED pass1 generated_derivative_error $(awk '/Generated derivative error/{print $NF}' "$E/run-pass1.txt")"
echo "OBSERVED pass2 generated_derivative_error $(awk '/Generated derivative error/{print $NF}' "$E/run-pass2.txt")"
echo "VALUE tp1_generated_derivative_error $(val "$E/run-pass1.txt")"
