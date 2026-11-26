#!/usr/bin/env bash
# Rebuilds the rerun verdict for gaviano2003-gkls-829 (TOMS 829, GKLS test-function generator, C).
# Fetch (the only network step): netlib TOMS 829.gz (sha256 checked), unpacked inside the sandbox
# (it is a shell archive; the sh step runs inside tools/sandbox.sh). Everything else runs through tools/sandbox.sh.
# Original attempt (G1): `make gkls` in a copy of the authors' tree, exactly as the Makefile documents. It stops at
# the link step: the Makefile puts -lm before the objects, which the default --as-needed linker of this host rejects
# ("undefined reference to sin"). Log kept in evidence/original-attempt.log, never overwritten.
# Patch (the basis): the authors' Makefile is run unchanged with one linker flag, CFLAGS=-Wl,--no-as-needed, so the
# -lm line still resolves. No source file and no Makefile line is edited.
# Build-only proof (G2): the authors' tree is copied to a BUILD TREE (/work/build) before any build command; manifest
# pre is over the authors' unpacked tree, mid is over the build tree right before `make`, post after the build.
# Claim: the global minimizer coordinates of D-type function 1, dimension 2, printed by ./gkls (example.c writes
# test001.txt), compared with the registered values (-0.136, 0.824) at tol_abs 1e-3. The shipped test001.txt is the
# reference (copied into evidence/reference and compared as a whole file, not only the minimizer line).
set -uo pipefail
ID=gaviano2003-gkls-829
URL=https://netlib.org/toms/829.gz
SHA=e4bd1b05f73b9a697c69998ba190226b38133b68d83f0b3da2cd8d9f99a5f5f6
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 829.gz (sha256 checked), unpacked in the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "rm -rf /work/pre /work/build /work/g1 && cd /work && curl -fsSL -o 829.gz '$URL' && echo '$SHA  829.gz' | sha256sum -c - && gunzip -kf 829.gz && mkdir pre && sed -n '/^#! \/bin\/sh/,\$p' 829 > pre/829.sh && cd pre && sh 829.sh > /dev/null 2>&1; test -f C/Dp/Drivers/example.c" || { echo "FETCH-FAILED"; exit 1; }

# G2 build-only proof, manifest 1 of 3: the authors' bytes, right after unpacking, before any copy or build.
tools/sandbox.sh "$ID" -- sh -c "cat /work/pre/C/Dp/Drivers/test001.txt" > "$E/reference/test001.txt" || { echo "REF-FAILED"; exit 1; }
python3 -I tools/verify_sources.py manifest "$W/pre/C" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }
echo "manifest.pre: $(wc -l < "$W/manifest.pre") source files"

echo "== G1 original attempt: the authors' Makefile as documented, in a copy (kept once, never overwritten)"
ORIG="$E/original-attempt.log"
if [ ! -s "$ORIG" ]; then
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/C /work/g1 && cd /work/g1/Dp/Drivers && make CC=gcc 2>&1; echo make_exit=\$?" > "$ORIG" 2>&1
fi
tail -4 "$ORIG"

# The build tree: a full copy of the authors' C tree (same layout). Every build command runs here.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/C /work/build" || { echo "COPY-FAILED"; exit 1; }

# G2 build-only proof, manifest 2 of 3: the build tree, immediately before the build command.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: the authors' Makefile with one linker flag (CC=gcc CFLAGS=-Wl,--no-as-needed)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/Dp/Drivers && make CC=gcc CFLAGS=-Wl,--no-as-needed; echo make_exit=\$?" | tee "$E/build.log"

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "make CC=gcc CFLAGS=-Wl,--no-as-needed" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: G2 hold stays (see the record's kind and the added/modified lists)"

# Runs, twice (G3): each pass in its own clean directory, the binary copied from the build tree.
for pass in run1 run2; do
  echo "== $pass: clean directory, ./gkls (writes test001.txt in its directory)"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/build/Dp/Drivers/gkls /work/$pass/ && cd /work/$pass && timeout 900 ./gkls > stdout.txt 2> stderr.txt; echo ${pass}_exit=\$?; cat test001.txt > /work/$pass-test001.txt; cat stdout.txt | tail -2"
  tools/sandbox.sh "$ID" -- cat /work/$pass-test001.txt > "$E/$pass-test001.txt"
  echo "$pass vs shipped test001.txt (diff ignoring the final newline):"
  diff <(sed -e '$a\' "$E/reference/test001.txt") <(sed -e '$a\' "$E/$pass-test001.txt") && echo "$pass: whole file identical to the shipped reference" || echo "$pass: DIFFERS from the shipped reference"
done

python3 -I "$here/impl/extract_minimizer.py" "$E/run2-test001.txt" > "$E/run2-value.txt"
python3 -I "$here/impl/extract_minimizer.py" "$E/run1-test001.txt" > "$E/run1-value.txt"
echo "VALUE D-type function 1, dim 2, global minimizer x1 $(sed -n 1p "$E/run2-value.txt")"
echo "VALUE D-type function 1, dim 2, global minimizer x2 $(sed -n 2p "$E/run2-value.txt")"
echo "== run1 and run2 minimizer (x1, x2)"
paste "$E/run1-value.txt" "$E/run2-value.txt"
