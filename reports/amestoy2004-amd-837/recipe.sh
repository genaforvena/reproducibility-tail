#!/usr/bin/env bash
# Rebuilds the rerun verdict for amestoy2004-amd-837 (TOMS 837, AMD approximate minimum degree ordering, C).
# Fetch (the only network step): netlib TOMS 837.zip, unpacked inside the sandbox scratch. Everything else runs
# through tools/sandbox.sh. The registered archive sha256 in queue/amestoy2004-amd-837.json does not match the file
# netlib serves today; the archive hash observed is printed in the log, and the integrity check that gates the
# claim is the sha256 of the shipped Demo/amd_demo.out (63a791ae...), which the registration also records.
# Original attempt (G1): the authors' Makefiles run unchanged (`make lib` in the top directory, then `make amd_demo`
# in Demo), in a copy of the unpacked tree. No patch, no build flag. Log kept in evidence/original-attempt.log.
# Claim: the demo prints "LDL' flop count for real A" for the built-in can_24 matrix; registered value 647, exact.
# Two clean passes (G3): each runs the binary built in the original attempt, in its own clean directory.
set -uo pipefail
ID=amestoy2004-amd-837
URL=https://netlib.org/toms/837.zip
DEMO_SHA=63a791ae537cb1126fad775dbc9a629a8787568812f8cc47f1a3bf660c9702f0
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 837.zip, unpacked in the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "rm -rf /work/pre && mkdir /work/pre && cd /work && curl -fsSL -o 837.zip '$URL' && echo \"archive sha256 observed: \$(sha256sum 837.zip | cut -d' ' -f1)\" && unzip -q 837.zip -d pre && test -f pre/837/Demo/amd_demo.out" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: Demo/amd_demo.out, checked against the registered sha256"
tools/sandbox.sh "$ID" -- cat /work/pre/837/Demo/amd_demo.out > "$E/reference/amd_demo.out" || { echo "REF-FAILED"; exit 1; }
echo "$(sha256sum "$E/reference/amd_demo.out")"
sha256sum "$E/reference/amd_demo.out" | grep -q "^$DEMO_SHA " && echo "reference sha256 matches the registration" || echo "reference sha256 DIFFERS from the registration"

echo "== G1 original attempt: the authors' Makefiles as documented, in a copy (always rebuilt into /work/g1, the sandbox scratch is not kept between runs)"
# The first original attempt log is kept (never overwritten); a later rebuild writes its own log so the build always exists for the runs.
ORIG="$E/original-attempt.log"
[ -s "$ORIG" ] && ORIG="$E/original-attempt-rebuild.log"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/837 /work/g1 && cd /work/g1 && make lib 2>&1; echo lib_exit=\$?; cd Demo && make amd_demo 2>&1; echo demo_exit=\$?" > "$ORIG" 2>&1
tail -8 "$ORIG"

echo "== runs, twice (G3): each pass in its own clean directory, the demo binary from the original build"
for pass in run1 run2; do
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/g1/Demo/amd_demo /work/$pass/ && cd /work/$pass && timeout 900 ./amd_demo > stdout.txt 2> stderr.txt; echo ${pass}_exit=\$?; cp stdout.txt /work/$pass-stdout.txt" || echo "$pass: run command failed"
  tools/sandbox.sh "$ID" -- cat /work/$pass-stdout.txt > "$E/$pass-stdout.txt"
  echo "$pass vs shipped amd_demo.out (full text):"
  diff "$E/reference/amd_demo.out" "$E/$pass-stdout.txt" && echo "$pass: whole output identical to the shipped reference" || echo "$pass: output DIFFERS from the shipped reference (see diff above)"
  grep -m1 "LDL' flop count for real A:" "$E/$pass-stdout.txt" | awk '{print $NF}' > "$E/$pass-value.txt"
done

echo "== claimed value per pass"
paste "$E/run1-value.txt" "$E/run2-value.txt"
echo "VALUE LDL' flop count for real A, can_24 demo (amd_demo.out) $(cat "$E/run2-value.txt")"
