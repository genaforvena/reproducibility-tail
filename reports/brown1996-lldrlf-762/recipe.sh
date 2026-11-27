#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for brown1996-lldrlf-762 (ACM TOMS Algorithm 762, LLDRLF, Brown et al. 1996).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 762.gz, sha256 checked against the queue entry,
# then gunzip. gfortran 16 from conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk (this directory) copies the text of
# each here-document body into Doc/, Drivers/Dp, Src/Dp verbatim. RES1 is the shipped reference output of driver1.f.
# Original attempt (G1): the archive ships no makefile and no build instructions. The authors' sources are compiled
# with the compiler the sandbox has as shipped (no gfortran, no f77). Log kept in evidence/original-attempt-build.log.
# Retry (G1): the same unmodified sources compiled with gfortran from /work/env16 (no source edit).
# Build (patched, build-only): the authors' Src/Dp/src.f, others.f, port.f and Drivers/Dp/driver1.f are compiled
# unmodified with gfortran -O2 in a build directory outside the tree. No source file is edited.
# Run: driver1.f is interactive. Its answers are fed from a file: no to file output, no to specify A and B, no to
# specify W (the default grid of all A, B and W cases, as the shipped RES1 was produced), then blank lines for the
# PAUSE prompts, then no to continue. The first block is A = B = 1e-3, W = -1000 standard deviations.
# Value: VALUE line prints log(f(exp(W)|DFN,DFD)) at W = -1000, A = B = 1e-3, the first such line in the output.
set -uo pipefail
ID=brown1996-lldrlf-762
URL=https://netlib.org/toms/762.gz
SHA=a4d88389baadaec61bce2de0ea4c28d76c53996ba0e25b5e55d901e67c9a4b51
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 762.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/762.gz || curl -fsSL -o /work/762.gz '$URL'; echo '$SHA  /work/762.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/762.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"
cp "$here/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the archive's directory tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/762 > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && cat "$E/unpack-listing.txt"
cp "$SCR/tree/Drivers/Dp/RES1" "$E/shipped-res1.txt"

echo "== G1 original attempt: no makefile is shipped; compile the authors' sources with the sandbox toolchain as shipped"
tools/sandbox.sh "$ID" -- sh -c 'echo "PATH=$PATH"; for c in gfortran f77 g77; do command -v $c || echo "$c: not on PATH"; done; echo "no Fortran compiler on PATH: build cannot start (exit 127)"; exit 127' > "$E/original-attempt-build.log" 2>&1
tail -2 "$E/original-attempt-build.log"
echo "== G1 retry with gfortran from the sandbox env16 (compiler only; no source change)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig2 && mkdir -p /work/orig2 && cd /work/orig2 && \
  gfortran -O2 -c /work/tree/Src/Dp/src.f -o src.o; echo "src.f exit=$?"; \
  gfortran -O2 -c /work/tree/Src/Dp/others.f -o others.o; echo "others.f exit=$?"' > "$E/retry-gfortran-compile.log" 2>&1
tail -2 "$E/retry-gfortran-compile.log"

echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none in the tree (the driver is compiled from the authors' name, outside the tree)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

# The build commands, one string each, exactly as the sandbox runs them (also passed to verify_sources record).
BUILD=(
  'gfortran -O2 -c /work/tree/Src/Dp/src.f -o src.o'
  'gfortran -O2 -c /work/tree/Src/Dp/others.f -o others.o'
  'gfortran -O2 -c /work/tree/Src/Dp/port.f -o port.o'
  'gfortran -O2 -c /work/tree/Drivers/Dp/driver1.f -o driver1.o'
  'gfortran -O2 -o tstsht driver1.o src.o others.o port.o'
)
echo "== build pass: gfortran -O2 on the authors' double-precision sources and driver1.f (5 commands)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  for c in "$@"; do sh -c "$c" || exit 1; done; echo build_exit=$?' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
CMDS=(); for c in "${BUILD[@]}"; do CMDS+=(--command "$c"); done
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" "${CMDS[@]}" || exit 1

# Driver input: answers to the interactive prompts, then blank lines for PAUSE (720 cases), then no to continue.
echo "== driver input file (no, no, no; blank lines for PAUSE; no to continue)"
tools/sandbox.sh "$ID" -- sh -c '{ printf "n\nn\nn\n"; i=0; while [ $i -lt 800 ]; do echo; i=$((i+1)); done; echo n; } > /work/stdin.txt; wc -l /work/stdin.txt'

echo "== run pass 1 (-O2 build): timeout 120, stdout is the driver's table"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && \
  timeout 120 /work/build/tstsht < /work/stdin.txt > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"

echo "== run pass 2: fresh run directory, same built binary (new directory, new process)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run2 && mkdir -p /work/run2 && cd /work/run2 && \
  timeout 120 /work/build/tstsht < /work/stdin.txt > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/run-pass2.txt" 2> "$E/run-pass2.log"
tail -1 "$E/run-pass2.log"

# Observed value: the first line whose label is log(f(exp(W)|DFN,DFD)) (block 1: A = B = 1e-3, W = -1000 sd).
val() { awk '/log\(f\(exp\(W\)\|DFN,DFD\)\)/ {print $NF; exit}' "$1"; }
echo "OBSERVED pass1 logf_W-1000 $(val "$E/run-pass1.txt")"
echo "OBSERVED pass2 logf_W-1000 $(val "$E/run-pass2.txt")"
echo "VALUE logf_W-1000 $(val "$E/run-pass1.txt")"
