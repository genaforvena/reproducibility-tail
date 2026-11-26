#!/usr/bin/env bash
# Rebuilds the rerun verdict for alhargan2006-mathieu-855 (TOMS 855, Mathieu characteristic numbers, C++).
# Fetch (the only network step, inside the sandbox): netlib TOMS 855.zip (sha256 checked) and unzipped
# into /work/pre (855/CPP/Dp/Src/mcnf.cpp, mcnr.cpp; 855/CPP/Dp/Drivers/driver.cpp, Res; 855/Doc/Makefile).
# Everything else runs through tools/sandbox.sh.
# Original attempt (G1): the authors' Doc/Makefile, as shipped. It includes makefile.inc, which the archive
# does not contain, so make stops. Log: evidence/original-attempt.log.
# Patch (basis patched): build-only. The archive ships no compiler settings, so the authors' three sources
# are compiled with g++ -O0 out of tree (the Makefile's own targets, as one command per object and one link);
# no source file is edited. Proven by three manifests (verify_sources record).
# Claim: Table 2 (nu = 10.5), row t = 1.50, column c = Compute_c(10.5, 0, h = 15.75), printed %1.6lf
# against the shipped 130.971685, absolute tolerance 1e-6.
# Two passes (G3): each in its own clean directory; pass 2 uses -O2 (a different compile environment).
set -uo pipefail
ID=alhargan2006-mathieu-855
URL=https://www.netlib.org/toms/855.zip
SHA=3ed63d4389cec03acf2822a43e87caa9c1d829477e32f83b064eb1ef82ae1154
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 855.zip (sha256 checked), unzipped into /work/pre"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/build /work/g1 /work/out /work/pass2; mkdir /work/pre; cd /work; curl -fsSL -o 855.zip '$URL'; echo '$SHA  855.zip' | sha256sum -c -; cd pre && unzip -q ../855.zip; test -f 855/CPP/Dp/Drivers/driver.cpp && test -f 855/CPP/Dp/Drivers/Res" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: Res, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/855/CPP/Dp/Drivers/Res > "$E/reference/Res"
grep -m1 "^  1.50 & 128.651417 & 130.971685" "$E/reference/Res"

# G2 build-only proof, manifest 1 of 3: the authors' bytes right after unpacking, before any patch.
python3 -I tools/verify_sources.py manifest "$W/pre/855" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }

# G1 original attempt: the authors' Makefile as shipped. Expected to stop at makefile.inc (absent from the archive).
ORIG="$E/original-attempt.log"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/855/Doc && make 2>&1; echo make_exit=\$?" > "$ORIG" 2>&1
tail -2 "$ORIG"

# The build tree: a copy of the authors' C++ sources. Outputs go to /work/out, outside the tree.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/855 /work/build && mkdir -p /work/out" || { echo "COPY-FAILED"; exit 1; }

# G2 build-only proof, manifest 2 of 3: the build tree immediately before the build commands.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: the authors' driver.cpp, mcnf.cpp, mcnr.cpp compiled with g++ -O0 out of tree"
BUILD_CMD="g++ -O0 -c /work/build/CPP/Dp/Drivers/driver.cpp && g++ -O0 -c /work/build/CPP/Dp/Src/mcnr.cpp && g++ -O0 -c /work/build/CPP/Dp/Src/mcnf.cpp && g++ -O0 -o driver driver.o mcnr.o mcnf.o"
tools/sandbox.sh "$ID" -- sh -c "cd /work/out && $BUILD_CMD 2>&1; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -2 "$E/build.log"

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
[ -f "$root/reports/$ID/result.json" ] || echo '{}' > "$root/reports/$ID/result.json"
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "g++ -O0 -c /work/build/CPP/Dp/Drivers/driver.cpp" \
  --command "g++ -O0 -c /work/build/CPP/Dp/Src/mcnr.cpp" \
  --command "g++ -O0 -c /work/build/CPP/Dp/Src/mcnf.cpp" \
  --command "g++ -O0 -o driver driver.o mcnr.o mcnf.o" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: G2 hold stays (see the record's kind and the added/modified lists)"

# Two passes (G3), each in a clean directory. The driver writes data.txt in its working directory.
# Pass 1: the -O0 build from the build tree. Pass 2: a separate -O2 build of the same sources, in its own directory.
run_pass() { # $1 = pass label, $2 = dir, $3 = optimisation level
  tools/sandbox.sh "$ID" -- sh -c "rm -rf $2 && mkdir -p $2 && cd $2 && g++ -O$3 -c /work/build/CPP/Dp/Drivers/driver.cpp && g++ -O$3 -c /work/build/CPP/Dp/Src/mcnr.cpp && g++ -O$3 -c /work/build/CPP/Dp/Src/mcnf.cpp && g++ -O$3 -o driver driver.o mcnr.o mcnf.o && ./driver > stdout.txt 2>&1; echo driver_exit=\$?; cat data.txt; echo" > "$E/pass-$1.log" 2>&1
  tail -1 "$E/pass-$1.log"
}
run_pass 1 /work/out/pass1 0
run_pass 2 /work/pass2 2

# Extract the claimed value (Table 2, nu=10.5, row t=1.50, column c) from each pass's data.txt.
for p in 1 2; do
  awk '/ Table 2/{s=1} /Table 3/{s=0} s && $1=="1.50"{print $5; exit}' "$E/pass-$p.log" > "$E/value-pass-$p.txt"
done
echo "VALUE Table 2, nu=10.5, t=1.50, c $(cat "$E/value-pass-1.txt")"
echo "PASS2 VALUE Table 2, nu=10.5, t=1.50, c $(cat "$E/value-pass-2.txt")"
