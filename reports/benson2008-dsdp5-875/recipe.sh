#!/usr/bin/env bash
# Rebuilds the rerun verdict for benson2008-dsdp5-875 (TOMS 875, DSDP5 semidefinite programming solver, C).
# Fetch (the only network step, inside the sandbox): netlib TOMS 875.zip (sha256 checked), unzipped into /work/pre
# (875/bin/output.theta is the shipped reference log; 875/bin/graph1 is the input). Everything else runs through
# tools/sandbox.sh. The host only hashes source files with tools/verify_sources.py (read-only).
#
# Original attempt (G1): the documented route, make.include as shipped with DSDPROOT set in the environment
# (the authors' step 1 allows that), then `make all`. It builds libdsdp.a and fails at the first link:
# "cannot find -lg2c" (make.include's LAPACKBLAS lists the obsolete f2c runtime, absent on this host). The matlab
# step (dsdp target, needs mex) also fails in the same run; it is not part of the claim. Log: evidence/original-attempt.log.
#
# Build-only route (basis `patched`): the same make.include is used unedited; the library list is overridden on the
# make command line (LAPACKBLAS='-llapack -lblas -lm'), and only the library and examples targets are built, so the
# matlab step is skipped. No source or makefile is edited, so pre, mid and post manifests of the authors' files
# are identical; the record is build-only.
#
# Claim: the DD Objective of the last iteration of `theta graph1`, as a magnitude, against 3.00000012 (tol 1e-5).
# Two passes (G3): pass 1 is the verdict's build (make.include optimisation -O3); pass 2 is a clean copy built
# with OPTFLAGS=-O0 (a different build environment), run after the record.
set -uo pipefail
ID=benson2008-dsdp5-875
URL=https://netlib.org/toms/875.zip
SHA=43a19f4832245b4703dc1826a9786d21073a76e9c554e951aa2d3136ed78158f
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 875.zip (sha256 checked), unzipped into /work/pre"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/875.zip '$URL'; echo '$SHA  /work/875.zip' | sha256sum -c -; unzip -q /work/875.zip; test -f 875/bin/output.theta" || { echo "FETCH-FAILED"; exit 1; }

echo "== manifest (pre): the unpacked archive, before any patch"
python3 tools/verify_sources.py manifest "$SCRATCH/pre/875" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== shipped reference: bin/output.theta, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/875/bin/output.theta > "$E/reference/output.theta"
tail -1 "$E/reference/output.theta"

echo "== original attempt (G1, documented route: make all, as shipped)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/875 /work/g1 && cd /work/g1 && DSDPROOT=/work/g1 make all; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'make_exit=|cannot find' "$E/original-attempt.log"

echo "== pass 1: copy the archive to the build directory (no edit), then manifest (mid)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/875 /work/build && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"

echo "== pass 1 build (authors' documented targets, library list overridden on the command line)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && DSDPROOT=/work/build make LAPACKBLAS='-llapack -lblas -lm' dsdplibrary example > /work/build-make.log 2>&1; echo build_exit=\$?; tail -3 /work/build-make.log" > "$E/pass1-build.log" 2>&1
cat "$E/pass1-build.log"

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: theta graph1, then compare the whole log with the shipped reference"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/bin && ./theta graph1 > /work/theta-pass1.out 2>&1; echo run_exit=\$?; cat /work/theta-pass1.out; echo ---; diff /work/theta-pass1.out /work/pre/875/bin/output.theta && echo identical_to_reference" > "$E/pass1-run.log" 2>&1
grep -E '^(run_exit|identical_to_reference)' "$E/pass1-run.log"
tools/sandbox.sh "$ID" -- cat /work/theta-pass1.out > "$E/pass1-output.txt"

echo "== pass 2 (clean copy, OPTFLAGS=-O0, run after the record)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && cp -r /work/pre/875 /work/pass2 && cd /work/pass2 && DSDPROOT=/work/pass2 make LAPACKBLAS='-llapack -lblas -lm' OPTFLAGS=-O0 dsdplibrary example > /work/pass2-make.log 2>&1; echo build_exit=\$?; cd bin && ./theta graph1 > /work/theta-pass2.out 2>&1; echo run_exit=\$?; cat /work/theta-pass2.out" > "$E/pass2-run.log" 2>&1
grep -E '^(build_exit|run_exit)=' "$E/pass2-run.log"
tools/sandbox.sh "$ID" -- cat /work/theta-pass2.out > "$E/pass2-output.txt"

echo "== values: |DD objective| of the last iteration line"
for p in pass1 pass2; do
  awk '/^[0-9]+ +-?[0-9]/{last=$0} END{print last}' "$E/$p-output.txt" | awk '{printf "%.8f\n", ($3<0?-$3:$3)}' > "$E/$p-dd-magnitude.txt"
done
echo "VALUE theta graph1 final DD objective (magnitude) $(cat "$E/pass1-dd-magnitude.txt")"
echo "PASS2 VALUE theta graph1 final DD objective (magnitude) $(cat "$E/pass2-dd-magnitude.txt")"
