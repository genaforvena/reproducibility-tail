#!/usr/bin/env bash
# Rebuilds the rerun verdict for peters1998-pcp2nurb-783 (TOMS 783, Pcp2Nurb, C).
# Fetch (the only network step, inside the sandbox): netlib TOMS 783.gz (sha256 checked), gunzipped, then the shar
# unpacked with sh (everything above the #! /bin/sh line removed first). The shar creates C/Drivers/Sp/{driver1.c,
# driver2.c,RES1,RES2,data2} and C/Src/Sp/src.c. Everything else runs through tools/sandbox.sh.
# Original attempt (G1): the header's documented commands as printed (cc -g -c nurb_iv1.c; cc -g -c pcp2nurb.c;
# cc -g -o nurb_iv1 nurb_iv1.o pcp2nurb.o -lm). The shar ships driver1.c and src.c, not those names, so the
# documented compile fails at once. Log kept once in evidence/original-attempt.log.
# Patch (basis patched): build-only. The same sources are compiled under their shipped names (driver1.c, src.c),
# out of tree into /work/out; no source file is edited. Proven by three manifests (verify_sources record).
# Claim: driver1 run with blend ratio 0.5, the first Coordinate3 point list (first NurbsSurface), point 1, x y z,
# against the shipped RES1 values 0.493056 1.868056 0.972222 at absolute tolerance 1e-5.
# Two passes (G3): each in its own clean directory.
set -uo pipefail
ID=peters1998-pcp2nurb-783
URL=https://netlib.org/toms/783.gz
SHA=11691adb9b362f2232d25883a1a74b809698f158a27e9a26f910d56d04e2dd87
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 783.gz (sha256 checked), gunzipped, shar unpacked with sh in the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "rm -rf /work/pre /work/build /work/g1 /work/out && mkdir /work/pre && cd /work && curl -fsSL -o 783.gz '$URL' && echo '$SHA  783.gz' | sha256sum -c - && gunzip -kf 783.gz && sed -n '4,\$p' 783 > pre/shar.sh && cd pre && sh shar.sh && test -f C/Drivers/Sp/driver1.c && test -f C/Src/Sp/src.c && test -f C/Drivers/Sp/RES1" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: RES1 copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/C/Drivers/Sp/RES1 > "$E/reference/RES1"
grep -m1 -A1 "Coordinate3" "$E/reference/RES1" | tail -1

# G2 build-only proof, manifest 1 of 3: the authors' bytes right after unpacking, before any patch.
python3 -I tools/verify_sources.py manifest "$W/pre/C" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }

# G1 original attempt: the header's documented commands as printed. Expected to fail (file names absent).
ORIG="$E/original-attempt.log"
[ -s "$ORIG" ] && ORIG="$E/original-attempt-rebuild.log"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/C /work/g1 && cd /work/g1/Drivers/Sp && cc -g -c nurb_iv1.c; echo c1_exit=\$?; cc -g -c pcp2nurb.c; echo c2_exit=\$?" > "$ORIG" 2>&1
tail -2 "$ORIG"

# The build tree: a copy of the authors' C/ tree. Outputs go to /work/out, outside the tree.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/C /work/build && mkdir -p /work/out" || { echo "COPY-FAILED"; exit 1; }

# G2 build-only proof, manifest 2 of 3: the build tree immediately before the build commands.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: the authors' sources under their shipped names, compiled out of tree with cc"
tools/sandbox.sh "$ID" -- sh -c "cd /work/out && cc -g -c /work/build/Drivers/Sp/driver1.c -o driver1.o 2>&1; echo d_exit=\$?; cc -g -c /work/build/Src/Sp/src.c -o src.o 2>&1; echo s_exit=\$?; cc -g -o nurb_iv1 driver1.o src.o -lm 2>&1; echo link_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
# record() reads and rewrites result.json (it adds the patch block); create the file if this is a fresh rebuild.
[ -f "$root/reports/$ID/result.json" ] || echo '{}' > "$root/reports/$ID/result.json"
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "cc -g -c /work/build/Drivers/Sp/driver1.c -o driver1.o" \
  --command "cc -g -c /work/build/Src/Sp/src.c -o src.o" \
  --command "cc -g -o nurb_iv1 driver1.o src.o -lm" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: G2 hold stays (see the record's kind and the added/modified lists)"

# Runs, twice (G3): each pass in a clean directory; the driver with blend ratio 0.5, the first Coordinate3 point 1.
for pass in run1 run2; do
  echo "== $pass: clean directory, nurb_iv1 0.5"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/out/nurb_iv1 /work/$pass/ && cd /work/$pass && timeout 300 ./nurb_iv1 0.5 > out.iv 2> stderr.txt; echo ${pass}_run_exit=\$?; cp out.iv /work/$pass-out.iv"
  tools/sandbox.sh "$ID" -- cat /work/$pass-out.iv > "$E/$pass-out.iv"
  awk '/Coordinate3/{f=1} f && /point/{getline; print; exit}' "$E/$pass-out.iv" | tr -d ',[]' > "$E/$pass-point1.txt"
  echo "$pass point 1: $(cat "$E/$pass-point1.txt")"
done

echo "== claimed values per pass"
paste "$E/run1-point1.txt" "$E/run2-point1.txt"
read -r X Y Z < "$E/run2-point1.txt"
echo "VALUE driver1 0.5, first patch control point 1 x $X"
echo "VALUE driver1 0.5, first patch control point 1 y $Y"
echo "VALUE driver1 0.5, first patch control point 1 z $Z"
