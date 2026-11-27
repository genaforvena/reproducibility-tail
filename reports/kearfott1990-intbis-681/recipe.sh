#!/usr/bin/env bash
# Rebuilds the rerun verdict for kearfott1990-intbis-681 (TOMS 681, INTBIS; see result.md when written).
# Fetch (the only network step, inside the sandbox): netlib TOMS 681.gz, sha256 checked, gunzipped to 681.txt.
# gfortran (conda-forge, micromamba) goes to /work/env if missing.
# Claim: "Number of roots found" for test problem no. 1 (cubic-parabola) in the GENBIS run, against the
# shipped sample output inside the archive (line 10401 of the decompressed text), tolerance abs 0.
# The archive is one text file: documentation, Fortran source (lines 94-9717, from PROGRAM GENBIS to the END
# of PUSH), the sample input (lines 9718-10374, read by the program from unit 5) and the sample configuration
# (lines 10375-10388, read from unit 20). The program's own code is cut out by an extraction patch (one file,
# intbis.f); the input and configuration are fed from the archive's own line ranges in the run step.
# Patch (source, not build-only): gfortran rejects the package's own subroutine FREE ("Too many arguments in call to 'free'"),
# so FREE is renamed FREEBX at its two sites (CALL and SUBROUTINE). evidence/rename-diff-vs-archive-range.txt shows every change.
# Original attempt (G1): the archive compiled as shipped (gfortran on the whole text file): it fails on the
# documentation prose (kept in evidence/original-attempt-build.log).
set -uo pipefail
ID=kearfott1990-intbis-681
URL=https://netlib.org/toms/681.gz
SHA=b0ac1477099be1f23d2cdb9be18cfad2f31afd1e95e7d026a6f2b2d98f987f96
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 681.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/raw && cd /work/raw; \
  curl -fsSL -o 681.gz '$URL'; echo '$SHA  681.gz' | sha256sum -c - ; gzip -dc 681.gz > /work/raw/681.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }; \
  /work/env/bin/gfortran --version | head -1 > /work/gfortran-version.txt" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- cat /work/gfortran-version.txt > "$E/gfortran-version.txt" && cat "$E/gfortran-version.txt"

echo "== unpack: the authors' archive text goes into the tree as the archive file (no execution)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cp /work/raw/681.txt /work/tree/681.txt && sha256sum /work/tree/681.txt'
tools/sandbox.sh "$ID" -- sh -c 'sed -n "10398,10401p" /work/raw/681.txt' > "$E/reference/shipped-problem1-excerpt.txt"; cat "$E/reference/shipped-problem1-excerpt.txt"

ORIG="$E/original-attempt-build.log"
if [ ! -s "$ORIG" ]; then
  echo "== G1 original attempt: the archive as shipped, compiled with gfortran (fixed form, no edits)"
  tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH; rm -rf /work/orig && mkdir /work/orig && cd /work/orig && cp /work/raw/681.txt ./681.f && gfortran -c 681.f 2>&1; echo compile_exit=$?' > "$ORIG" 2>&1
  tail -3 "$ORIG"
fi

echo "== manifest pre (archive file only, before the patch step)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: lines 94-9717 of the archive file copied to intbis.f, and the name FREE (the package's own subroutine, which gfortran maps onto the C library free) renamed to FREEBX at its two sites; no other change"
tools/sandbox.sh "$ID" -- bash -c 'cd /work/tree && sed -n "94,9717p" 681.txt | sed -e "s/CALL FREE(/CALL FREEBX(/" -e "s/SUBROUTINE FREE(/SUBROUTINE FREEBX(/" > intbis.f && sha256sum intbis.f && sed -n "94,9717p" 681.txt > /work/intbis-archive-range.f'
tools/sandbox.sh "$ID" -- sh -c 'diff /work/intbis-archive-range.f /work/tree/intbis.f > /work/rename.diff; true' && tools/sandbox.sh "$ID" -- cat /work/rename.diff > "$E/rename-diff-vs-archive-range.txt"; cat "$E/rename-diff-vs-archive-range.txt"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

BUILD=('gfortran -O2 -ffixed-line-length-none -o /work/build/intbis intbis.f')
echo "== build: gfortran, compiled in the tree directory, output to /work/build"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH && mkdir -p /work/build && cd /work/tree && for c in "$@"; do sh -c "$c" || exit 1; done; echo build_exit=$?' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

echo "== run pass 1: input from the archive's line range (unit 5 = stdin), configuration as unit 20 (fort.20)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir /work/run1 && cd /work/run1 && sed -n "9718,10374p" /work/raw/681.txt > stdin.dat && sed -n "10375,10388p" /work/raw/681.txt > fort.20 && timeout 300 /work/build/intbis < stdin.dat > run.out 2>&1; echo run_exit=$?; cat run.out' > "$E/run-pass1.txt" 2>&1
head -1 "$E/run-pass1.txt"
echo "== values (VALUE line) from pass 1"
python3 -I "$here/impl/extract_value.py" "$E/run-pass1.txt" | tee "$E/values-run1.txt"
echo "== problem 1 output block against the shipped block (lines 10398-10530 of the archive text), whitespace ignored; evidence only, not the claim"
tools/sandbox.sh "$ID" -- sh -c 'sed -n "10398,10530p" /work/raw/681.txt' > "$E/reference/shipped-problem1.txt"
awk '/Test problem no. 1:  cubic/{f=1} /Test problem no. 2 --/{if(f)exit} f' "$E/run-pass1.txt" > "$E/problem1-run1.txt"
diff -w -B "$E/reference/shipped-problem1.txt" "$E/problem1-run1.txt" > "$E/problem1-diff.txt"; true
echo "problem 1 differing lines (whitespace ignored): $(grep -c '^[<>]' "$E/problem1-diff.txt")"
