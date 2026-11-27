#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for hanson2004-givens-830 (ACM TOMS Algorithm 830, Hanson & Hopkins 2004).
# Everything that runs the authors' code goes through tools/sandbox.sh.
set -uo pipefail
ID=hanson2004-givens-830
URL=https://netlib.org/toms/830.gz
SHA=aadb021e657f625267c8aa6e4b9f4b5b83aed15a5b7755e8339798e8704925a6
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 830.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 when missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/830.gz || curl -fsSL -o /work/830.gz '$URL'; echo '$SHA  /work/830.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/830.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"

echo "== unpack: run the shar from its /bin/sh line in a fresh tree"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && sed -n "/^#! \/bin\/sh/,\$p" /work/830 > /work/830.sh && cd /work/tree && sh /work/830.sh && find /work/tree -type f | sort'

echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1

echo "== G1 original attempt: the Makefile as shipped (F90 = /opt/NAGWare/bin/f95), in a copy of Drivers (tree untouched)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig && mkdir -p /work/orig && cp -r /work/tree/Fortran90/Drivers /work/orig/Drivers && cp -r /work/tree/Fortran90/Src /work/orig/Src && cd /work/orig/Drivers && \
  echo "== make res1 (Makefile as shipped)"; timeout 600 make res1; echo "make exit=$?"' > "$E/original-attempt-build.log" 2>&1
tail -3 "$E/original-attempt-build.log"

echo "== patch step: no source edit; build layout as symlinks outside the tree, output (res1, .o) written in /work/build only"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/build && mkdir -p /work/build/Fortran90/Drivers && cd /work/build/Fortran90 && ln -sfn /work/tree/Fortran90/Src Src && cd Drivers && ln -sfn /work/tree/Fortran90/Drivers/Makefile Makefile && ln -sfn /work/tree/Fortran90/Drivers/rotm_battery.f90 rotm_battery.f90 && ln -sfn /work/tree/Fortran90/Drivers/data3 data3 && cd /work/build && find . -ls' > "$E/patch-layout.txt" 2>&1
cat "$E/patch-layout.txt"
echo "== manifest mid (immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== build and run: make res1 with the authors' Makefile, compiler and flags overridden on the command line"
tools/sandbox.sh "$ID" -- sh -c 'cd /work/build/Fortran90/Drivers && export PATH=/work/env16/bin:$PATH && timeout 600 make F90=gfortran "F90OPTS=-O2" F90LINK=gfortran "F90LINKOPTS=-O2" res1; echo "make exit=$?"' > "$E/build-run.log" 2>&1
tail -3 "$E/build-run.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

echo "== the produced res1 (first test, first output x-vector) and the shipped res1 from the archive"
tools/sandbox.sh "$ID" -- sh -c 'cat /work/build/Fortran90/Drivers/res1' > "$E/run-pass1.txt" 2>&1
tools/sandbox.sh "$ID" -- sh -c 'cat /work/tree/Fortran90/Drivers/res1' > "$E/shipped-res1.txt" 2>&1
sha256sum "$E/shipped-res1.txt" | tee "$E/shipped-res1.sha256"

# Observed value: first element of the x-vector after the first 'Output vectors (scaled' header of res1.
val() { awk '/Output vectors \(scaled/ {f=1; next} f && /x-vector:/ {getline; print $1; exit}' "$1"; }
v="$(val "$E/run-pass1.txt")"
echo "VALUE rotm-x1-scaled $(python3 -I -c "import sys;print(repr(float(sys.argv[1])))" "$v" 2>/dev/null || echo "$v")"
# Build-only proof (tools/verify_sources.py record): pre == mid, and the one build command, as recipe.sh runs it.
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" --command 'cd /work/build/Fortran90/Drivers && export PATH=/work/env16/bin:$PATH && timeout 600 make F90=gfortran "F90OPTS=-O2" F90LINK=gfortran "F90LINKOPTS=-O2" res1; echo "make exit=$?"'
