#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for donnelly1973-bivnor-462 (ACM TOMS Algorithm 462, Donnelly 1973, BIVNOR).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 462.gz, sha256 checked, gunzip; gfortran 16 from
# conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a standard shell archive. The text from its '#! /bin/sh' line down is run inside the
# sandbox in /work/tree; it writes Fortran/Dp/{Drivers,Src}/ with cat heredocs and nothing else.
# G1 original attempt: the authors' Makefile as shipped, in a copy (/work/orig). It fails: the Makefile expects
# src.f and erf.f next to driver.f in Drivers/, but the archive puts them in Src/. Log kept in evidence/.
# Build-only patch: no source file is edited. /work/build is a directory of symlinks, made before the mid manifest,
# that gives the authors' Makefile the layout it expects (Makefile, driver.f, src.f, erf.f all linked to the unedited
# tree); then make F77=gfortran F77OPTS='-O2 -std=legacy' Res builds driver and runs it into Res (the Makefile's own target).
# Manifests pre/mid/post bracket the build; the build command is recorded with verify_sources.py record.
# Value: the BIVNOR column of the first row of Res (H=0.80000, K=-1.50000, R=-0.90000).
set -uo pipefail
ID=donnelly1973-bivnor-462
URL=https://netlib.org/toms/462.gz
SHA=547505dbaaa2b140deffa1ed3f90c133d637b70502e468b0dc8a26c09ad88aa0
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 462.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/462.gz || curl -fsSL -o /work/462.gz '$URL'; echo '$SHA  /work/462.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/462.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"

echo "== unpack: strip the text above the shell line and run the shar in a fresh tree (writes files only)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && sed -n "/^#! \/bin\/sh/,\$p" /work/462 > /work/462.sh && cd /work/tree && sh /work/462.sh && find /work/tree -type f | sort && wc -l /work/tree/Fortran/Dp/Src/*.f /work/tree/Fortran/Dp/Drivers/driver.f'
echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1

echo "== G1 original attempt: the Makefile as shipped, in a copy of the Drivers directory (tree untouched)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig && cp -r /work/tree/Fortran/Dp/Drivers /work/orig && cd /work/orig && \
  echo "== make F77=gfortran F77OPTS=-O2 -std=legacy Res (Makefile as shipped)"; timeout 600 make F77=gfortran "F77OPTS=-O2 -std=legacy" Res; echo "make exit=$?"' > "$E/original-attempt-build.log" 2>&1
tail -3 "$E/original-attempt-build.log"

echo "== patch step: no source edit; build layout as symlinks outside the tree (Makefile, driver.f, src.f, erf.f)"
tools/sandbox.sh "$ID" -- sh -c 'mkdir -p /work/build && cd /work/build && ln -sfn ../tree/Fortran/Dp/Drivers/Makefile Makefile && ln -sfn ../tree/Fortran/Dp/Drivers/driver.f driver.f && ln -sfn ../tree/Fortran/Dp/Src/src.f src.f && ln -sfn ../tree/Fortran/Dp/Src/erf.f erf.f && ls -l' > "$E/patch-layout.txt" 2>&1
cat "$E/patch-layout.txt"
echo "== manifest mid (immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== build and run (patched layout): make F77=gfortran F77OPTS=-O2 -std=legacy Res (the Makefile's own target)"
tools/sandbox.sh "$ID" -- sh -c 'cd /work/build && export PATH=/work/env16/bin:$PATH && timeout 600 make F77=gfortran "F77OPTS=-O2 -std=legacy" Res; echo "make exit=$?"' > "$E/build-run.log" 2>&1
tail -3 "$E/build-run.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

echo "== the produced table and the shipped table (from the archive)"
tools/sandbox.sh "$ID" -- sh -c 'cd /work/build && cat Res && echo "== shipped res" && cat /work/tree/Fortran/Dp/Drivers/res' > "$E/run-pass1.txt" 2>&1
tools/sandbox.sh "$ID" -- sh -c 'cat /work/tree/Fortran/Dp/Drivers/res' > "$E/shipped-res.txt" 2>&1
sha256sum "$E/shipped-res.txt" | tee "$E/shipped-res.sha256"
cat "$E/run-pass1.txt"

# Observed value: BIVNOR column of the first row (H=0.80000, K=-1.50000, R=-0.90000) of the produced Res.
val() { awk '$1=="0.80000" && $2=="-1.50000" && $3=="-0.90000" { printf "%.17g\n", $4+0; exit }' "$1"; }
echo "VALUE BIVNOR(0.8, -1.5, -0.9) $(val "$E/run-pass1.txt")"
