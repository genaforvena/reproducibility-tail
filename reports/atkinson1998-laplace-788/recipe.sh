#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for atkinson1998-laplace-788 (ACM TOMS Algorithm 788, Atkinson and Jeon 1998, NEUMAN).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 788.gz, sha256 checked, gunzip; gfortran 16 from
# conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk (copied from dobmann1995-adm-746) copies
# each here-document body verbatim into /work/tree.
# Original attempt (G1): the archive's Doc/Makefile sets FC=epcf90, a compiler not on this host. Run as shipped:
# `make -f Doc/Makefile neuman VPATH=../../Src/Dp` in Fortran77/Drivers/Dp. Log kept in evidence/original-attempt-build.log.
# Build (basis patched, build-only): the Makefile's neuman rule commands are run directly with gfortran in a build
# directory outside the tree (flags as the authors' FFLAGS minus epcf90-only options). No tree file is edited.
# Value: the driver1 table row for X=0.1112, Y=1.3695 (IBD=0), column U(X,Y), printed in D-format.
set -uo pipefail
ID=atkinson1998-laplace-788
URL=https://netlib.org/toms/788.gz
SHA=86e9c5c9ae7abcee40dbc4afe303e559416a91dd9a0383d6c09edb9d8706a775
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 788.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/788.gz || curl -fsSL -o /work/788.gz '$URL'; echo '$SHA  /work/788.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/788.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"
cp "$here/../dobmann1995-adm-746/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the archive's directory tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/788 > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && wc -l "$E/unpack-listing.txt"

echo "== G1 original attempt: the authors' own make target as shipped (no compiler change, no source change)"
tools/sandbox.sh "$ID" -- sh -c 'cd /work/tree/Fortran77/Drivers/Dp && for c in make gfortran f77 epcf90; do command -v $c || echo "$c: not on PATH"; done; echo "== make neuman (Doc/Makefile)"; make -f /work/tree/Doc/Makefile neuman VPATH=../../Src/Dp 2>&1; echo "make exit=$?"' > "$E/original-attempt-build.log" 2>&1
tail -1 "$E/original-attempt-build.log"

echo "== diagnostic attempt (unpatched d1mach.f, gfortran): build and run, log kept; not the basis"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build0 /work/run0 && mkdir -p /work/build0 /work/run0 && cd /work/build0 && \
  gfortran -O2 -std=legacy -c /work/tree/Fortran77/Src/Dp/d1mach.f -o d1mach.o && gfortran -O2 -std=legacy -c /work/tree/Fortran77/Src/Dp/lasys.f -o lasys.o && \
  gfortran -O2 -std=legacy -c /work/tree/Fortran77/Src/Dp/rfft_pack.f -o rfft_pack.o && gfortran -O2 -std=legacy -c /work/tree/Fortran77/Src/Dp/neuman.f -o neuman.o && \
  gfortran -O2 -std=legacy -c /work/tree/Fortran77/Drivers/Dp/driver1.f -o driver1.o && gfortran -O2 -o driver1 d1mach.o lasys.o rfft_pack.o neuman.o driver1.o && \
  cd /work/run0 && cp /work/build0/driver1 /work/tree/Fortran77/Drivers/Dp/data1 . && timeout 900 ./driver1 < data1 > stdout.txt 2> stderr.txt; echo run_exit=$?; cat res1' > "$E/diagnostic-unpatched-d1mach-run.txt" 2>&1
grep -n "0.1112 *1.3695" "$E/diagnostic-unpatched-d1mach-run.txt" | head -1

echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: d1mach.f ships configured for big-endian IEEE (SGI/HP); activate the file's own documented 8087 block for little-endian x86 (the file says to do this for other machines)"
tools/sandbox.sh "$ID" -- sh -c 'f=/work/tree/Fortran77/Src/Dp/d1mach.f && sed -i -e "49,53s/^/C/" -e "59,63s/^C      DATA/      DATA/" "$f" && sed -n 45,64p "$f"' > "$E/patch-d1mach.txt" 2>&1
cat "$E/patch-d1mach.txt" | head -30
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

# The build commands, exactly as the sandbox runs them (also passed to verify_sources record).
BUILD=(
  'gfortran -O2 -std=legacy -c /work/tree/Fortran77/Src/Dp/d1mach.f -o d1mach.o'
  'gfortran -O2 -std=legacy -c /work/tree/Fortran77/Src/Dp/lasys.f -o lasys.o'
  'gfortran -O2 -std=legacy -c /work/tree/Fortran77/Src/Dp/rfft_pack.f -o rfft_pack.o'
  'gfortran -O2 -std=legacy -c /work/tree/Fortran77/Src/Dp/neuman.f -o neuman.o'
  'gfortran -O2 -std=legacy -c /work/tree/Fortran77/Drivers/Dp/driver1.f -o driver1.o'
  'gfortran -O2 -o driver1 d1mach.o lasys.o rfft_pack.o neuman.o driver1.o'
)
echo "== build pass (authors' neuman rule, gfortran -O2 -std=legacy)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  for c in "$@"; do sh -c "$c" || { echo "failed: $c"; exit 1; }; done; echo build_exit=0' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
[ -f "reports/$ID/result.json" ] || echo '{}' > "reports/$ID/result.json"
CMDS=(); for c in "${BUILD[@]}"; do CMDS+=(--command "$c"); done
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" "${CMDS[@]}"; echo "record_exit=$? (2 = source patch before build: full G2 paper check applies)"

echo "== run pass 1: fresh directory, driver1 fed data1 on stdin; timeout 900"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && cp /work/build/driver1 /work/tree/Fortran77/Drivers/Dp/data1 . && \
  timeout 900 ./driver1 < data1 > stdout.txt 2> stderr.txt; echo run_exit=$?; cat res1' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"

# Observed value: the table row for X=0.1112, Y=1.3695 (IBD 0), column U(X,Y), D-format converted to a number.
val() { awk '$1=="0" && $2=="0.1112" && $3=="1.3695" {s=$4; gsub(/D/,"E",s); printf "%.11f\n", s+0; exit}' "$1"; }
echo "VALUE neuman_u_0p1112_1p3695 $(val "$E/run-pass1.txt")"
