#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for geurts1997-colred-767 (ACM TOMS Algorithm 767, Geurts & Praagman 1997, COLRED).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 767.gz, sha256 recorded, gunzip; gfortran 16 from
# conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a standard shell archive. The text from its '#! /bin/sh' line down is run inside the sandbox
# in /work/tree; it writes Drivers/Dp/{driver.f,data,RES} and Src/Dp/{src,blas1,blas2,lapack}.f with cat heredocs.
# G1 original attempt: the archive ships no Makefile and no build script; `make` in the shipped Drivers/Dp fails.
# Build-only: no source file is edited. The authors' sources are compiled in place with gfortran -O2 -std=legacy,
# the flags the sibling TOMS records use; the output binary goes to /work/build, never into the tree.
# Manifests pre/mid/post bracket the build; the build command is recorded with verify_sources.py record.
# Run: the driver reads the archive's own data file on stdin (example 1..11). Value: R(0)(1,1) of example 2.
set -uo pipefail
ID=geurts1997-colred-767
URL=https://netlib.org/toms/767.gz
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 767.gz (sha256 recorded, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/767.gz || curl -fsSL -o /work/767.gz '$URL'; sha256sum /work/767.gz > /work/sha.txt; \
  gunzip -kf /work/767.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"

echo "== unpack: strip the text above the shell line and run the shar in a fresh tree (writes files only)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && sed -n "/^#! \/bin\/sh/,\$p" /work/767 > /work/767.sh && cd /work/tree && sh /work/767.sh && find /work/tree -type f | sort'

echo "== manifest pre (right after unpack, before any build)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1

echo "== G1 original attempt: the shipped tree as it is, with its own make (no Makefile in the archive)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && cd /work/tree/Drivers/Dp && echo "== make (as shipped)"; timeout 120 make; echo "make exit=$?"' > "$E/original-attempt-build.log" 2>&1
cat "$E/original-attempt-build.log"

echo "== manifest mid (immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== build: gfortran -O2 -std=legacy on the unedited sources, output in /work/build"
BUILD_CMD='mkdir -p /work/build && cd /work/build && export PATH=/work/env16/bin:$PATH && T=/work/tree && gfortran -O2 -std=legacy $T/Drivers/Dp/driver.f $T/Src/Dp/src.f $T/Src/Dp/blas1.f $T/Src/Dp/blas2.f $T/Src/Dp/lapack.f -o colred; echo "gfortran exit=$?"'
tools/sandbox.sh "$ID" -- sh -c "$BUILD_CMD" > "$E/build-run.log" 2>&1
cat "$E/build-run.log"

echo "== run: the archive's data file on stdin, in the build directory (not the tree)"
tools/sandbox.sh "$ID" -- sh -c 'cd /work/build && timeout 300 ./colred < /work/tree/Drivers/Dp/data > run-pass1.out 2> run-pass1.err; echo "run exit=$?"' >> "$E/build-run.log" 2>&1
tail -2 "$E/build-run.log"
cp "$SCR/build/run-pass1.out" "$E/run-pass1.out"
cp "$SCR/build/run-pass1.err" "$E/run-pass1.err" 2>/dev/null || true

echo "== manifest post (after the build and run)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

echo "== build-only record (exit 0 means only the build differs; no source edit between mid and post)"
python3 -I tools/verify_sources.py record --repo . --id "$ID" \
  --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" \
  --command "$BUILD_CMD" || echo "record exit=$? (2 means a source changed before the build: full G2 check needed)"

echo "== the shipped RES (from the archive) and the produced output"
cp "$SCR/tree/Drivers/Dp/RES" "$E/shipped-res.txt"
sha256sum "$E/shipped-res.txt" | tee "$E/shipped-res.sha256"
# Signed zeros: the shipped RES prints 0.0000000 where this compiler prints -0.0000000. Normalised comparison only.
sed 's/-0\.0000000/ 0.0000000/g' "$E/shipped-res.txt" | sed 's/ *$//' > "$E/shipped-res.norm"
sed 's/-0\.0000000/ 0.0000000/g' "$E/run-pass1.out" | sed 's/ *$//' > "$E/run-pass1.norm"
diff "$E/shipped-res.norm" "$E/run-pass1.norm" > "$E/compare-signed-zero-normalised.txt"; echo "normalised diff lines: $(wc -l < "$E/compare-signed-zero-normalised.txt")"
wc -l < "$E/run-pass1.out"

# Observed value: R(0)(1,1) of EXAMPLE( 2), the first entry of the first R(0) block after the example-2 header.
val() { awk '/EXAMPLE\( 2\)/ {ex=1} ex && /R\( 0\)/ {r=1; next} r && /^ *1 +-?[0-9]+\.[0-9]/ {printf "%s\n", $2; exit}' "$1"; }
echo "VALUE R(0)(1,1), COLRED example 2 $(val "$E/run-pass1.out")"
