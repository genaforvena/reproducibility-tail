#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for laurie1982-cubtri-584 (ACM TOMS Algorithm 584, Laurie 1982, CUBTRI).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 584.gz, sha256 checked, gunzip; gfortran 16 from
# conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is one Fortran file (main program KONYN, function F, CUBTRI, RNDERR, CUBRUL). It is copied
# verbatim into /work/tree/584.f; no tree file is edited (manifest pre == mid == post).
# Build and run (G1 original attempt): the file as shipped, compiled and linked as one program with gfortran -O2
# -std=legacy, then run once with no input. Log kept in evidence/original-attempt-build.log and evidence/run-pass1.txt.
# Value: the driver's row for integrand 4 (EXP(SIN(X)*COS(Y)), triangle (0,1),(0,0),(1,0)) at EPS=1E-3, column ANS.
set -uo pipefail
ID=laurie1982-cubtri-584
URL=https://netlib.org/toms/584.gz
SHA=f5b9249f64e069d4e7bdaca43854c5bf73b06c1973a0eec99b3333e60810410e
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 584.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/584.gz || curl -fsSL -o /work/584.gz '$URL'; echo '$SHA  /work/584.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/584.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"

echo "== unpack: the single source file into the tree (verbatim copy; nothing is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cp /work/584 /work/tree/584.f && wc -l /work/tree/584.f'
echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1

echo "== G1 original attempt: the file as shipped, one gfortran compile and link, no change"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && \
  echo "== gfortran -O2 -std=legacy -o as_shipped /work/tree/584.f"; gfortran -O2 -std=legacy -o as_shipped /work/tree/584.f 2>&1; echo "gfortran exit=$?"' > "$E/original-attempt-build.log" 2>&1
tail -3 "$E/original-attempt-build.log"

echo "== patch step: none"
tools/sandbox.sh "$ID" -- sh -c 'cmp /work/584 /work/tree/584.f && echo "tree identical to archive member"' > "$E/patch-none.txt" 2>&1
cat "$E/patch-none.txt"
echo "== manifest mid (immediately before the run)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== run pass 1: the shipped driver as built (original), timeout 300"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && \
  gfortran -O2 -std=legacy -o kontyn /work/tree/584.f && \
  timeout 300 ./kontyn > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt; echo "== stderr"; cat stderr.txt' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"
grep -n "run_exit" "$E/run-pass1.txt"
echo "== manifest post (after the run)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

# Observed value: the ANS column (F15.12) of the first row (EPS=1.E-03) of the fourth example block.
val() { awk '$1=="1.E-03" { n++; if (n==4) { printf "%.17g\n", $2+0; exit } }' "$1"; }
echo "VALUE cubtri_int4_eps1e-3 $(val "$E/run-pass1.txt")"
