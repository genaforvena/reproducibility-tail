#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for zeng2004-multroot-835 (TOMS 835, MultRoot: multiplicity structure and roots
# of a polynomial, Zeng 2004; MATLAB code run under GNU Octave 10.3.0 from conda-forge, since MATLAB is proprietary).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 835.gz, sha256 checked against the value below, then
# gunzip; micromamba and Octave into /work/octave when missing.
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk copies each here-document body verbatim
# into its directory (Doc/, Matlab/Src, Matlab/Drivers) following the archive's cd lines.
# Run: impl/run_example.m calls the authors' multroot on the worked example of Doc/readme.txt section 3 and prints one
# VALUE line per claimed quantity. The Octave path step (addpath of Octave's own m-library) is the workaround recorded as
# the basis 'patched'; the original attempt (octave-cli without it, run by hand) is kept in evidence/.
set -uo pipefail
ID=zeng2004-multroot-835
URL=https://netlib.org/toms/835.gz
SHA=ce26ae432aeb7009b30e066a4da73092baaacc7fc2525668646fd307adfdb8ff
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 835.gz (sha256 checked, gunzip); micromamba + octave into /work/octave if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work && curl -fsSL -o /work/835.gz '$URL'; echo '$SHA  /work/835.gz' | sha256sum -c -; gunzip -kf /work/835.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/octave/bin/octave-cli || timeout 900 /work/bin/micromamba create -y -q -p /work/octave -r /work/mamba -c conda-forge octave; \
  /work/octave/bin/octave-cli --version | head -1 > /work/octave-version.txt" || { echo "FETCH-FAILED"; exit 1; }
cp "$SCR/octave-version.txt" "$E/" 2>/dev/null

echo "== unpack: verbatim here-document bodies into the archive's directory tree (no shell archive is executed)"
cp "$here/extract-tree.awk" "$SCR/extract-tree.awk"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/835 && find . -type f | sort' > "$E/unpack-listing.txt" || { echo "UNPACK-FAILED"; exit 1; }
wc -l < "$E/unpack-listing.txt"

echo "== run: authors' multroot on the readme worked example (Octave, sandboxed, timeout 900)"
cp "$here/impl/run_example.m" "$SCR/run_example.m"
tools/sandbox.sh "$ID" -- sh -c 'cd /work && timeout 900 /work/octave/bin/octave-cli --no-gui -q /work/run_example.m' > "$E/recipe-run-raw.log" 2>&1
echo "run_exit=$?"
grep -v -E '^\s+[a-zA-Z_]+ at line|^warning: |^\s*$' "$E/recipe-run-raw.log" > "$E/recipe-run.log"
grep '^VALUE ' "$E/recipe-run-raw.log" > "$E/values.txt"
cat "$E/values.txt"
